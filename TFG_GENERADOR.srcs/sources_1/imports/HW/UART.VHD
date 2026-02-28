library ieee;
library xil_defaultlib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use xil_defaultlib.io_map.all;

entity uart is

   port(
      clk     : in  std_logic;
      reset   : in  std_logic;
      -- slot interface 
      cs      : in  std_logic;
      write   : in  std_logic;
      read    : in  std_logic;
      addr    : in  std_logic_vector(4 downto 0);
      rd_data : out std_logic_vector(31 downto 0);
      wr_data : in  std_logic_vector(31 downto 0);
      -- external signals
      tx      : out std_logic;
      rx      : in  std_logic
   );
end uart;
architecture arch of uart is
   signal wr_en    : std_logic;
   signal wr_uart  : std_logic;
   signal rd_uart  : std_logic;
   signal wr_dvsr  : std_logic;
   signal tx_full  : std_logic;
   signal rx_empty : std_logic;
   signal r_data   : std_logic_vector(7 downto 0);
   signal dvsr_reg : std_logic_vector(10 downto 0);
begin
   -- instancia el uart controller   
uart_unit : entity xil_defaultlib.uart_controller
-- opcionalmente se puede explicitar la arquitectura -- que se desea usar añadiendo: (str_arch)
--      generic map(
--         DBIT    => 8, 
--         SB_TICK => 16, 
--         FIFO_W  => N_DEPTH_FIFO -- Parámetro en iomap prof de pila
--      )
      port map(
         clk      => clk,
         reset    => reset,
         rd_uart  => rd_uart,
         wr_uart  => wr_uart,
         dvsr     => dvsr_reg,
         rx       => rx,
         tx       => tx,
         w_data   => wr_data(7 downto 0),
         r_data   => r_data,
         tx_full  => tx_full,
         rx_empty => rx_empty
      );
   -- registro de baud rate
   process(clk, reset)
   begin
      if (reset = '1') then
         dvsr_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         if wr_dvsr = '1' then
            dvsr_reg <= wr_data(10 downto 0);
         end if;
      end if;
   end process;
   -- decodificación de escritura
   wr_en   <= '1' when write = '1' and cs = '1' else '0';
   wr_dvsr <= '1' when addr(1 downto 0)="01" and wr_en = '1' else '0';
   wr_uart <= '1' when addr(1 downto 0)="10" and wr_en = '1' else '0';
   rd_uart <= '1' when addr(1 downto 0)="11" and wr_en = '1' else '0';
   
   -- multiplexor de lectura   
   rd_data <= x"00000" & "00" & tx_full & rx_empty & r_data;
end arch;

