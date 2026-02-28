--  Mapa de registros del timer;
--    * 00: read (32 LSB of counter)
--    * 01: read (16 MSB of counter)
--    * 10: control register: 
--          bit 0: enable/pausa
--          bit 1: clear (no memoria, solo genera 1 pulso de borrado)
--    * 48-bit counter (hasta 32 dias)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
 port(
  	clk     : in  std_logic;
      	reset   : in  std_logic;
  -- slot interface 
      	cs      : in  std_logic;
      	write   : in  std_logic;
      	read    : in  std_logic;
      	addr    : in  std_logic_vector(4 downto 0);
      	rd_data : out std_logic_vector(31 downto 0);
     	wr_data : in  std_logic_vector(31 downto 0)
 );
end timer;
architecture arch of timer is
   	signal count_reg  : unsigned(47 downto 0);
   	signal count_next : unsigned(47 downto 0);
   	signal ctrl_reg   : std_logic;
   	signal wr_en      : std_logic;
   	signal clear, go  : std_logic;
begin
   --******************************************************************
   -- Contador
   --******************************************************************
   -- register
   process(clk, reset)
   begin
      if reset = '1' then
         count_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         count_reg <= count_next;
      end if;
   end process;
   -- next-state logic 
   count_next <= (others => '0') when clear = '1' else
                 count_reg + 1   when go = '1' else
                 count_reg;
   
-- ***************************************************************
-- Registro de control
-- ***************************************************************
process(clk, reset)
   begin
      if reset = '1' then
         ctrl_reg <= '0';
      elsif (clk'event and clk = '1') then
         if wr_en = '1' then
            ctrl_reg <= wr_data(0);
         end if;
      end if;
   end process;
-- ***************************************************************
-- Lógica de decodificación
-- ***************************************************************
   wr_en <= '1' when write='1' and cs='1' and addr(1 downto 0)="10" else '0';
   clear <= '1' when wr_en='1' and wr_data(1)='1' else '0';
   go    <= ctrl_reg;
-- ***************************************************************
-- Multiplexación de lectura (MSB, LSB)
-- ***************************************************************
   rd_data <= std_logic_vector(count_reg(31 downto 0)) when addr(0)='0' else
              x"0000" & std_logic_vector(count_reg(47 downto 32));
end arch;

