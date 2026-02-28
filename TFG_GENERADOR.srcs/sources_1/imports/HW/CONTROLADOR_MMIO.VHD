library ieee;
library xil_defaultlib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use xil_defaultlib.io_map.all; -- Contiene constantes de Slots y tipos 2D

entity mmio_controller is
   port(
      -- FPro bus 
      FP_mmio_cs        : in  std_logic;
      FP_wr             : in  std_logic;
      FP_rd             : in  std_logic;
      FP_addr           : in  std_logic_vector(20 downto 0);
      FP_wr_data        : in  std_logic_vector(31 downto 0);
      FP_rd_data        : out std_logic_vector(31 downto 0);
      -- slot interface
      Slot_cs_array       : out std_logic_vector(63 downto 0);
      Slot_mem_rd_array   : out std_logic_vector(63 downto 0);
      Slot_mem_wr_array   : out std_logic_vector(63 downto 0);
      
      Slot_reg_addr_array : out SLOT_2D_REG_TYPE;
      Slot_rd_data_array  : in  SLOT_2D_DATA_TYPE;
      Slot_wr_data_array  : out SLOT_2D_DATA_TYPE
   );
end mmio_controller;

architecture arch of mmio_controller is
   
-- 11 LSBs de dirección: 2^6 slots (64), cada uno con 2^5 registers
   alias slot_addr : std_logic_vector(5 downto 0) is fp_addr(10 downto 5);
   alias reg_addr  : std_logic_vector(4 downto 0) is fp_addr(4 downto 0);
    -- Decodificación mediante un process(slot_addr, mmio_cs)
   begin
   
   process(slot_addr, FP_mmio_cs) 
 
begin  
      slot_cs_array <= (others => '0');
      if FP_mmio_cs = '1' then
         slot_cs_array(to_integer(unsigned(slot_addr))) <= '1';
      end if;
   end process;
   
   -- Distribuye a todos slots las líneas de control rd y wr
   slot_mem_rd_array   <= (others => fp_rd);
   slot_mem_wr_array   <= (others => fp_wr);
   
   slot_wr_data_array  <= (others => fp_wr_data);
   slot_reg_addr_array <= (others => reg_addr);
   
   -- mux para leer los Datos
   fp_rd_data <= slot_rd_data_array(to_integer(unsigned(slot_addr)));
end arch;

