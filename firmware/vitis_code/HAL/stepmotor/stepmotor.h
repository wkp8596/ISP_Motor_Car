#ifndef SRC_HAL_STEPMOTOR_STEPMOTOR_H_
#define SRC_HAL_STEPMOTOR_STEPMOTOR_H_

#include <stdint.h>
#include "xparameters.h"

#define CLK_HZ 100000000

typedef struct {
  volatile  uint32_t CR;   // 0x00
  volatile  uint32_t ARR;  // 0x04
} StepMotor_TypeDef_t;

#define LEFT_STEPMOTOR_BASEADDR XPAR_AXI4_LITE_STEPMOTOR_1_S00_AXI_BASEADDR
#define LEFT_STEPMOTOR ((StepMotor_TypeDef_t *) LEFT_STEPMOTOR_BASEADDR)

#define RIGHT_STEPMOTOR_BASEADDR XPAR_AXI4_LITE_STEPMOTOR_0_S00_AXI_BASEADDR
#define RIGHT_STEPMOTOR ((StepMotor_TypeDef_t *) RIGHT_STEPMOTOR_BASEADDR)

#define STEPMOTOR_ENABLE (1U <<0)
#define STEPMOTOR_DIR (1U <<1)

#endif
