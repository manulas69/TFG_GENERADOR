#ifndef _INIT_H_INCLUDED
#define _INIT_H_INCLUDED

// library
#include "timer_core.h"
#include "io_map.h"
#include "io_rw.h"



#ifdef __cplusplus
extern "C" {
#endif

//timing functions
unsigned long now_us();
unsigned long now_ms();
void sleep_us(unsigned long int t);
void sleep_ms(unsigned long int t);

/**********************************************************************
 * debug(): funcion para facilitar la depuración
 *  - envía un mensaje de una linea via "uart" controlado por _DEBUG
 *  - _DEBUG debe ser definido en el fichero de forma individual
 *  - reemplazado con debug_off() cuando _DEBUG no está defineda
 *  - reemplazado con debug_on() cuando _DEBUG está defineda
 *  - debug_on() imprime un mensaje de una línea (un string y 2 numeros)
 *
 *********************************************************************/

/**
 * function.
 @note sustituye debug() cuando _DEBUG no está declarada
 */
void debug_off();

/**
 * imprime un mensaje de una linea (string más 2 numeros).
 * @param str un string
 * @param n1 primer número
 * @param n2 segundo número
 * @note sustituye debug() cuando _DEBUG está declarada
 */
void debug_on(const char *str, int n1, int n2);

#ifndef _DEBUG
#define debug(str, n1, n2) debug_off()
#endif // not _DEBUG

#ifdef _DEBUG
#define debug(str, n1, n2) debug_on((str), (n1), (n2))
#endif //  _DEBUG


#ifdef __cplusplus
} // extern "C"
#endif

/*********************************************************************
 * macros de manipulacion de bits
 * @param n posicion del bit
 *********************************************************************/
#define bit_set(data, n) ((data) |=(1UL << (n)))
#define bit_clear(data, n) ((data)&= ~(1UL << (n)))
#define bit_toggle(data, n) ((data)^= (1UL << (n)))
#define bit_read(data, n) (((data)>> (n)) & 0x01)
#define bit_write(data, n, bitvalue) (bitvalue ? bit_set((data), n) : bit_clear((data), n))
#define bit(n) (1UL << (n))

#endif // _INIT_H_INCLUDED
