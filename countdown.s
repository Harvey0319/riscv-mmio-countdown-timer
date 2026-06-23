.text
.globl _start

_start:
    lui  x1, 0x40000
    addi x2, x0, 1
    addi x3, x0, 0
    addi x4, x0, 0

loop:
    beq  x3, x0, led_wait
    beq  x3, x2, led_run
    addi x7, x0, 2
    beq  x3, x7, led_pause

led_done:
    addi x7, x0, 8
    sw   x7, 8(x1)
    jal  x0, after_led

led_wait:
    addi x7, x0, 1
    sw   x7, 8(x1)
    jal  x0, after_led

led_run:
    addi x7, x0, 2
    sw   x7, 8(x1)
    jal  x0, after_led

led_pause:
    addi x7, x0, 4
    sw   x7, 8(x1)

after_led:
    sw   x4, 12(x1)
    lw   x5, 4(x1)
    andi x7, x5, 2
    bne  x7, x0, do_reset
    beq  x3, x0, state_wait
    beq  x3, x2, state_run
    addi x7, x0, 2
    beq  x3, x7, state_pause
    jal  x0, state_done

do_reset:
    sw   x5, 28(x1)
    sw   x2, 24(x1)
    addi x3, x0, 0
    lw   x4, 0(x1)
    jal  x0, loop

state_wait:
    lw   x4, 0(x1)
    sw   x4, 12(x1)
    andi x7, x5, 1
    beq  x7, x0, loop
    sw   x5, 28(x1)
    sw   x2, 24(x1)
    beq  x4, x0, set_done
    addi x3, x0, 1
    jal  x0, loop

set_done:
    addi x3, x0, 3
    jal  x0, loop

state_run:
    andi x7, x5, 1
    bne  x7, x0, set_pause
    lw   x6, 16(x1)
    andi x6, x6, 1
    beq  x6, x0, loop
    sw   x2, 24(x1)
    beq  x4, x0, set_done
    addi x4, x4, -1
    beq  x4, x0, set_done
    jal  x0, loop

set_pause:
    sw   x5, 28(x1)
    addi x3, x0, 2
    jal  x0, loop

state_pause:
    andi x7, x5, 1
    beq  x7, x0, loop
    sw   x5, 28(x1)
    sw   x2, 24(x1)
    addi x3, x0, 1
    jal  x0, loop

state_done:
    andi x7, x5, 1
    beq  x7, x0, loop
    sw   x5, 28(x1)
    addi x3, x0, 0
    lw   x4, 0(x1)
    jal  x0, loop
