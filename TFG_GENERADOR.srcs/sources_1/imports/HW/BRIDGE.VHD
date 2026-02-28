library ieee;
library xil_defaultlib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use xil_defaultlib.io_map.all; -- Contiene la constante BRIDGE_BASE

entity BRIDGE is
port(
-- uBlaze MCS I/O bus
      IO_ADDR_STROBE  : in  std_logic;  -- no usada 
      IO_READ_STROBE  : in  std_logic;
      IO_WRITE_STROBE : in  std_logic;
      IO_BYTE_ENABLE  : in  std_logic_vector(3 downto 0);
      IO_ADDRESS      : in  std_logic_vector(31 downto 0);
      IO_WRITE_DATA   : in  std_logic_vector(31 downto 0);
      IO_READ_DATA    : out std_logic_vector(31 downto 0);
      IO_READY        : out std_logic;
-- FPro bus
      FP_VIDEO_CS     : out std_logic;
      FP_MMIO_CS      : out std_logic;
      FP_WR           : out std_logic;
      FP_RD           : out std_logic;
      FP_ADDR         : out std_logic_vector(20 downto 0);
      FP_WR_DATA      : out std_logic_vector(31 downto 0);
      FP_RD_DATA      : in  std_logic_vector(31 downto 0)
   );
end BRIDGE;
architecture ARCH of BRIDGE is
   
   signal MCS_BRIDGE_EN : std_logic;
   signal WORD_ADDR     : std_logic_vector(29 downto 0);

begin
-- address translation and decoding

   WORD_ADDR <= IO_ADDRESS(31 downto 2); -- 2 LSBs se prescinde por el word alignment 
   MCS_BRIDGE_EN <= '1' when IO_ADDRESS(31 downto 24)= BRIDGE_BASE(31 downto 24) else '0';
   FP_VIDEO_CS   <= '1' when MCS_BRIDGE_EN='1' and IO_ADDRESS(23)='1' else '0';
   FP_MMIO_CS    <= '1' when MCS_BRIDGE_EN='1' and IO_ADDRESS(23)='0' else '0';
   FP_ADDR       <=  WORD_ADDR(20 downto 0);

-- control line conversion 
   FP_WR         <= IO_WRITE_STROBE;
   FP_RD         <= IO_READ_STROBE;
   IO_READY      <= '1'; -- no usada, la transacción se hace en 1 clock

-- data line conversion
   FP_WR_DATA    <= IO_WRITE_DATA;
   IO_READ_DATA  <= FP_RD_DATA;
end ARCH;

