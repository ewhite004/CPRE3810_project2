# Proj1_cf_test.s
# Uses every required control flow instruction: beq bne blt bge bltu bgeu jal jalr (j, jr and ret are
# the same instructions as jal / jalr with x0). Each branch is tested both taken and not taken, with
# signed and unsigned edge values (-3 vs 5, INT_MIN vs INT_MAX) where the signed and unsigned compares disagree.
# Call depth: fact(6) recurses 6 levels deep, so there are 6 activation records (ra and n saved) on the stack.
# Final register values (checked by comparing with RARS):
#   s0 = branch bit pattern, s1 = fact(6) = 720 (0x2D0), s2 = 111, s3 = 55
.text
main:
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
