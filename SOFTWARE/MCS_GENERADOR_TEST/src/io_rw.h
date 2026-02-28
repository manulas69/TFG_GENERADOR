#ifndef _IO_RW_H_INCLUDED
#define _IO_RW_H_INCLUDED

// library
#include <inttypes.h> // uso de los tipos uint32_t (En general uintN_t, (N:8, 16, 32, 64…)

#ifdef __cplusplus
extern "C" {
#endif

#define io_read(base_addr, offset) \
(*(volatile uint32_t *)((base_addr) + 4*(offset)))

#define io_write(base_addr, offset, data) \
(*(volatile uint32_t *)((base_addr) + 4*(offset)) = (data))

#define get_slot_addr(base, slot) \
((uint32_t)((base) + (slot)*32*4))

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* IO_RW_H_INCLUDED */















