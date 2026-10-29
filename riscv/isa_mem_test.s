# Load / store test: lw, lb, lbu, lh, lhu and sw with every byte/halfword position, signs and negative offsets.
.data
w0: .word 0x80FF7F01     # bytes (little endian): 01 7F FF 80
w1: .word 0x12345678
w2: .word 0xFFFF8000
w3: .word 0

.text
main:
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
    wfi
