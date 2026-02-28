library IEEE;
library xil_defaultlib;
use IEEE.STD_LOGIC_1164.ALL;
use xil_defaultlib.io_map.all;
entity RAIZ_BASE_TIOU is
	Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           led : out STD_LOGIC_VECTOR (N_LED-1 downto 0);
           sw : in STD_LOGIC_VECTOR (N_SW-1 downto 0);
      -- spi
      spi_sclk : out std_logic;
      spi_mosi : out std_logic;
      spi_miso : in  std_logic;
      spi_ss_n : out std_logic_vector(1 downto 0);
      -- DAC output
      dac_out : out std_logic_vector(13 downto 0)
);
end RAIZ_BASE_TIOU;
architecture Behavioral of RAIZ_BASE_TIOU is

-- Componente Clocking Wizard 
component clk_wiz_0
port
 (
  clk_165MHz  : out    std_logic;
  reset       : in     std_logic;
  locked      : out    std_logic;
  clk_125MHz  : in     std_logic
 );
end component;

-- Componente Microcontrolador Microblaze MCS
component cpu
port(
  CLK           : in  std_logic;
  RESET         : in  std_logic;
  IO_addr_strobe: out std_logic;
  IO_read_strobe: out std_logic;
  IO_write_strobe: out std_logic;
  IO_address    : out std_logic_vector(31 downto 0);
  IO_byte_enable: out std_logic_vector(3 downto 0);
  IO_write_data : out std_logic_vector(31 downto 0);
  IO_read_data  : in  std_logic_vector(31 downto 0);
  IO_ready      : in  std_logic
  );
end component;
component bridge 
port(
-- uBlaze MCS I/O bus
 IO_addr_strobe  : in  std_logic;  -- not used 
 IO_read_strobe  : in  std_logic;
 IO_write_strobe : in  std_logic;
 IO_byte_enable  : in  std_logic_vector(3 downto 0);
 IO_address      : in  std_logic_vector(31 downto 0);
 IO_write_data   : in  std_logic_vector(31 downto 0);
 IO_read_data    : out std_logic_vector(31 downto 0);
 IO_ready        : out std_logic;
-- FPro bus
 FP_video_cs     : out std_logic;
 FP_mmio_cs      : out std_logic;
 FP_wr           : out std_logic;
 FP_rd           : out std_logic;
 FP_addr         : out std_logic_vector(20 downto 0);
 FP_wr_data      : out std_logic_vector(31 downto 0);
 FP_rd_data      : in  std_logic_vector(31 downto 0)
 );
end component;

component mmio
  
port(
      -- FPro bus
      clk          : in  std_logic;
      reset        : in  std_logic;
      clk_dds      : in  std_logic;  -- Reloj rápido 165 MHz para DDS
      Fp_mmio_cs      : in  std_logic;
      Fp_wr      : in  std_logic;
      Fp_rd      : in  std_logic;
      Fp_addr    : in  std_logic_vector(20 downto 0); -- solo 11 LSBs utilizados
      Fp_wr_data : in  std_logic_vector(31 downto 0);
      Fp_rd_data : out std_logic_vector(31 downto 0);
      -- switches y LEDs
      SW           : in  std_logic_vector(N_SW-1 downto 0);
      LED          : out std_logic_vector(N_LED-1 downto 0);
      -- uart
      -- spi
      spi_sclk     : out std_logic;
      spi_mosi     : out std_logic;
      spi_miso     : in  std_logic;
      spi_ss_n     : out std_logic_vector(1 downto 0);
      -- DAC output
      dac_out      : out std_logic_vector(13 downto 0)
   );
end component;

----------------------------------------------------
--      SE�ALES MICRO
----------------------------------------------------
signal clk_dds         : std_logic;  -- 165 MHz (DDS/DAC)
signal reset_sys       : std_logic;
signal mmcm_locked     : std_logic;
signal pll_reset       : std_logic;
----------------------------------------------------
--      SE�ALES MICRO-PUENTE
----------------------------------------------------
signal IO_addr_strobe  : std_logic;
signal IO_read_strobe  : std_logic;
signal IO_write_strobe : std_logic;
signal IO_address      : std_logic_vector(31 downto 0);
signal IO_byte_enable  : std_logic_vector(3 downto 0);
signal IO_write_data   : std_logic_vector(31 downto 0);
signal IO_read_data    : std_logic_vector(31 downto 0);
signal IO_ready        : std_logic;
-------------------------------------------------------
-- SE�ALES PUENTE-MMIO
-------------------------------------------------------
signal FP_video_cs     : std_logic;
signal FP_mmio_cs      : std_logic;
signal FP_wr           : std_logic;
signal FP_rd           : std_logic;
signal FP_addr         : std_logic_vector(20 downto 0);
signal FP_wr_data      : std_logic_vector(31 downto 0);
signal FP_rd_data      : std_logic_vector(31 downto 0);

begin
----------------------------------------------------
--      GESTIÓN DE RELOJ Y RESET
----------------------------------------------------
-- El reset del MMCM es activo a nivel ALTO
pll_reset <= reset; 

-- Instancia del Clocking Wizard (solo genera 165 MHz para DDS)
RELOJ_SISTEMA : clk_wiz_0
   port map ( 
  clk_165MHz  => clk_dds,    -- 165 MHz para DDS/DAC
  reset       => pll_reset,  -- Reset del PLL
  locked      => mmcm_locked,-- Indica cuando el reloj es estable
  clk_125MHz  => clk         -- Reloj externo de la placa (125 MHz)
 );
 
 -- MicroBlaze y bus usan directamente el reloj de la placa (125 MHz exactos)
 reset_sys <= '1' when (mmcm_locked = '0' or reset = '1') else '0';
----------------------------------------------------
--      INSTANCIA MICROPROCESADOR
----------------------------------------------------
BLOQUE_MICRO: cpu
      port map(
         CLK             => clk,
         RESET           => reset_sys, 
         IO_addr_strobe  => IO_addr_strobe,
         IO_read_strobe  => IO_read_strobe,
         IO_write_strobe => IO_write_strobe,
         IO_address      => IO_address,
         IO_byte_enable  => IO_byte_enable,
         IO_write_data   => IO_write_data, 
         IO_read_data    => IO_read_data,
         IO_ready        => IO_ready
);
----------------------------------------------------
--      INSTANCIA PUENTE
----------------------------------------------------
BLOQUE_BRIDGE: bridge 
--   generic map (BRIDGE_BASE)
   port map(
-- uBlaze MCS I/O bus
      IO_addr_strobe  =>   IO_addr_strobe,
      IO_read_strobe  =>   IO_read_strobe,
      IO_write_strobe =>   IO_write_strobe,
      IO_address      =>   IO_address,
      IO_byte_enable  =>   IO_byte_enable, 
      IO_write_data   =>   IO_write_data, 
      IO_read_data    =>   IO_read_data,
      IO_ready        =>   IO_ready,
-- FPro bus
      FP_video_cs     =>   FP_video_cs,
      FP_mmio_cs      =>   FP_mmio_cs,
      FP_wr           =>   FP_wr,
      FP_rd           =>   FP_rd,
      FP_addr         =>   FP_addr,
      FP_wr_data      =>   FP_wr_data,
      FP_rd_data      =>   FP_rd_data
   );
-------------------------------------------------
--      INSTANCIA BLOQUE MMIO
-------------------------------------------------
BLOQUE_MMIO: mmio
-- generic map( N_LED, N_SW, N_DEPTH_FIFO )  
   
  port map(
      -- FPro bus
      clk          => clk,
      reset        => reset_sys,
      clk_dds      => clk_dds,
      Fp_mmio_cs      => Fp_mmio_cs,
      Fp_wr      => FP_wr,
      Fp_rd      => FP_rd,
      Fp_addr    => Fp_addr,
      Fp_wr_data => fp_wr_data,
      Fp_rd_data => fp_rd_data,
      
      -- switches and LEDs
      sw          => SW,
      led         => LED,
      
      -- spi
      spi_sclk    => spi_sclk,
      spi_mosi    => spi_mosi,
      spi_miso    => spi_miso,
      spi_ss_n    => spi_ss_n,
      -- DAC output
      dac_out     => dac_out
   );

end Behavioral;

