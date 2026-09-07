#ifndef DRIVER_UART_H_
#define DRIVER_UART_H_

#include <stdint.h>
#include "../../HAL/uart/hal_uart.h"

void UART_Transmit(UART_TypeDef_t *uart, uint8_t data);
uint8_t UART_Receive(UART_TypeDef_t *uart);
void UART_StartInterrupt(UART_TypeDef_t *uart);
void UART_StopInterrupt(UART_TypeDef_t *uart);
void UART_SET_BAUD_RATE(UART_TypeDef_t *uart, uint32_t baud_rate);
void UART_Enable(UART_TypeDef_t *uart);
void UART_Disable(UART_TypeDef_t *uart);

#endif
