#ifndef _DDS_AWG_CORE_H_INCLUDED
#define _DDS_AWG_CORE_H_INCLUDED
#include "init.h"

/**********************************************************************
 * DdsAwgCore driver  (slot 5)
 *  - compatible con dds_awg_slot.vhd
 *
 * Mapa de registros (offsets del slot):
 *  - reg 0 (R/W): FCW      - Frequency Control Word (32 bits)
 *  - reg 1 (W):   CTRL     - Bit 0: Enable, Bit 1: Wave Select (0=Seno, 1=AWG)
 *  - reg 2 (W):   RAM_ADDR - Direccion de la RAM AWG a escribir (10 bits)
 *  - reg 3 (W):   RAM_DATA - Dato a escribir en la RAM AWG (14 bits),
 *                            la escritura dispara el pulso de WE
 *  - reg 4 (W):   POW      - Phase Offset Word (32 bits)
 *
 * NOTA: rd_data devuelve SIEMPRE fcw_reg (cualquier lectura retorna FCW).
 *       CTRL, RAM_ADDR y POW son write-only; se cachean en software.
 *
 * Parametros del hardware:
 *  - PHASE_WIDTH = 10 (1024 posiciones de tabla)
 *  - DAC_WIDTH   = 14 (salida de 14 bits)
 *  - f_out = fcw * f_clk / 2^32
 *  - f_clk = DDS_CLK_FREQ MHz (165 MHz)
 **********************************************************************/
class DdsAwgCore {
public:
   /**
    * mapa de registros
    */
   enum {
      FCW_REG      = 0,   /**< R/W: Frequency Control Word (32 bits) */
      CTRL_REG     = 1,   /**< W:   bit0=enable, bit1=wave_sel (cacheado en ctrl_data) */
      RAM_ADDR_REG = 2,   /**< W:   direccion RAM AWG (10 bits) */
      RAM_DATA_REG = 3,   /**< W:   dato RAM AWG (14 bits), dispara WE */
      POW_REG      = 4    /**< W:   Phase Offset Word (32 bits) */
   };

   // Constantes del hardware
   static const int PHASE_WIDTH = 10;
   static const int TABLE_SIZE  = 1 << PHASE_WIDTH;  // 1024
   static const int DAC_WIDTH   = 14;
   static const int DAC_MAX     = (1 << DAC_WIDTH) - 1;  // 16383

   /**
    * constructor.
    * @param core_base_addr direccion base del slot DDS AWG
    */
   DdsAwgCore(uint32_t core_base_addr);
   ~DdsAwgCore();

   /**
    * configura la frecuencia de salida.
    * f_out = fcw * f_clk / 2^32
    * @param freq_hz frecuencia deseada en Hz
    */
   void set_freq(double freq_hz);

   /**
    * escribe directamente el FCW (Frequency Control Word).
    * @param fcw valor del FCW (32 bits)
    */
   void set_fcw(uint32_t fcw);

   /**
    * configura el desfase inicial.
    * @param degrees desfase en grados (0.0 - 360.0)
    */
   void set_phase(double degrees);

   /**
    * escribe directamente el POW (Phase Offset Word).
    * @param pow valor del POW (32 bits)
    */
   void set_pow(uint32_t pow);

   /**
    * lee el FCW actual.
    * @return valor del FCW
    */
   uint32_t get_fcw();

   /**
    * lee la frecuencia actual en Hz (calculada desde el FCW del hardware).
    * @return frecuencia en Hz
    */
   double get_freq();

   /**
    * lee el desfase actual (cacheado en software).
    * @return desfase en grados
    */
   double get_phase();

   /**
    * lee el POW actual (cacheado en software).
    * @return valor del POW
    */
   uint32_t get_pow();

   /**
    * habilita/deshabilita la salida del generador.
    * @param on true para habilitar, false para deshabilitar (salida a mid-scale)
    */
   void enable(bool on);

   /**
    * selecciona la forma de onda.
    * @param sel 0 = Senoidal (ROM), 1 = Arbitraria (RAM AWG)
    */
   void select_wave(int sel);

   /**
    * escribe una muestra en la tabla RAM de forma de onda arbitraria.
    * @param addr direccion de la muestra (0..TABLE_SIZE-1)
    * @param data valor de la muestra (0..DAC_MAX, unsigned, 14 bits)
    */
   void write_awg_sample(int addr, int data);

   /**
    * carga una tabla completa de forma de onda arbitraria.
    * @param table puntero a un array de TABLE_SIZE muestras (cada una 0..DAC_MAX)
    */
   void load_awg_table(const int *table);

   /**
    * genera una tabla de onda cuadrada y la carga en la RAM AWG.
    * @param duty ciclo de trabajo en porcentaje (0-100)
    */
   void gen_square_wave(int duty);

   /**
    * genera una tabla de onda triangular y la carga en la RAM AWG.
    */
   void gen_triangle_wave();

   /**
    * genera una tabla de onda diente de sierra y la carga en la RAM AWG.
    */
   void gen_sawtooth_wave();

private:
   uint32_t base_addr;
   uint32_t ctrl_data;   // registro de control en cache
   uint32_t pow_data;    // POW en cache
   bool safe_disable();
   void safe_restore(bool was_on);
};

#endif  // _DDS_AWG_CORE_H_INCLUDED
