#include "delay.h"

uint32_t m_tick = 0;

uint32_t millis() {

	return m_tick;
}

void incTick() {

	m_tick++;
}

void delay_sec(u32 seconds) { // u32는 제공하는 함수

	sleep(seconds);
}

void delay_ms(uint32_t msec) {

	uint32_t mseconds = msec * 1000;
	usleep(mseconds); // usleep은 micro 단위 함수

}

void delay_us(uint32_t usec) {

	usleep(usec);
}

