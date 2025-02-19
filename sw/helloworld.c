// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include "uart.h"
#include "print.h"
#include "timer.h"
#include "gpio.h"
#include "util.h"

unsigned int
__mulsi3 (unsigned int a, unsigned int b)
{
  unsigned int r = 0;

  while (a)
    {
      if (a & 1)
	r += b;
      a >>= 1;
      b <<= 1;
    }
  return r;
}

#define n 16
#define func 1

void naive_func(int8_t* restrict a, int8_t* restrict b, int8_t* restrict c) {
    for(int i = 0; i < n; i++) {
        switch(func) {
            case 0: c[i] = a[i] + b[i]; break;
            case 1: c[i] = a[i] - b[i]; break;
            case 2: c[i] = a[i] * b[i]; break;
            default: c[i] = 0;
        }
    }
}

void accel_func(int8_t* restrict a, int8_t* restrict b, int8_t* restrict c) {
    volatile uint32_t *user_reg = (volatile uint32_t *)0x20000000;

    uint32_t* a_ptr = (uint32_t*)a;
    uint32_t* b_ptr = (uint32_t*)b;
    uint32_t* c_ptr = (uint32_t*)c;

    user_reg[0] = func;
    for(int i = 0; i < n; i += 4) {
        // Write a and b to the accelerator
        user_reg[1] = a_ptr[i / 4];
        user_reg[2] = b_ptr[i / 4];

        // Read result
        c_ptr[i / 4] = user_reg[3];
    }
}


void bench_function() {
    int8_t a[n];
    int8_t b[n];
    int8_t c_naive[n]; 
    int8_t c_accel[n]; 

    for(int i = 0; i < n; i++) {
        a[i] = i;
        b[i] = i << 4;
    }

    uint32_t start = get_mcycle();
    naive_func(a, b, c_naive);
    uint32_t end   = get_mcycle();
    gpio_write(end - start);

    start = get_mcycle();
    accel_func(a, b, c_accel);
    end   = get_mcycle();
    gpio_write(end - start);

    // Compare results
    for(int i = 0; i < n; i++) {
        if(c_naive[i] != c_accel[i]) {
            printf("Error at index %x: %x != %x\n", i, c_naive[i], c_accel[i]);
        }
    }
}

int main() {
    uart_init(); // setup the uart peripheral

    printf("Started\n");
    uart_write_flush();

    gpio_set_direction(0xFFFF, 0xFFFF);
    gpio_write(0x00);
    gpio_enable(0xFFFF);

    bench_function();

    printf("Done\n");
    uart_write_flush();

    /*
    // simple printf support (only prints text and hex numbers)
    printf("Hello World!\n");
    // wait until uart has finished sending
    uart_write_flush();

    // toggling some GPIOs
    gpio_set_direction(0xFFFF, 0x000F); // lowest four as outputs
    gpio_write(0x0A);  // ready output pattern
    gpio_enable(0xFF); // enable lowest eight
    // wait a few cycles to give GPIO signal time to propagate
    asm volatile ("nop; nop; nop; nop; nop;");
    printf("GPIO (expect 0xA0): 0x%x\n", gpio_read());

    gpio_toggle(0x0F); // toggle lower 8 GPIOs
    asm volatile ("nop; nop; nop; nop; nop;");
    printf("GPIO (expect 0x50): 0x%x\n", gpio_read());
    uart_write_flush();

    // doing some compute
    uint32_t start = get_mcycle();
    uint32_t res   = isqrt(1234567890UL);
    uint32_t end   = get_mcycle();
    printf("Result: 0x%x, Cycles: 0x%x\n", res, end - start);
    uart_write_flush();

    // using the timer
    printf("Tick\n");
    sleep_ms(10);
    printf("Tock\n");
    uart_write_flush();
    */
    return 1;
}
