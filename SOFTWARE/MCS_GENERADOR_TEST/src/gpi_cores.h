
#ifndef _GPI_H_INCLUDED
#define _GPI_H_INCLUDED
#include "init.h"

/**********************************************************************
 * gpi (entradas de propósito general) core driver
 **********************************************************************/
/**
 * gpi (entradas de propósito general) core driver
 *  
 * Parámetros del subsistema MMIO:
 *  - W:  # bits de entrada del registro
 *   (bits no existentes devuelven 0's)
 */
class GpiCore {
public:
   /**
    * register map
    *
    */
   enum {
      DATA_REG = 0 /* registro de entrada de datos */
   };
   /**
    * constructor.
    */
   GpiCore(uint32_t core_base_addr);
   ~GpiCore();                  // no usado

   /* metodos */
   /**
    * leer un word de 32-bit
    * @return 32-bit read data word
    * @note bits no usados se leen como 0's
    */
   uint32_t read();

   /**
    * leer un bit de una posición concreta
    *
    * @param bit_pos posición del pit
    * @return 1-bit dato de 1 bit leido
    *
    */
   int read(int bit_pos);

private:
   uint32_t base_addr;
};

#endif  // _GPI_H_INCLUDED
