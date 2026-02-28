
#ifndef _UART_CORE_H_INCLUDED
#define _UART_CORE_H_INCLUDED

#include "io_rw.h"
#include "io_map.h"  // to use SYS_CLK_FREQ
/**
 * uart core driver
 * - transmite/recibe datos via MMIO uart core.
 * - display (print) numero y string en la consola serie
 *
 */
class UartCore {
   /**
    * register map
    *
    */
   enum {
      RD_DATA_REG = 0,   /**< rx data/status register */
      DVSR_REG = 1,      /**< baud rate divisor register */
      WR_DATA_REG = 2,   /**< wr data register */
      RM_RD_DATA_REG = 3 /**< remove read data offset */
   };
  /**
   * mask fields
   *
   */
   enum {
      TX_FULL_FIELD = 0x00000200, /**< bit 9 of rd_data_reg; full bit  */
      RX_EMPT_FIELD = 0x00000100, /**< bit 10 of rd_data_reg; empty bit */
      RX_DATA_FIELD = 0x000000ff  /**< bits 7..0 rd_data_reg; read data */
   };
public:
   /* methods */
   /**
    * constructor.
    *
    * @note default rate a 9600 baud
    */
   UartCore(uint32_t core_base_addr);
   ~UartCore();

   /**
    * set baud rate
    *
    * @param baud baud rate
    * @note baud rate = sys_clk_freq/16/(dvsr+1)
    */
   void set_baud_rate(int baud);

   /**
    * chequea si la uart receiver fifo está vacía
    *
    * @return 1: if empty; 0: otherwise
    *
    */
   int rx_fifo_empty();

   /**
    * check si la uart transmitter fifo está llena
    *
    * @return 1: if full; 0: en otro caso
    *
    */
   int tx_fifo_full();

   /**
    * transmit a byte
    *
    * @param byte data byte a ser transmitido
    *
    * @note la function espera si tx fifo está full;
    *       para evitar "bloqueo" de ejecution, usar tx_fifo_full() para check status
    */
   void tx_byte(uint8_t byte);

   /**
    * recibir un byte
    *
    * @return -1 if rx fifo empty; byte data other wise
    *
    * @note la función no "busy wait"
    */
   int rx_byte();

   /**
    * display (print) a char on a serial terminal console
    *
    * @param ch char to be displayed
    *
    */
   void disp(char ch);

   /**
    * display (print) a string on a serial terminal console
    *
    * @param str pointer to the string to be displayed
    *
    */
   void disp(const char *str);

   /**
    * display (print) an integer on a serial terminal console
    *
    * @param n entero  a mostrar
    * @param base 2/8/10/16 for binary/octal/decimal/hex format
    * @param len # of digits (length) to be displayed
    *
    * @note padding blank spaces are added if printed digits smaller than len;
    * @note if len=0, # digits determined automatically without blanks
    *
    */
   void disp(int n, int base, int len);

   /**
    * display (print) un entero en la consola terminal serie
    *
    * @param n entero a mostrar
    * @param base 2/8/10/16 para formato binary/octal/decimal/hex
    * @note # digitos determinados automaticamente sin blancos
    *       (i.e., len=0)
    *
    */
   void disp(int n, int base);

   /**
    * display (print) an integer on a serial terminal console
    *
    * @param n intero a ser mostrado
    * @note base 10 
    * @note # digitos determinado automaticamente sin blancos
    *       (i.e., len=0)
    *
    */
   void disp(int n);

   /**
    * display (print) a floating-point number on a serial terminal console
    *
    * @param f floating-point número a mostrar
    * @param digit # of digits (length) in fraction portion to be displayed
    * @note base 10 
    * @note length entero determinado automaticamente
    *
    *
    */
   void disp(double f, int digit);

   /**
    * muestra (print) un floating-point number en la consola terminal serie
    *
    * @param f floating-point number to be displayed
    * @note 3 digitos de la parte fractional para añadir
    * @note base 10 
    * @note length entero determinado automaticamente
    *
    */
   void disp(double f);

private:
   uint32_t base_addr;
   int baud_rate;
   void disp_str(const char *str);
};

#endif  // _UART_CORE_H_INCLUDED
