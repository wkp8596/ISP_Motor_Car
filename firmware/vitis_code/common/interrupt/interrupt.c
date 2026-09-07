#include "interrupt.h"

#include "../../driver/uart/driver_uart.h"
#include "../../HAL/uart/hal_uart.h"

// Handler of Interrupt Controller
XIntc IntrController;
extern volatile uint8_t rx_data;
extern volatile uint8_t rx_flag;

//void TMR_ISR(void *CallbackRef)
//{
//   incTick();
//}

void UART_ISR(void *CallbackRef)
{
	if((UART0->SR & UART_RXNE) && (UART0->CR & UART_RXNEIE))
	{
		rx_data = UART_Receive(UART0);
		rx_flag = 1;
		UART0->CR &= ~UART_RXNEIE;
	}
}

int SetupInterruptSystem()
{
    int status;

    // 1, 3, 5번 과정은 고정
    // 2, 4번만 수정하면 됨

    // 1. 인터럽트 컨트롤러 초기화 - 변경 X
    status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
    if (status != XST_SUCCESS) {
       return XST_FAILURE;
    }

//    // 2-1. TMR_ISR 함수를 Intc와 연결
//    status = XIntc_Connect(&IntrController, TMR_VEC_ID, (XInterruptHandler)TMR_ISR, (void *)0);
//    if (status != XST_SUCCESS) {
//      return XST_FAILURE;
//    }

    // 2-2. UART_ISR 함수를 Intc와 연결
   status = XIntc_Connect(&IntrController, UART_VEC_ID, (XInterruptHandler)UART_ISR, (void *)0);
   if (status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   // 3. Interrupt Controller 시작 (Hardware Mode) - 변경 X
   status = XIntc_Start(&IntrController, XIN_REAL_MODE);
   if (status != XST_SUCCESS) {
      return XST_FAILURE;
   }

   // 4. 각각의 Interrupt 채널 활성화
   //   XIntc_Enable(&IntrController, TMR_VEC_ID);
   XIntc_Enable(&IntrController, UART_VEC_ID);

   // 5. MicroBlaze의 Exception 초기화 및 활성화 - 변경 X
   Xil_ExceptionInit();
   Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XIntc_InterruptHandler, &IntrController);
   Xil_ExceptionEnable();

   return XST_SUCCESS;
}
