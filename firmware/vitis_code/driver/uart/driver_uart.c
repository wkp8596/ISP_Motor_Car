#include "driver_uart.h"

void UART_Transmit(UART_TypeDef_t *uart, uint8_t data) {
	while(!(uart->SR & UART_TXE)); // TXE == 1일 때 TX_data 전송
	uart->DR = (uint32_t)data;
	uart->SR = UART_TC;
}

uint8_t UART_Receive(UART_TypeDef_t *uart) {
	uint8_t data;
	while(!(uart->SR & UART_RXNE)); // RXNE == 0일 때 RX_data 읽기
	data = uart->DR;
	uart->SR = UART_RXNE;
	return data;
}

void UART_StartInterrupt(UART_TypeDef_t *uart) {
	uart->CR |= UART_RXNEIE;
}

void UART_StopInterrupt(UART_TypeDef_t *uart) {
	uart->CR &= ~UART_RXNEIE;
}

void UART_SET_BAUD_RATE(UART_TypeDef_t *uart, uint32_t baud_rate) {
	uint32_t baud_div;
	baud_div = UART_CLK_FREQ/(baud_rate * 16);
	uart->BRR = baud_div;
}

void UART_Enable(UART_TypeDef_t *uart) {
	uart->CR |= UART_UE; // UE
}

void UART_Disable(UART_TypeDef_t *uart) {
	uart->CR &= ~UART_UE; // UE
}



