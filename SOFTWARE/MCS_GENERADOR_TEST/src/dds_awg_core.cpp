
#include "dds_awg_core.h"

/**********************************************************************
 * DdsAwgCore
 **********************************************************************/
DdsAwgCore::DdsAwgCore(uint32_t core_base_addr) {
   base_addr   = core_base_addr;
   ctrl_data   = 0x00000000;
   pow_data    = 0x00000000;
   // inicializar registros
   io_write(base_addr, FCW_REG, 0);
   io_write(base_addr, CTRL_REG, ctrl_data);
   io_write(base_addr, POW_REG, 0);
}

DdsAwgCore::~DdsAwgCore() {
}

void DdsAwgCore::set_freq(double freq_hz) {
   bool was_on = safe_disable();
   // Clamp a Nyquist (f_clk/2)
   double max_freq = (DDS_CLK_FREQ * 1000000.0) / 2.0;
   if (freq_hz > max_freq) freq_hz = max_freq;
   if (freq_hz < 0.0) freq_hz = 0.0;
   // fcw = freq_hz * 2^32 / f_clk
   double fcw_d = freq_hz * 4294967296.0 / (DDS_CLK_FREQ * 1000000.0);
   uint32_t fcw = (uint32_t) fcw_d;
   io_write(base_addr, FCW_REG, fcw);
   safe_restore(was_on);
}

void DdsAwgCore::set_fcw(uint32_t fcw) {
   bool was_on = safe_disable();
   io_write(base_addr, FCW_REG, fcw);
   safe_restore(was_on);
}

void DdsAwgCore::set_phase(double degrees) {
   bool was_on = safe_disable();
   // pow = degrees * 2^32 / 360.0
   double pow_d = degrees * 4294967296.0 / 360.0;
   pow_data = (uint32_t) pow_d;
   io_write(base_addr, POW_REG, pow_data);
   safe_restore(was_on);
}

void DdsAwgCore::set_pow(uint32_t pow) {
   bool was_on = safe_disable();
   pow_data = pow;
   io_write(base_addr, POW_REG, pow_data);
   safe_restore(was_on);
}

uint32_t DdsAwgCore::get_fcw() {
   return io_read(base_addr, FCW_REG);
}

double DdsAwgCore::get_freq() {
   uint32_t fcw = get_fcw();
   return (double)fcw * (DDS_CLK_FREQ * 1000000.0) / 4294967296.0;
}

double DdsAwgCore::get_phase() {
   return (double)pow_data * 360.0 / 4294967296.0;
}

uint32_t DdsAwgCore::get_pow() {
   return pow_data;
}

void DdsAwgCore::enable(bool on) {
   if (on)
      bit_set(ctrl_data, 0);
   else
      bit_clear(ctrl_data, 0);
   io_write(base_addr, CTRL_REG, ctrl_data);
}

void DdsAwgCore::select_wave(int sel) {
   bool was_on = safe_disable();
   if (sel)
      bit_set(ctrl_data, 1);
   else
      bit_clear(ctrl_data, 1);
   io_write(base_addr, CTRL_REG, ctrl_data);
   safe_restore(was_on);
}

void DdsAwgCore::write_awg_sample(int addr, int data) {
   // 1. Escribir la direccion en RAM_ADDR_REG (offset 2)
   io_write(base_addr, RAM_ADDR_REG, (uint32_t)(addr & (TABLE_SIZE - 1)));
   // 2. Escribir el dato en RAM_DATA_REG (offset 3), lo que dispara el pulso WE
   io_write(base_addr, RAM_DATA_REG, (uint32_t)(data & DAC_MAX));
}

void DdsAwgCore::load_awg_table(const int *table) {
   bool was_on = safe_disable();
   for (int i = 0; i < TABLE_SIZE; i++) {
      write_awg_sample(i, table[i]);
   }
   safe_restore(was_on);
}

void DdsAwgCore::gen_square_wave(int duty) {
   bool was_on = safe_disable();
   int threshold = (TABLE_SIZE * duty) / 100;
   for (int i = 0; i < TABLE_SIZE; i++) {
      if (i < threshold)
         write_awg_sample(i, DAC_MAX);
      else
         write_awg_sample(i, 0);
   }
   safe_restore(was_on);
}

void DdsAwgCore::gen_triangle_wave() {
   bool was_on = safe_disable();
   int half = TABLE_SIZE / 2;
   for (int i = 0; i < TABLE_SIZE; i++) {
      int val;
      if (i < half)
         val = (DAC_MAX * i) / half;
      else
         val = (DAC_MAX * (TABLE_SIZE - i)) / half;
      write_awg_sample(i, val);
   }
   safe_restore(was_on);
}

void DdsAwgCore::gen_sawtooth_wave() {
   bool was_on = safe_disable();
   for (int i = 0; i < TABLE_SIZE; i++) {
      int val = (DAC_MAX * i) / TABLE_SIZE;
      write_awg_sample(i, val);
   }
   safe_restore(was_on);
}

// ---- Helpers privados para safe enable/disable ----
bool DdsAwgCore::safe_disable() {
   bool was_on = (ctrl_data & 0x01) != 0;
   if (was_on) {
      enable(false);
   }
   return was_on;
}

void DdsAwgCore::safe_restore(bool was_on) {
   if (was_on) {
      enable(true);
   }
}
