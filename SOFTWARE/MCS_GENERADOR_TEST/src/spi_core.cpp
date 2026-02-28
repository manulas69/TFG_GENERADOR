
#include "spi_core.h"

/**********************************************************************
 * SpiCore
 **********************************************************************/
SpiCore::SpiCore(uint32_t core_base_addr) {
   base_addr = core_base_addr;
   // ctrl por defecto: cpol=0, cpha=0, dvsr=256 (~195 KHz con 100 MHz)
   ctrl_data = 0x00000100;
   ss_n_data = 0x00000003;  // todos los ss desactivados (activo bajo)
   io_write(base_addr, CTRL_REG, ctrl_data);
   io_write(base_addr, SS_REG, ss_n_data);
}

SpiCore::~SpiCore() {
}

void SpiCore::set_freq(int freq) {
   // f_sclk = SYS_CLK_FREQ_MHz * 1000 / (2 * (dvsr + 1))
   // dvsr = (SYS_CLK_FREQ_MHz * 1000) / (2 * freq) - 1
   int dvsr;
   dvsr = (SYS_CLK_FREQ * 1000) / (2 * freq) - 1;
   if (dvsr < 0)
      dvsr = 0;
   // preservar cpol/cpha (bits 17:16), actualizar dvsr (bits 15:0)
   ctrl_data = (ctrl_data & 0x00030000) | (dvsr & 0x0000FFFF);
   io_write(base_addr, CTRL_REG, ctrl_data);
}

void SpiCore::set_mode(int cpol, int cpha) {
   // cpol en bit 16, cpha en bit 17
   ctrl_data = (ctrl_data & 0x0000FFFF)
             | ((cpol & 0x01) << 16)
             | ((cpha & 0x01) << 17);
   io_write(base_addr, CTRL_REG, ctrl_data);
}

void SpiCore::assert_ss(int n) {
   bit_clear(ss_n_data, n);  // activo bajo: clear = activar
   io_write(base_addr, SS_REG, ss_n_data);
}

void SpiCore::deassert_ss(int n) {
   bit_set(ss_n_data, n);    // activo bajo: set = desactivar
   io_write(base_addr, SS_REG, ss_n_data);
}

uint8_t SpiCore::transfer(uint8_t data) {
   // espera a que el controlador este listo
   while (!ready()) {}
   // escribe dato, lo que arranca la transferencia
   io_write(base_addr, WR_DATA_REG, (uint32_t) data);
   // espera a que termine
   while (!ready()) {}
   // lee dato recibido (bits 7:0)
   return ((uint8_t) io_read(base_addr, RD_DATA_REG) & 0xFF);
}

bool SpiCore::ready() {
   // bit 8 del registro de lectura indica ready
   return ((io_read(base_addr, RD_DATA_REG) & 0x100) != 0);
}
