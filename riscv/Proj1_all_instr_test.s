# Proj1_all_instr_test.s -- one program that exercises every instruction the datapath supports:
#   add sub and or xor slt sltu sll srl sra            (R-type)
#   addi andi ori xori slti sltiu slli srli srai       (I-type ALU)
#   lui auipc                                          (U-type)
#   lw lb lbu lh lhu sw                                (memory; sb/sh are not supported)
#   beq bne blt bge bltu bgeu jal jalr                 (control flow, incl. recursion depth 6)
#   wfi                                                (halt)
# Edge values used: 0, 1, -1, INT_MIN (0x80000000), INT_MAX (0x7FFFFFFF), shift amounts 0/1/31/33.
# Section 1 = arithmetic/logic/shift/compare, section 2 = loads/stores, section 3 = branches/jumps.
# Subroutines sit at the end, before the single wfi, because the toolflow stops at wfi.
.data
w0: .word 0x80FF7F01     # bytes (little endian): 01 7F FF 80
w1: .word 0x12345678
w2: .word 0xFFFF8000
w3: .word 0

.text
main:
# ---------------- section 1: arithmetic / logic / shifts ----------------
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

# ---------------- section 2: loads and stores ----------------
    la   s0, w0
    lw   t0, 0(s0)
    lb   t1, 0(s0)           # 0x00000001
    lb   t2, 1(s0)           # 0x0000007F
    lb   t3, 2(s0)           # 0xFFFFFFFF (sign extended)
    lb   t4, 3(s0)           # 0xFFFFFF80
    lbu  t5, 2(s0)           # 0x000000FF (zero extended)
    lbu  t6, 3(s0)           # 0x00000080
    lh   s1, 0(s0)           # 0x00007F01
    lh   s2, 2(s0)           # 0xFFFF80FF
    lhu  s3, 2(s0)           # 0x000080FF
    lhu  s4, 0(s0)
    lw   s5, 4(s0)
    lh   s6, 8(s0)           # 0xFFFF8000
    lhu  s7, 8(s0)           # 0x00008000
    lh   s8, 10(s0)          # 0xFFFFFFFF
    addi s9, s0, 8
    lw   s10, -4(s9)         # negative offset: w1
    lb   s11, -3(s9)         # 0x56
    li   a0, 0xDEADBEEF
    sw   a0, 12(s0)
    lw   a1, 12(s0)
    lb   a2, 12(s0)         # 0xFFFFFFEF
    lbu  a3, 13(s0)         # 0x000000BE
    lh   a4, 14(s0)         # 0xFFFFDEAD
    lhu  a5, 14(s0)         # 0x0000DEAD
    sw   a1, 0(s0)
    lw   a6, 0(s0)
    lb   a7, 3(s0)          # 0xFFFFFFDE

# ---------------- section 3: branches and jumps ----------------
    li   sp, 0x10011000
    li   s0, 0               # each skipped/executed path adds a different bit
    li   t0, 5
    li   t1, 5
    li   t2, -3
    li   t3, 7
    beq  t0, t1, L_beq1      # taken
    addi s0, s0, 1           # skipped
L_beq1:
    beq  t0, t3, L_beq2      # not taken
    addi s0, s0, 2
L_beq2:
    bne  t0, t3, L_bne1      # taken
    addi s0, s0, 4           # skipped
L_bne1:
    bne  t0, t1, L_bne2      # not taken
    addi s0, s0, 8
L_bne2:
    blt  t2, t0, L_blt1      # -3 < 5 taken
    addi s0, s0, 16          # skipped
L_blt1:
    blt  t0, t2, L_blt2      # 5 < -3 not taken
    addi s0, s0, 32
L_blt2:
    blt  t0, t1, L_blt3      # equal: not taken
    addi s0, s0, 64
L_blt3:
    bge  t0, t2, L_bge1      # 5 >= -3 taken
    addi s0, s0, 128         # skipped
L_bge1:
    bge  t2, t0, L_bge2      # -3 >= 5 not taken
    addi s0, s0, 256
L_bge2:
    bge  t0, t1, L_bge3      # equal: taken
    addi s0, s0, 512         # skipped
L_bge3:
    bltu t0, t2, L_bltu1     # 5 <u 0xFFFFFFFD taken
    addi s0, s0, 1024        # skipped
L_bltu1:
    bltu t2, t0, L_bltu2     # 0xFFFFFFFD <u 5 not taken
    addi s0, s0, 1023
L_bltu2:
    bltu t0, t1, L_bltu3     # equal: not taken
    addi s0, s0, 1022
L_bltu3:
    bgeu t2, t0, L_bgeu1     # 0xFFFFFFFD >=u 5 taken
    addi s0, s0, 1021        # skipped
L_bgeu1:
    bgeu t0, t2, L_bgeu2     # 5 >=u 0xFFFFFFFD not taken
    addi s0, s0, 1020
L_bgeu2:
    bgeu t0, t1, L_bgeu3     # equal: taken
    addi s0, s0, 1019       # skipped
L_bgeu3:
    # backward branch loop: t5 = 10 + 9 + ... + 1
    li   t4, 10
    li   t5, 0
loop:
    add  t5, t5, t4
    addi t4, t4, -1
    bne  t4, x0, loop

    # INT_MIN vs INT_MAX: signed and unsigned compares disagree
    li   t0, 0x80000000
    li   t1, 0x7FFFFFFF
    blt  t0, t1, E1          # taken (signed)
    addi s0, s0, 1
E1: bltu t0, t1, E2          # not taken (unsigned)
    addi s0, s0, 2
E2: bge  t1, t0, E3          # taken (signed)
    addi s0, s0, 4
E3: bgeu t0, t1, E4          # taken (unsigned)
    addi s0, s0, 8
E4:
    # call depth 6
    li   a0, 6
    jal  ra, fact            # a0 = 720
    mv   s1, a0

    # jalr: call a subroutine through a register and return
    la   t0, tgt1
    jalr ra, 0(t0)
    addi s2, x0, 111         # executed after the return

    # jalr with a nonzero immediate
    la   t0, tgt2
    addi t0, t0, -3
    jalr x0, 3(t0)           # target = tgt2
    addi s2, s2, 1000        # skipped
tgt2:
    # jalr with an odd target: bit 0 of the target must be cleared
    la   t0, tgt3
    addi t0, t0, 1
    jalr x0, 0(t0)
    addi s2, s2, 2000        # skipped
tgt3:
    j    done                # jal x0 (forward)
    addi s2, s2, 1500        # skipped
tgt1:
    addi s3, x0, 55
    jr   ra
done:
    j    finish


# int fact(int n): n <= 1 ? 1 : n * fact(n-1)  (the multiply is repeated addition)
fact:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   a0, 8(sp)
    li   t0, 1
    bgt  a0, t0, recurse
    li   a0, 1
    j    fact_ret
recurse:
    addi a0, a0, -1
    jal  ra, fact
    lw   t1, 8(sp)           # n
    mv   t2, a0              # fact(n-1)
    li   a0, 0
mul_loop:
    beq  t1, x0, fact_ret
    add  a0, a0, t2
    addi t1, t1, -1
    j    mul_loop
fact_ret:
    lw   ra, 12(sp)
    addi sp, sp, 16
    jr   ra
finish:
    wfi
