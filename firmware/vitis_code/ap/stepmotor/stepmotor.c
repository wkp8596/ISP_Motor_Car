#include "stepmotor.h"

void StepMotor_AppInit(void){
	StepMotor_Init(LEFT_STEPMOTOR);
	StepMotor_Init(RIGHT_STEPMOTOR);
	StepMotor_SetDir(LEFT_STEPMOTOR, MOTOR_FORWARD);
	StepMotor_SetDir(RIGHT_STEPMOTOR, MOTOR_FORWARD);
	StepMotor_Enable(LEFT_STEPMOTOR);
	StepMotor_Enable(RIGHT_STEPMOTOR);
	StepMotor_LineTrace(LEFT_STEPMOTOR, RIGHT_STEPMOTOR, 0x80);
}
