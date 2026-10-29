# Arithmetic / logic / shift / compare test: every required ALU instruction, with edge cases.
# (INT_MIN = 0x80000000, INT_MAX = 0x7FFFFFFF, -1 = 0xFFFFFFFF, shift amounts 0, 1, 31 and 33)
.text
main:
    li   t0, 0x12345678
    li   t1, 0x9ABCDEF0
    li   t2, -1
    li   t3, 0x80000000
    li   t4, 0x7FFFFFFF
    li   t5, 31
    li   t6, 1

    # ---- register-register ----
    add  s0, t0, t1
    sub  s1, t0, t1
    sub  s2, t3, t6          # INT_MIN - 1 wraps to INT_MAX
    add  s3, t4, t6          # INT_MAX + 1 wraps to INT_MIN
    and  s4, t0, t1
    or   s5, t0, t1
    xor  s6, t0, t1
    xor  s7, t0, t0          # 0
    slt  a0, t3, t6          # INT_MIN < 1   -> 1
    slt  a1, t6, t3          # 1 < INT_MIN   -> 0
    slt  a2, t2, t6          # -1 < 1        -> 1
    slt  a3, t6, t2          # 1 < -1        -> 0
    slt  a4, t0, t0          # equal         -> 0
    sltu a5, t3, t6          # 0x80000000 <u 1          -> 0
    sltu a6, t6, t3          # 1 <u 0x80000000          -> 1
    sltu a7, t2, t6          # 0xFFFFFFFF <u 1          -> 0
    sltu s8, t6, t2          # 1 <u 0xFFFFFFFF          -> 1
    sll  s9, t0, t6          # shift by 1
    sll  s10, t0, t5         # shift by 31
    sll  s11, t0, x0         # shift by 0
    srl  a0, t3, t5          # 0x80000000 >> 31 = 1
    srl  a1, t2, t6          # 0x7FFFFFFF
    sra  a2, t3, t5          # 0xFFFFFFFF
    sra  a3, t2, t6          # 0xFFFFFFFF
    sra  a4, t0, t5          # 0
    sra  a5, t1, t6          # 0xCD5E6F78
    srl  a6, t1, t5          # 1
    sll  a7, t6, t5          # 0x80000000

    # only the low 5 bits of the shift amount count: 33 acts like 1
    li   t5, 33
    sll  s0, t0, t5
    srl  s1, t1, t5
    sra  s2, t1, t5

    # ---- immediates ----
    addi s3, t0, 1
    addi s4, t0, -1
    addi s5, t3, -1          # INT_MIN - 1
    andi s6, t1, 0x7F0
    andi s7, t1, -16         # immediate is sign extended: 0xFFFFFFF0
    ori  s8, t0, 0x7FF
    ori  s9, t0, -2048
    xori s10, t0, 0x555
    xori s11, t0, -1         # bitwise not
    slti a0, t3, 1           # INT_MIN < 1   -> 1
    slti a1, t6, -1          # 1 < -1        -> 0
    slti a2, t2, 0           # -1 < 0        -> 1
    sltiu a3, t6, -1         # 1 <u 0xFFFFFFFF -> 1
    sltiu a4, t2, 1          # 0xFFFFFFFF <u 1 -> 0
    sltiu a5, x0, 1          # 0 <u 1 -> 1 (seqz)
    slli a6, t0, 4
    slli a7, t0, 31
    slli s0, t0, 0
    srli s1, t1, 4
    srli s2, t1, 31
    srai s3, t1, 4
    srai s4, t1, 31
    srai s5, t0, 31
    srai s6, t3, 1

    # ---- upper immediates ----
    lui  s7, 0xFFFFF
    lui  s8, 0x12345
    auipc s9, 0
    auipc s10, 0x10
    auipc s11, 0xFFFFF
    wfi
