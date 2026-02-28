#ifndef _TIMER_H_INCLUDED
#define _TIMER_H_INCLUDED

#include "io_rw.h"  /* para accesos de lectura y escritura a registros*/
#include "io_map.h" /* para obtener system clock rate  */

class TimerCore {

/* mapa de registros */
enum {
COUNTER_LOWER_REG = 0, /* registro con los 32 bits bajos del contador*/
COUNTER_UPPER_REG = 1, /* registro con los 16 bits altos del contador */
CTRL_REG = 2 	   /* registro de control. Sólo relevantes bit 1 y bit 0 */
};

/* máscaras para registro de control */
enum {
GO_FIELD =  0x00000001, /* < bit 0 enable bit */
CLR_FIELD = 0x00000002  /* < bit 1 clear bit */
};

public:
TimerCore(uint32_t core_base_addr); // constructor
~TimerCore(); 		      // destructor; no usado

/* metodos */
void pause(); // pausar al contador
void go();    // habilitar al contador
void clear(); // resetea el contador a 0
uint64_t read_tick(); //obtiene el número de clocks transcurridos
uint64_t read_time(); //obtiene el tiempo transcurrido (en microsegundos)
void sleep(uint64_t us); //inactiva durante us microsegundos

private:
uint32_t base_addr;  // dirección base
uint32_t ctrl; 	// estado actual del registro de control
};
#endif  // _TIMER_H_INCLUDED
