#include "stepmotor.h"

static uint8_t  avg_buf[AVG_SIZE] = {
    0x80, 0x80, 0x80, 0x80, 0x80,
    0x80, 0x80, 0x80, 0x80, 0x80
};
static uint8_t  avg_idx = 0;
static uint16_t avg_sum = 0x80 * AVG_SIZE;

void StepMotor_Init (StepMotor_TypeDef_t *motor) {
	motor->ARR = CLK_HZ / 600;	//base = 600HZ
	motor->CR = 0;				//disable
}

void StepMotor_SetSpeed(StepMotor_TypeDef_t *motor, uint32_t step_ticks) {
	motor->ARR = step_ticks;
}

void StepMotor_SetLevel(StepMotor_TypeDef_t *motor, uint8_t level){
	if(level >= SPEED_LEVELS) level = SPEED_LEVELS -1;
	StepMotor_SetSpeed(motor, speed_table[level]);
}


void StepMotor_SetDir(StepMotor_TypeDef_t *motor, uint8_t dir){
	if(dir) motor->CR |= STEPMOTOR_DIR;
	else motor->CR &= ~STEPMOTOR_DIR;
}

void StepMotor_Enable(StepMotor_TypeDef_t *motor){
	motor->CR |= STEPMOTOR_ENABLE;
}

void StepMotor_Disable(StepMotor_TypeDef_t *motor) {
    motor->CR &= ~STEPMOTOR_ENABLE;
}

void StepMotor_LineTrace(StepMotor_TypeDef_t *left, StepMotor_TypeDef_t *right, uint8_t x) {
    if (x == 0x00) {  // 0x00 → 직진
        StepMotor_SetSpeed(left,  SPEED_FULL);
        StepMotor_SetSpeed(right, SPEED_FULL);
        return;
    }

    int8_t dx = (int8_t)(x - CENTER_X);

    if (dx < -30) {
    	StepMotor_SetDir(left, MOTOR_BACKWARD);
        StepMotor_SetSpeed(left,  SPEED_LOW);
    	StepMotor_SetDir(right, MOTOR_FORWARD);
        StepMotor_SetSpeed(right, SPEED_FULL);
    } else if (dx <= 30) {
    	StepMotor_SetDir(left, MOTOR_FORWARD);
        StepMotor_SetSpeed(left,  SPEED_FULL);
        StepMotor_SetDir(right, MOTOR_FORWARD);
        StepMotor_SetSpeed(right, SPEED_FULL);
    } else {
    	StepMotor_SetDir(right, MOTOR_BACKWARD);
        StepMotor_SetSpeed(right, SPEED_LOW);
        StepMotor_SetDir(left, MOTOR_FORWARD);
        StepMotor_SetSpeed(left,  SPEED_FULL);
    }
}

uint8_t StepMotor_MovingAvg(uint8_t new_val) {
    avg_sum -= avg_buf[avg_idx];   // 오래된 값 제거
    avg_buf[avg_idx] = new_val;    // 새 값 저장
    avg_sum += new_val;            // 합산
    avg_idx = (avg_idx + 1) % AVG_SIZE;  // 인덱스 순환
    return (uint8_t)(avg_sum / AVG_SIZE); // 평균 반환
}
