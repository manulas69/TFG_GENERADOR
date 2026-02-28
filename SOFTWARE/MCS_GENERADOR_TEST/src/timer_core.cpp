#include "timer_core.h"

TimerCore::TimerCore(uint32_t core_base_addr) {
   base_addr = core_base_addr;
   ctrl = 0x01;
   clear();
   io_write(base_addr, CTRL_REG, ctrl);  // enable the timer
}

TimerCore::~TimerCore() {
}

void TimerCore::pause() {
   // pone el bit de count enable a 0
   ctrl = ctrl & ~GO_FIELD;
   io_write(base_addr, CTRL_REG, ctrl);
}

void TimerCore::go() {
   // set enable bit to 1
   ctrl = ctrl | GO_FIELD;
   io_write(base_addr, CTRL_REG, ctrl);
}

void TimerCore::clear() {
   uint32_t wdata;
// escribe el bit clear para generate un pulso transitorio de borrado.
   wdata = ctrl | CLR_FIELD;
   io_write(base_addr, CTRL_REG, wdata);
}

uint64_t TimerCore::read_tick() {
   uint64_t upper, lower;
   lower = (uint64_t) io_read(base_addr, COUNTER_LOWER_REG);
   upper = (uint64_t) io_read(base_addr, COUNTER_UPPER_REG);
   return ((upper << 32) | lower);
}

uint64_t TimerCore::read_time() {
   // tiempo transcurrido en microsegundos (SYS_CLK_FREQ in MHz)
   return (read_tick() / SYS_CLK_FREQ);
}

void TimerCore::sleep(uint64_t us) {
   uint64_t start_time, now;
   start_time = read_time();
   // bucle de espera
   do {
      now = read_time();
   } while ((now - start_time) < us);
}
