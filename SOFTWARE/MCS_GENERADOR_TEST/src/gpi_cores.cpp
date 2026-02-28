
#include "gpi_cores.h"


/**********************************************************************
 * GpiCore
 **********************************************************************/
GpiCore::GpiCore(uint32_t core_base_addr) {
   base_addr = core_base_addr;
}
GpiCore::~GpiCore() {
}

uint32_t GpiCore::read() {
   return (io_read(base_addr, DATA_REG));
}

int GpiCore::read(int bit_pos) {
   uint32_t rd_data = io_read(base_addr, DATA_REG);
   return ((int) bit_read(rd_data, bit_pos));
}












