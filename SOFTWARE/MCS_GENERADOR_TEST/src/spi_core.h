#ifndef _SPI_CORE_H_INCLUDED
#define _SPI_CORE_H_INCLUDED
#include "init.h"

/**********************************************************************
 * spi_core driver
 *  - compatible con spi_core.vhd (wrapper de spi_controller.vhd)
 *
 * Mapa de registros:
 *  - reg 0 (lectura):  {23'b0, ready, dout[7:0]}
 *  - reg 1 (escritura): ss_n (slave selects, activo bajo)
 *  - reg 2 (escritura): din[7:0] (dato a enviar, lanza transferencia)
 *  - reg 3 (escritura): ctrl {14'b0, cpha, cpol, dvsr[15:0]}
 **********************************************************************/
class SpiCore {
public:
   /**
    * mapa de registros
    */
   enum {
      RD_DATA_REG = 0,   /**< lectura: ready(bit8) + dout(bits 7..0) */
      SS_REG      = 1,   /**< escritura: slave select */
      WR_DATA_REG = 2,   /**< escritura: dato tx (lanza transferencia) */
      CTRL_REG    = 3    /**< escritura: {cpha, cpol, dvsr[15:0]} */
   };

   /**
    * constructor.
    * @param core_base_addr direccion base del slot SPI
    */
   SpiCore(uint32_t core_base_addr);
   ~SpiCore();

   /**
    * configura el divisor de frecuencia del reloj SPI.
    * f_sclk = SYS_CLK_FREQ / (2 * (dvsr + 1))
    * @param freq frecuencia deseada en KHz
    */
   void set_freq(int freq);

   /**
    * configura el modo SPI (cpol, cpha).
    * @param cpol polaridad del reloj
    * @param cpha fase del reloj
    */
   void set_mode(int cpol, int cpha);

   /**
    * activa (pone a '0') el slave select n.
    * @param n indice del slave (0 o 1)
    */
   void assert_ss(int n);

   /**
    * desactiva (pone a '1') el slave select n.
    * @param n indice del slave (0 o 1)
    */
   void deassert_ss(int n);

   /**
    * transfiere un byte (envia y recibe simultaneamente).
    * bloquea hasta que la transferencia se completa.
    * @param data byte a enviar
    * @return byte recibido
    */
   uint8_t transfer(uint8_t data);

   /**
    * comprueba si el controlador SPI esta listo.
    * @return true si esta listo
    */
   bool ready();

private:
   uint32_t base_addr;
   uint32_t ctrl_data;   // registro de control en cache
   uint32_t ss_n_data;   // registro ss_n en cache
};

#endif  // _SPI_CORE_H_INCLUDED
