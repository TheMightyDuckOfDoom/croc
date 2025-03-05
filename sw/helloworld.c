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

typedef union {
    float f;
    uint32_t i;
} float_int_t;

float fpinator_add(float a, float b) {
    float_int_t fa, fb, fc;
    fa.f = a;
    fb.f = b;

    *reg32(FPINATOR_BASE_ADDR, 0) = 0; // Add
    *reg32(FPINATOR_BASE_ADDR, 4) = fa.i;
    *reg32(FPINATOR_BASE_ADDR, 8) = fb.i;
    fc.i = *reg32(FPINATOR_BASE_ADDR, 12); // Dummy read
    fc.i = *reg32(FPINATOR_BASE_ADDR, 12); // Read actual result

    return fc.f;
}

float fpinator_sub(float a, float b) {
    float_int_t fa, fb, fc;
    fa.f = a;
    fb.f = b;

    *reg32(FPINATOR_BASE_ADDR, 0) = 1; // Sub
    *reg32(FPINATOR_BASE_ADDR, 4) = fa.i;
    *reg32(FPINATOR_BASE_ADDR, 8) = fb.i;
    fc.i = *reg32(FPINATOR_BASE_ADDR, 12);
    fc.i = *reg32(FPINATOR_BASE_ADDR, 12);

    return fc.f;
}

int main() {
    uart_init(); // setup the uart peripheral

    // simple printf support (only prints text and hex numbers)
    printf("Hello World!\n");
    // wait until uart has finished sending
    uart_write_flush();

    // doing some compute
    volatile float_int_t a, b, c, d;
    a.i = 0x3F800000; // 1.0
    b.i = 0x40000000; // 2.0

    uint64_t start = get_mcycle();
    c.f = fpinator_add(a.f, b.f);
    uint64_t time = get_mcycle() - start;
    printf("Fpinator: 0x%x took 0x%x cycles\n", c.i, time);

    // Software float
    start = get_mcycle();
    d.f = a.f + b.f;
    time = get_mcycle() - start;
    printf("Softfloat: 0x%x took 0x%x cycles\n", c.i, time);

    if(c.i == d.i) {
        printf("Success!\n");
    } else {
        printf("Failure!\n");
        uart_write_flush();
        return -1;
    }

    c.f = fpinator_sub(c.f, b.f);
    printf("Fpinator: 0x%x\n", c.i);
    if(c.i == a.i) {
        printf("Success!\n");
    } else {
        printf("Failure!\n");
    }

    uart_write_flush();
    return 1;
}
