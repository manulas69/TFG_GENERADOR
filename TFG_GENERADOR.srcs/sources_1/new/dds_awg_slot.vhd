library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dds_awg_slot is
    generic(
        ADDR_WIDTH  : integer := 5;  -- 5 bits = 32 registros por slot
        DATA_WIDTH  : integer := 32; -- Ancho del bus
        PHASE_WIDTH : integer := 10; 
        DAC_WIDTH   : integer := 14
    );
    port(
        clk         : in  std_logic;
        reset       : in  std_logic;
        clk_dds     : in  std_logic;  -- Reloj 165 MHz para el core DDS
        
        -- Interfaz de Bus I/O FPro (Viene del MicroBlaze)
        cs          : in  std_logic;
        write       : in  std_logic;
        read        : in  std_logic;
        addr        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        rd_data     : out std_logic_vector(DATA_WIDTH-1 downto 0);
        wr_data     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Salida fisica hacia el DAC
        dac_out     : out std_logic_vector(DAC_WIDTH-1 downto 0)
    );
end dds_awg_slot;

architecture arch of dds_awg_slot is

    -- Registros mapeados en memoria (MMIO)
    signal fcw_reg      : unsigned(31 downto 0);
    signal ctrl_reg     : std_logic_vector(1 downto 0);
    signal ram_addr_reg : unsigned(PHASE_WIDTH-1 downto 0);
    signal pow_reg      : unsigned(31 downto 0);  -- Phase Offset Word
    
    -- Senales de interconexion con el Core
    signal wr_en        : std_logic;
    signal ram_we_pulse : std_logic;

begin

    ------------------------------------------------------------------
    -- 1. Decodificador del Bus MMIO (MicroBlaze -> FPGA)
    ------------------------------------------------------------------
    wr_en <= '1' when write = '1' and cs = '1' else '0';

    -- Escritura a registros (Offsets 0, 1 y 2)
    process(clk, reset)
    begin
        if reset = '1' then
            fcw_reg      <= (others => '0');
            ctrl_reg     <= (others => '0');
            ram_addr_reg <= (others => '0');
            pow_reg      <= (others => '0');
        elsif rising_edge(clk) then
            if wr_en = '1' then
                case addr(2 downto 0) is
                    when "000" => -- Offset 0: Frequency Control Word
                        fcw_reg <= unsigned(wr_data);
                    when "001" => -- Offset 1: Control (Bit 0: Enable, Bit 1: Wave Sel)
                        ctrl_reg <= wr_data(1 downto 0);
                    when "010" => -- Offset 2: Direccion de RAM a escribir
                        ram_addr_reg <= unsigned(wr_data(PHASE_WIDTH-1 downto 0));
                    when "011" => -- Offset 3: Dato de RAM (dispara escritura)
                        null;
                    when "100" => -- Offset 4: Phase Offset Word
                        pow_reg <= unsigned(wr_data);
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -- Generador de pulso de escritura para la RAM (Offset 3)
    -- Cuando el C++ escribe en el Registro 3, dispara este pulso un ciclo de reloj
    ram_we_pulse <= '1' when wr_en = '1' and addr(2 downto 0) = "011" else '0';

    ------------------------------------------------------------------
    -- 2. Lectura del Bus MMIO (FPGA -> MicroBlaze)
    --    Solo devuelve fcw_reg en cualquier direccion.
    --    ctrl_reg y ram_addr_reg son senales internas (write-only).
    ------------------------------------------------------------------   
    rd_data <= std_logic_vector(fcw_reg);
      

    ------------------------------------------------------------------
    -- 3. Instanciacion del Motor (DDS + AWG)
    ------------------------------------------------------------------
    dds_awg_unit : entity work.dds_awg_core
        generic map(
            PHASE_WIDTH => PHASE_WIDTH,
            DAC_WIDTH   => DAC_WIDTH
        )
        port map(
            clk         => clk_dds,    -- <<< Reloj rapido 165 MHz
            reset       => reset,
            
            -- Senales de Control
            fcw          => fcw_reg,
            phase_offset => pow_reg,
            enable       => ctrl_reg(0),
            wave_sel     => ctrl_reg(1),
            
            -- Interfaz hacia la RAM programable
            ram_we      => ram_we_pulse,
            ram_addr_in => ram_addr_reg,
            ram_data_in => wr_data(DAC_WIDTH-1 downto 0), -- El dato llega directo del bus
            
            -- Salida
            dac_out     => dac_out
        );

end arch;
