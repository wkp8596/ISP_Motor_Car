#ifndef SRC_COMMON_INTERRUPT_INTERRUPT_H_
#define SRC_COMMON_INTERRUPT_INTERRUPT_H_

#include "xparameters.h"
#include "xintc.h"
#include "xil_exception.h"

//#include "../delay/delay.h"

#define INTC_DEV_ID XPAR_INTC_0_DEVICE_ID

//#define TMR_VEC_ID 	XPAR_INTC_0_TIMER_0_VEC_ID
#define UART_VEC_ID XPAR_INTC_0_AXI4_LITE_UART_0_VEC_ID

//void TMR_ISR(void *CallbackRef);
void UART_ISR(void *CallbackRef);
int SetupInterruptSystem();

#endif /* SRC_COMMON_INTERRUPT_INTERRUPT_H_ */
