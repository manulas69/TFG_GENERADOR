library ieee;
use ieee.std_logic_1164.all;
entity gpo is
   generic(W : integer := 8);  --  N_SW
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
      dout    : out std_logic_vector(W - 1 downto 0)
   );
end gpo;
architecture arch of gpo is
  signal buf_reg : std_logic_vector(W - 1 downto 0);
  signal wr_en   : std_logic;
begin
  -- registro de salida
  process(clk, reset)
  begin
      if (reset = '1') then
         buf_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         if wr_en = '1' then
            buf_reg <= wr_data(W - 1 downto 0);
         end if;
      end if;
  end process;
  
-- lógica de decodificación
   wr_en   <= '1' when write = '1' and cs = '1' else '0';
   
-- interfaz de lectura del slot 
   rd_data <= (others => '0');  -- not used
-- salida externa  
   dout    <= buf_reg;
end arch;

