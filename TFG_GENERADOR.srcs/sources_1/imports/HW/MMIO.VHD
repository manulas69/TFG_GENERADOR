library ieee;
library xil_defaultlib;
use ieee.std_logic_1164.all;
use xil_defaultlib.io_map.all;
entity mmio is
  
port(
      -- FPro bus
      clk        : in  std_logic;
      reset      : in  std_logic;
      clk_dds    : in  std_logic;  -- Reloj rapido 165 MHz para DDS
      Fp_mmio_cs : in  std_logic;
      Fp_wr      : in  std_logic;
      Fp_rd      : in  std_logic;
      Fp_addr    : in  std_logic_vector(20 downto 0); -- only 11 LSBs used
      Fp_wr_data : in  std_logic_vector(31 downto 0);
      Fp_rd_data : out std_logic_vector(31 downto 0);
      
      -- switches and LEDs
      sw         : in  std_logic_vector(N_SW-1 downto 0);
      led        : out std_logic_vector(N_LED-1 downto 0);
      -- spi
      spi_sclk   : out std_logic;
      spi_mosi   : out std_logic;
      spi_miso   : in  std_logic;
      spi_ss_n   : out std_logic_vector(1 downto 0);
      -- DAC output
      dac_out     : out std_logic_vector(13 downto 0)
   );
end mmio;

architecture Behavioral of mmio is
-- Normalmente, aquí irían las declaraciones de los componentes. Una alternativa es omitir aquí 
-- estas declaraciones y hacer las intancias:“entity xil_defaultlib.name” como se indica más abajo
signal cs_array       : std_logic_vector(63 downto 0);
signal reg_addr_array : slot_2d_reg_type;
signal mem_rd_array   : std_logic_vector(63 downto 0);
signal mem_wr_array   : std_logic_vector(63 downto 0);
signal rd_data_array  : slot_2d_data_type;
signal wr_data_array  : slot_2d_data_type;
begin
------------------------------------------------------
--     Instancia del Controlador MMIO
------------------------------------------------------
Controlador: entity xil_defaultlib.mmio_controller
      port map(
         -- FPro bus interface
         FP_mmio_cs        => Fp_mmio_cs,
         FP_wr             => Fp_wr,
         FP_rd             => Fp_rd,
         FP_addr           => Fp_addr,
         FP_wr_data        => Fp_wr_data,
         FP_rd_data        => Fp_rd_data,
         -- 64 slot interface
         slot_cs_array       => cs_array,
         slot_reg_addr_array => reg_addr_array,
         slot_mem_rd_array   => mem_rd_array,
         slot_mem_wr_array   => mem_wr_array,
         slot_rd_data_array  => rd_data_array,
         slot_wr_data_array  => wr_data_array     );

------------------------------------------------------
--     Instancia de los Slots del MMIO
------------------------------------------------------
-- slot 0: Timer
Timer_SL0:  entity xil_defaultlib.timer
port map(
         clk           => clk,
         reset         => reset,
         -- slot interface 
         cs            => cs_array(S0_TIMER),
         read          => mem_rd_array(S0_TIMER),
         write         => mem_wr_array(S0_TIMER),
         addr          => reg_addr_array(S0_TIMER),
         rd_data       => rd_data_array(S0_TIMER),
         wr_data       => wr_data_array(S0_TIMER)
      );
-- slot 1: gpo puerto de salidas para LEDS
Gpo_SL1: entity xil_defaultlib.gpo
      generic map(W => N_LED)
      port map(
         clk     => clk,
         reset   => reset,
         -- slot interface 
         cs      => cs_array(S1_LED),
         read    => mem_rd_array(S1_LED),
         write   => mem_wr_array(S1_LED),
         addr    => reg_addr_array(S1_LED),
         rd_data => rd_data_array(S1_LED),
         wr_data => wr_data_array(S1_LED),
         -- external signal
         dout    => led
      );

-- slot 2: Puerto de entradas para switches     
Gpi_SL2: entity xil_defaultlib.gpi
      generic map(W => N_SW)
      port map(
         clk     => clk,
         reset   => reset,
         cs      => cs_array(S2_SW),
         read    => mem_rd_array(S2_SW),
         write   => mem_wr_array(S2_SW),
         addr    => reg_addr_array(S2_SW),
         rd_data => rd_data_array(S2_SW),
         wr_data => wr_data_array(S2_SW),
         -- external signal
         din     => SW
      );
-- slot 3: UART     
UART_SL3: entity xil_defaultlib.uart
--    generic map(FIFO_DEPTH_BIT => N_DEPTH_FIFO)
      port map(
         clk     => clk,
         reset   => reset,
         cs      => cs_array(S3_UART),
         read    => mem_rd_array(S3_UART),
         write   => mem_wr_array(S3_UART),
         addr    => reg_addr_array(S3_UART),
         rd_data => rd_data_array(S3_UART),
         wr_data => wr_data_array(S3_UART),
         -- external signal
         tx     => open,
         rx     => '1'
      );

-- slot 4: SPI
SPI_SL4: entity xil_defaultlib.spi_core
      port map(
         clk      => clk,
         reset    => reset,
         cs       => cs_array(S4_SPI),
         read     => mem_rd_array(S4_SPI),
         write    => mem_wr_array(S4_SPI),
         addr     => reg_addr_array(S4_SPI),
         rd_data  => rd_data_array(S4_SPI),
         wr_data  => wr_data_array(S4_SPI),
         -- external signals
         spi_sclk => spi_sclk,
         spi_mosi => spi_mosi,
         spi_miso => spi_miso,
         spi_ss_n => spi_ss_n
      );
-- slot 5: DDS AWG Generador de señales
DDS_AWG_SL5: entity xil_defaultlib.dds_awg_slot
      port map(
         clk     => clk,
         reset   => reset,
         clk_dds => clk_dds,
         cs      => cs_array(S5_DDS_AWG),
         read    => mem_rd_array(S5_DDS_AWG),
         write   => mem_wr_array(S5_DDS_AWG),
         addr    => reg_addr_array(S5_DDS_AWG),
         rd_data => rd_data_array(S5_DDS_AWG),
         wr_data => wr_data_array(S5_DDS_AWG),
         -- external signal
         dac_out => dac_out
      );
-- asigna 0's a todas señales rd_data de los slot no usados 
   gen_unused_slot : for i in 6 to 63 generate
   rd_data_array(i) <= (others => '0');
   end generate gen_unused_slot;
end Behavioral;

