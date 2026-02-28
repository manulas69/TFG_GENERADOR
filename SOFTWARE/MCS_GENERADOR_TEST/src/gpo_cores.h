#ifndef _GPO_H_INCLUDED
#define _GPO_H_INCLUDED
#include "init.h"

/**********************************************************************
 * gpo (general-purpose output) core driver
 **********************************************************************/
/**
 * gpo (general-purpose output) core driver
 *  - escribe datos en el MMIO gpo core.
 *
 * MMIO subsystem HDL parameter:
 *  - W: # bits of output register
 *   (escribir en los bits no existentes no tienen efecto)
 */
class GpoCore {
public:
   /**
    * register map
    *
    */
   enum {
      DATA_REG = 0 /* registro de datos de salida */
   };
   /**
    * constructor.
    *
    */
   GpoCore(uint32_t core_base_addr);
   ~GpoCore();                  // no usado

   /**
    * escribir un 32-bit word
    * @param data 32-bit data
    *
    */
   void write(uint32_t data);

   /**
    * escribe un bit en una posicion concreta
    *
    * @param bit_value valor
    * @param bit_pos bit posicion
    *
    */
   void write(int bit_value, int bit_pos);

private:
   uint32_t base_addr;
   uint32_t wr_data;      // variable para conocer el valor escrito en data reg
};

#endif  // _GPO_H_INCLUDED
