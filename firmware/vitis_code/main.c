#include <stdint.h>
#include "xparameters.h"
#include "common/interrupt/interrupt.h"
#include "ap/stepmotor/stepmotor.h"
#include "ap/uart/ap_uart.h"
#include "common/delay/delay.h"

volatile uint8_t rx_data = 0x80;
volatile uint8_t rx_flag = 0;
uint32_t print_cnt = 0;

int main(void) {
	APP_UART_Init();
	xil_printf("Hello\r\n");
	SetupInterruptSystem();
	UART_StartInterrupt(UART0);
	StepMotor_AppInit();

	while (1) {
		if (rx_flag) {
			rx_flag = 0;
			uint8_t avg_x = StepMotor_MovingAvg(rx_data);

			int8_t dx = (int8_t) (avg_x - 0x80);
			char *state;
			if (avg_x == 0x00)
				state = "straight (default)";
			else if (dx < -30)
				state = "turn left high";
			else if (dx <= 30)
				state = "straight";
			else
				state = "turn right high";

			xil_printf("rx: 0x%02X avg: 0x%02X | %s\r\n", rx_data, avg_x,
					state);
			if (rx_data == 0xFF) {
				StepMotor_Disable(LEFT_STEPMOTOR);
				StepMotor_Disable(RIGHT_STEPMOTOR);
			}
			else {
				StepMotor_LineTrace(LEFT_STEPMOTOR, RIGHT_STEPMOTOR, avg_x);
				StepMotor_Enable(LEFT_STEPMOTOR);
				StepMotor_Enable(RIGHT_STEPMOTOR);
			}
			UART_StartInterrupt(UART0);
		}
	}
	return 0;
}

//
//int main(void) {
//    APP_UART_Init();
//    xil_printf("Hello\r\n");
//    SetupInterruptSystem();
//    UART_StartInterrupt(UART0);
//    StepMotor_AppInit();
//
//    while (1) {
//        // turn left high
//        StepMotor_LineTrace(LEFT_STEPMOTOR, RIGHT_STEPMOTOR, 0x10);
//    }
//    return 0;
//}
