#ifndef SRC_HAL_UART_HAL_UART_H_
#define SRC_HAL_UART_HAL_UART_H_

#include <stdint.h>
#include "xparameters.h"

#define UART_CLK_FREQ 100000000

typedef struct {

	volatile uint32_t CR;
	volatile uint32_t SR;
	volatile uint32_t DR;
	volatile uint32_t BRR;

}UART_TypeDef_t;

#define UART_BASEADDR XPAR_AXI4_LITE_UART_0_S00_AXI_BASEADDR
#define UART0 ((UART_TypeDef_t *)UART_BASEADDR)

// CR
#define UART_RXNEIE (1U << 0)
#define UART_UE (1U << 1)
// SR
#define UART_RXNE (1U << 0)
#define UART_TXE  (1U << 1)
#define UART_TC   (1U << 2)

#endif
