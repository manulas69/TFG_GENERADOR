library ieee;
use ieee.std_logic_1164.all;
entity gpi is
   generic(W : integer := 8); 
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
      -- external signal
      din     : in  std_logic_vector(W-1 downto 0)
   );
end gpi;
architecture arch of gpi is
  signal rd_data_reg : std_logic_vector(W-1 downto 0);
  signal enable_rd : std_logic;
begin
   -- input register
   process(clk, reset)
   begin
     if reset = '1' then
       rd_data_reg <= (others => '0');
     elsif (clk'event and clk = '1') then
      	if enable_rd ='1' then   
  rd_data_reg <= din;
      	end if;
     end if;
   end process;
   
enable_rd <='1' when (cs='1' and read='1') else '0';
-- slot read interface
   rd_data(W-1 downto 0) <= rd_data_reg;
   rd_data(31 downto W)  <= (others => '0');
end arch;

