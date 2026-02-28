Library ieee; 
use ieee.std_logic_1164.all; 
package io_map is 
-- ******************************************************************************************** 
-- 2D data types que facilitarán la interconexión de los slots en el MMIO (64 de 32 registros) 
-- ******************************************************************************************** 
	type SLOT_2D_DATA_TYPE is array (63 downto 0) of std_logic_vector(31 downto 0); 
	type SLOT_2D_REG_TYPE is array (63 downto 0) of std_logic_vector(4 downto 0); 
-- ******************************************************************************************** 
-- Dirección Base para el Puente: "1100" & 0X"000_0000" 
-- ***************************************************************** 
	constant BRIDGE_BASE : std_logic_vector(31 downto 0) := X"C0000000"; 
-- ***************************************************************** 
-- Definición de Slots para sistema Base 
-- ***************************************************************** 
	constant S0_TIMER : integer := 0; 
	constant S1_LED :   integer := 1; 
	constant S2_SW :    integer := 2; 
	constant S3_UART :  integer := 3; 
	constant S4_SPI :   integer := 4; 
	constant S5_DDS_AWG :  integer := 5; 
	constant S6_USER :  integer := 6;
	constant S7_USER :  integer := 7; 
---------------------------------------------- 
-- Constante del niveles de pila para la UART
	Constant N_DEPTH_FIFO: integer :=8;
---------------------------------------------- 
-- Constantes del número de leds, y de switches disponibles en la tarjeta: NEXYS 4 DDR  
	constant N_LED :   integer := 4; 
	constant N_SW  :   integer := 4;

end io_map; 
