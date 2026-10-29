# lw/sw test using only addi/add/sub/lw/sw/wfi (no lui/auipc/shifts needed yet).
# RARS keeps .data at 0x10010000, so we build that address by hand:
#   0x1001 = 2047 + 2047 + 3, then doubling 16 times gives 0x10010000.
# (The processor's data memory only uses address bits [11:2], so 0x10010000 maps to word 0.)
.data
buf: .word 0, 0, 0, 0

.text
main:
    addi x5, x0, 2047
    addi x6, x0, 2047
    add  x5, x5, x6          # 4094
    addi x5, x5, 3           # 4097 = 0x1001
    add  x5, x5, x5          # 0x2002
    add  x5, x5, x5          # 0x4004
    add  x5, x5, x5          # 0x8008
    add  x5, x5, x5          # 0x10010
    add  x5, x5, x5          # 0x20020
    add  x5, x5, x5          # 0x40040
    add  x5, x5, x5          # 0x80080
    add  x5, x5, x5          # 0x100100
    add  x5, x5, x5          # 0x200200
    add  x5, x5, x5          # 0x400400
    add  x5, x5, x5          # 0x800800
    add  x5, x5, x5          # 0x1001000
    add  x5, x5, x5          # 0x2002000
    add  x5, x5, x5          # 0x4004000
    add  x5, x5, x5          # 0x8008000
    add  x5, x5, x5          # 0x10010000  (x5 = base of .data)

    addi x1, x0, 5
    addi x2, x0, 7
    add  x3, x1, x2          # x3 = 12
    sw   x3, 0(x5)           # mem[0] = 12
    sw   x1, 4(x5)           # mem[1] = 5
    lw   x6, 0(x5)           # x6 = 12
    lw   x7, 4(x5)           # x7 = 5
    add  x8, x6, x7          # x8 = 17
    sw   x8, 8(x5)           # mem[2] = 17
    lw   x9, 8(x5)           # x9 = 17
    addi x11, x5, 8
    lw   x12, -4(x11)        # negative offset: x12 = 5
    sub  x13, x9, x6         # x13 = 5
    addi x14, x0, -1
    sw   x14, 12(x5)         # mem[3] = 0xFFFFFFFF
    lw   x15, 12(x5)         # x15 = -1
    wfi
