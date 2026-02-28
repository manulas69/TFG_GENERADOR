#ifndef _IO_MAP_INCLUDED
#define _IO_MAP_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

/***********************************************************
 * Zybo Z7 board 
 ***********************************************************/
// system clock rate in MHz; used for timer, uart, spi
#define SYS_CLK_FREQ 125
// DDS clock rate in MHz; used for FCW calculation (f_out = fcw * DDS_CLK_FREQ / 2^32)
#define DDS_CLK_FREQ 165

//io base address for microBlaze MCS
#define BRIDGE_BASE 0xc0000000

// slot module definition
// format: Slot#_ModuleType_Name 
#define S0_TIMER      0
#define S1_LED        1
#define S2_SW         2
#define S3_UART       3
#define S4_SPI        4
#define S5_DDS_AWG    5
#define S6_USER       6
#define S7_USER       7
#define S8_USER       8
#define S9_USER       9
#define S10_USER     10
#define S11_USER     11
#define S12_USER     12
#define S13_USER     13

/*****************************************************/
#ifdef __cplusplus
} // extern "C"
#endif

#endif  // _IO_MAP_INCLUDED

