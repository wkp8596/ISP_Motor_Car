#ifndef DRIVER_STEPMOTOR_H_
#define DRIVER_STEPMOTOR_H_

#include <stdint.h>
#include "../../HAL/stepmotor/stepmotor.h"

#define MOTOR_FORWARD 1
#define MOTOR_BACKWARD 0
#define AVG_SIZE 10


#define SPEED_LEVELS 5

#define SPEED_FULL  CLK_HZ / 500
#define SPEED_LOW  CLK_HZ / 200
#define CENTER_X    0x80


static const uint32_t speed_table[SPEED_LEVELS] = {
		CLK_HZ / 100,  // level 0 _ 200HZ
		CLK_HZ / 200,  // level 0 _ 400HZ
		CLK_HZ / 300,  // level 0 _ 600HZ
		CLK_HZ / 400,  // level 0 _ 800HZ
		CLK_HZ / 500, // level 0 _ 1000HZ
};

void StepMotor_Init(StepMotor_TypeDef_t *motor);
void StepMotor_SetSpeed(StepMotor_TypeDef_t *motor, uint32_t step_ticks);
void StepMotor_SetLevel(StepMotor_TypeDef_t *motor, uint8_t level);
void StepMotor_SetDir(StepMotor_TypeDef_t *motor, uint8_t dir);
void StepMotor_Enable(StepMotor_TypeDef_t *motor);
void StepMotor_Disable(StepMotor_TypeDef_t *motor);
void StepMotor_LineTrace(StepMotor_TypeDef_t *left, StepMotor_TypeDef_t *right, uint8_t x);
uint8_t StepMotor_MovingAvg(uint8_t new_val);

#endif
