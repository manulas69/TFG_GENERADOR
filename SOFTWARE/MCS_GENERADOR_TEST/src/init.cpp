
#include "init.h"

TimerCore _sys_timer(get_slot_addr(BRIDGE_BASE, S0_TIMER));
// UartCore uart no utilizada en Zybo Z7


// Actual system time en microsegundos
unsigned long now_us() {
return ((unsigned long) _sys_timer.read_time());
}

// Actual system time enmilisegundos
unsigned long now_ms() {
return ((unsigned long) _sys_timer.read_time() / 1000);
}

// pausa por t microsegundos
void sleep_us(unsigned long int t) {
_sys_timer.sleep(uint64_t(t));
}

// pausa por for t milisegundos
void sleep_ms(unsigned long int t) {
_sys_timer.sleep(uint64_t(1000 *
t));
}

// debug activado
// envía por UART un mensage de 1-linea: msg + 2 numeros en dec/hex format

void debug_on(const char *str, int n1, int n2) {
   // UART no disponible en Zybo Z7
}

void debug_off() {
}

