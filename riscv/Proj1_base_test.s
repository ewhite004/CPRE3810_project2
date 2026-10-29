# Proj1_base_test.s
# Uses every required arithmetic / logical instruction at least once:
#   add addi sub and or xor (nor built from or + xori) slt sltu slti sltiu
#   andi ori xori sll srl sra slli srli srai lui auipc, plus sw/lw to push results through memory.
# The program is a straight line (no branches), 1 instruction per cycle. Results are written to registers
# and used by later instructions, so a wrong value early on shows up in everything that follows.
# Each line ends with a comment of the form "# xN = value" (the value written to the register).
.text
main:
    # ---- build starting values with addi / lui ----
    addi x5,  x0, 25              # x5 = 0x00000019
    addi x6,  x0, 7               # x6 = 0x00000007
    addi x7,  x0, -3              # x7 = 0xFFFFFFFD
    lui  x28, 0x12345             # x28 = 0x12345000
    addi x28, x28, 0x678          # x28 = 0x12345678
    lui  x29, 0x80000             # x29 = 0x80000000
    addi x30, x0, 1               # x30 = 0x00000001
    # ---- add / sub ----
    add  x8,  x5, x6              # x8 = 0x00000020
    sub  x9,  x5, x6              # x9 = 0x00000012
    sub  x10, x6, x5              # x10 = 0xFFFFFFEE
    add  x11, x8, x9              # x11 = 0x00000032
    add  x12, x7, x7              # x12 = 0xFFFFFFFA
    sub  x13, x0, x7              # x13 = 0x00000003
    add  x14, x29, x29            # x14 = 0x00000000
    sub  x15, x29, x30            # x15 = 0x7FFFFFFF
    # ---- and / or / xor / nor ----
    and  x16, x28, x5             # x16 = 0x00000018
    or   x17, x28, x5             # x17 = 0x12345679
    xor  x18, x28, x5             # x18 = 0x12345661
    or   x19, x28, x29            # x19 = 0x92345678
    xori x19, x19, -1             # x19 = 0x6DCBA987
    and  x20, x17, x18            # x20 = 0x12345661
    or   x21, x16, x18            # x21 = 0x12345679
    xor  x22, x17, x17            # x22 = 0x00000000
    # ---- immediate logic ----
    andi x23, x28, 0x0FF          # x23 = 0x00000078
    ori  x24, x23, 0x700          # x24 = 0x00000778
    xori x25, x24, 0x5A5          # x25 = 0x000002DD
    andi x26, x7, -16             # x26 = 0xFFFFFFF0
    ori  x27, x0, -2048           # x27 = 0xFFFFF800
    # ---- compare ----
    slt  x31, x7, x6              # x31 = 0x00000001
    slt  x1,  x6, x7              # x1 = 0x00000000
    sltu x2,  x7, x6              # x2 = 0x00000000
    sltu x3,  x6, x7              # x3 = 0x00000001
    slti x4,  x7, -2              # x4 = 0x00000001
    slti x5,  x5, 25              # x5 = 0x00000000
    sltiu x6, x30, -1             # x6 = 0x00000001
    sltiu x7, x0, 1               # x7 = 0x00000001
    slt  x8,  x29, x15            # x8 = 0x00000001
    sltu x9,  x15, x29            # x9 = 0x00000001
    # ---- shifts (register amounts) ----
    addi x10, x0, 4               # x10 = 0x00000004
    addi x11, x0, 31              # x11 = 0x0000001F
    sll  x12, x28, x10            # x12 = 0x23456780
    srl  x13, x28, x10            # x13 = 0x01234567
    sra  x14, x29, x10            # x14 = 0xF8000000
    srl  x15, x29, x11            # x15 = 0x00000001
    sra  x16, x29, x11            # x16 = 0xFFFFFFFF
    sll  x17, x30, x11            # x17 = 0x80000000
    sll  x18, x28, x0             # x18 = 0x12345678
    # ---- shifts (immediate amounts) ----
    slli x19, x28, 8              # x19 = 0x34567800
    srli x20, x28, 8              # x20 = 0x00123456
    srai x21, x29, 8              # x21 = 0xFF800000
    srai x22, x28, 8              # x22 = 0x00123456
    slli x23, x30, 31             # x23 = 0x80000000
    srli x24, x29, 31             # x24 = 0x00000001
    srai x25, x29, 31             # x25 = 0xFFFFFFFF
    # ---- chain results together ----
    add  x26, x19, x20            # x26 = 0x3468AC56
    xor  x26, x26, x21            # x26 = 0xCBE8AC56
    sub  x26, x26, x22            # x26 = 0xCBD67800
    or   x26, x26, x23            # x26 = 0xCBD67800
    and  x26, x26, x25            # x26 = 0xCBD67800
    # ---- push values through memory (sw / lw) ----
    lui  x27, 0x10010             # x27 = 0x10010000
    sw   x26, 0(x27)              # mem[0x10010000] = 0xCBD67800
    sw   x28, 4(x27)              # mem[0x10010004] = 0x12345678
    sw   x29, 8(x27)              # mem[0x10010008] = 0x80000000
    lw   x1,  0(x27)              # x1 = 0xCBD67800
    lw   x2,  4(x27)              # x2 = 0x12345678
    lw   x3,  8(x27)              # x3 = 0x80000000
    add  x4,  x1, x2              # x4 = 0xDE0ACE78
    sub  x5,  x4, x3              # x5 = 0x5E0ACE78
    sw   x5,  12(x27)             # mem[0x1001000C] = 0x5E0ACE78
    lw   x6,  12(x27)             # x6 = 0x5E0ACE78
    # ---- auipc ----
    auipc x7, 0                   # x7 = 0x00400118
    auipc x8, 0x10                # x8 = 0x0041011C
    wfi
