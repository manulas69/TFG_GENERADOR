library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dds_awg_core is
    generic (
        PHASE_WIDTH : integer := 10; -- 1024 posiciones (10 bits)
        DAC_WIDTH   : integer := 14  -- Salida de 14 bits
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        
        -- Entradas de Control y Sintonia
        fcw          : in  unsigned(31 downto 0);
        phase_offset : in  unsigned(31 downto 0);  -- Desfase inicial (POW)
        enable       : in  std_logic;
        wave_sel     : in  std_logic; -- 0: Seno(ROM), 1: Arbitraria(RAM)
        
        -- Puerto A de la Memoria Arbitraria (Escritura desde C++)
        ram_we      : in  std_logic;
        ram_addr_in : in  unsigned(PHASE_WIDTH-1 downto 0);
        ram_data_in : in  std_logic_vector(DAC_WIDTH-1 downto 0);
        
        -- Salida Digital Analógica
        dac_out     : out std_logic_vector(DAC_WIDTH-1 downto 0)
    );
end dds_awg_core;

architecture rtl of dds_awg_core is

    ------------------------------------------------------------------
    -- 1. ROM Senoidal Constante (Generada en síntesis)
    ------------------------------------------------------------------
    constant ROM_DEPTH : integer := 2**PHASE_WIDTH;
    type memory_type is array (0 to ROM_DEPTH-1) of std_logic_vector(DAC_WIDTH-1 downto 0);

    function init_sin_rom return memory_type is
        variable rom : memory_type;
        variable x, y: real;
        variable val : integer;
    begin
        for i in 0 to ROM_DEPTH-1 loop
            x := real(i) * 2.0 * MATH_PI / real(ROM_DEPTH);
            y := sin(x);
            val := integer(round((y + 1.0) * (real((2**DAC_WIDTH) - 1) / 2.0)));
            if val > ((2**DAC_WIDTH) - 1) then val := (2**DAC_WIDTH) - 1; end if;
            if val < 0 then val := 0; end if;
            rom(i) := std_logic_vector(to_unsigned(val, DAC_WIDTH));
        end loop;
        return rom;
    end function;

    constant SIN_ROM : memory_type := init_sin_rom;

    ------------------------------------------------------------------
    -- 2. RAM Arbitraria Inferida (AWG) - Dual Port
    ------------------------------------------------------------------
    -- Puerto A: Escritura desde Bus. Puerto B: Lectura DDS
    signal awg_ram : memory_type := (others => (others => '0'));

    ------------------------------------------------------------------
    -- Señales Internas
    ------------------------------------------------------------------
    signal phase_acc   : unsigned(31 downto 0);
    signal phase_trunc : unsigned(PHASE_WIDTH-1 downto 0);
    
    signal sine_val_raw    : std_logic_vector(DAC_WIDTH-1 downto 0);
    signal awg_val_raw     : std_logic_vector(DAC_WIDTH-1 downto 0);
    signal sine_val    : std_logic_vector(DAC_WIDTH-1 downto 0);
    signal awg_val     : std_logic_vector(DAC_WIDTH-1 downto 0);
    signal out_reg     : std_logic_vector(DAC_WIDTH-1 downto 0);

begin

    ------------------------------------------------------------------
    -- Acumulador de Fase
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            phase_acc <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                phase_acc <= phase_acc + fcw;
            else
                phase_acc <= (others => '0');
            end if;
        end if;
    end process;

    -- Sumar desfase y extraer los bits MSB para direccionar la memoria
    phase_trunc <= (phase_acc(31 downto 32-PHASE_WIDTH) + phase_offset(31 downto 32-PHASE_WIDTH));
  

    ------------------------------------------------------------------
    -- Memorias (Pipeline de 2 etapas)
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- Puerto A RAM: Escritura (desde MicroBlaze)
            if ram_we = '1' then
                awg_ram(to_integer(ram_addr_in)) <= ram_data_in;
            end if;
            
            -- ETAPA 1: Lectura cruda de la memoria
            sine_val_raw <= SIN_ROM(to_integer(phase_trunc));
            awg_val_raw  <= awg_ram(to_integer(phase_trunc));
            
            -- ETAPA 2: Registro intermedio 
            sine_val <= sine_val_raw;
            awg_val  <= awg_val_raw;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Multiplexor y Registro de Salida
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            out_reg <= std_logic_vector(to_unsigned(2**(DAC_WIDTH-1), DAC_WIDTH)); -- mid-scale
        elsif rising_edge(clk) then
            if enable = '0' then
                out_reg <= std_logic_vector(to_unsigned(2**(DAC_WIDTH-1), DAC_WIDTH)); -- mid-scale
            else
                if wave_sel = '0' then
                    out_reg <= sine_val;
                else
                    out_reg <= awg_val;
                end if;
            end if;
        end if;
    end process;

    dac_out <= out_reg;

end rtl;
