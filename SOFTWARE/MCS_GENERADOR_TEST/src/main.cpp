/********************************************************************
********************************************************************
 * @fichero main.cpp
 *
 * @ Test Basico Timer, i/o cores y SPI - Zybo Z7
 *
 * @author J. Vicuna
 * @version v2.0: adaptado a Zybo Z7 (4 LEDs, 4 SW, SPI slot 4)
 *******************************************************************/

//#define _DEBUG

#include "init.h"
#include "gpi_cores.h"
#include "gpo_cores.h"
#include "spi_core.h"

/*******************************************************************
 * Parpadea 5 veces todos los LEDs.
 * Permite chequear el timer (basado en la SYS_CLK_FREQ)
 * @param led_p puntero a la instancia GpoCore (led)
 */
void timer_check(GpoCore *led_p) {
   int i;

   for (i = 0; i < 5; i++) {
      led_p->write(0x0F);     // 4 LEDs encendidos
      sleep_ms(1000);
      led_p->write(0x00);
      sleep_ms(1000);
   }
}

/*******************************************************************
 * Chequeo individual de led
 * @param led_p puntero a la instancia GpoCore (led)
 * @param n numero de LEDs
 */
void led_check(GpoCore *led_p, int n) {
   int i;

   for (i = 0; i < n; i++) {
      led_p->write(1, i);
      sleep_ms(200);
      led_p->write(0, i);
      sleep_ms(200);
   }
}

/*******************************************************************
 * Parpadea LEDs de acuerdo a los switches activados.
 * @param led_p puntero a la instancia led
 * @param sw_p puntero a la instancia GpiCore (switch)
 */
void sw_check(GpoCore *led_p, GpiCore *sw_p) {
   int i, s;

   s = sw_p->read();
   for (i = 0; i < 30; i++) {
      led_p->write(s);
      sleep_ms(50);
      led_p->write(0);
      sleep_ms(50);
   }
}

/*******************************************************************
 * Test basico SPI: envia un byte y lee la respuesta.
 * Enciende led[0] si el controlador SPI responde (ready).
 * @param spi_p puntero a la instancia SpiCore
 * @param led_p puntero a la instancia GpoCore (led)
 */
void spi_check(SpiCore *spi_p, GpoCore *led_p) {
   uint8_t rx_data;

   // configurar SPI: modo 0 (cpol=0, cpha=0), ~100 KHz
   spi_p->set_freq(100);
   spi_p->set_mode(0, 0);

   // activar slave 0
   spi_p->assert_ss(0);

   // enviar byte de prueba
   rx_data = spi_p->transfer(0xA5);

   // desactivar slave 0
   spi_p->deassert_ss(0);

   // indicar con LEDs que el test se ha completado
   // muestra los 4 bits bajos del dato recibido
   led_p->write(rx_data & 0x0F);
   sleep_ms(2000);
   led_p->write(0x00);
}


/*******************************************************************/
/*         MAIN                        */
/*******************************************************************/

// instancias de perifericos
GpoCore led(get_slot_addr(BRIDGE_BASE, S1_LED));
GpiCore sw(get_slot_addr(BRIDGE_BASE, S2_SW));
SpiCore spi(get_slot_addr(BRIDGE_BASE, S4_SPI));

int main() {

   while (1) {
      timer_check(&led);
      led_check(&led, 4);       // 4 LEDs en Zybo Z7
      sw_check(&led, &sw);
      spi_check(&spi, &led);
   } //while
} //main

/*******************************************************************/
/*         /MAIN                       */
/*******************************************************************/