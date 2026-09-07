#include "ap_uart.h"

void APP_UART_Init(void)
{
	UART_SET_BAUD_RATE(UART0, 115200);
	UART_Enable(UART0);
	UART_StartInterrupt(UART0);
}

