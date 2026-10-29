# Sorting Algorithm Template in RISC-V Assembly - Tyler Bibus
# This template provides a basic structure for implementing a sorting algorithm (i.e. mergesort) in RISC-V assembly language.

# Note: You MUST put the sorted array back in the SAME memory location as the original array.
#       During grading we will insert our own array and corresponding array_size for testing.
#       The max size will be 512 elements.
#
# Proj1_mergesort.s: top-down recursive merge sort (https://en.wikipedia.org/wiki/Merge_sort).
#   sort(array, size): if size < 2 return. Split at mid = size / 2, sort(left half), sort(right half),
#   then merge(array, mid, size). Values are compared as signed integers. The sort is stable
#   (on equal values the left element goes first).
#   merge copies only the LEFT run to a temporary buffer (temp, size/2 words) and then merges the
#   temp copy and the right run back into the original array. The right run is already in place,
#   so once the left run is used up the merge is finished. Only half-size temp storage is needed,
#   which matters because the data memory is only 4 KB: array (512 words) + temp (256 words) + stack
#   still fit for the maximum size of 512 elements.
.data
    array_size: .word 12
    array: .word 65, 12, 10, 89, 11, 70, 67, 5, 9, 45, 90, 7
    # TODO: You may add additional temporary data here
    temp: .space 1024            # temporary copy of the left run: 256 words (half of the maximum 512 elements)
.text
.globl main

main:
    # added: initialize sp. RARS starts with sp = 0x7FFFEFFC but our processor's registers all reset to 0,
    # so sp is set here (0x7FFFF000 - 4 = 0x7FFFEFFC) to make the stack addresses match RARS.
    lui  sp, 0x7FFFF
    addi sp, sp, -4
    # Save return address
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Call sorting function
    la a0, array
    lw a1, array_size
    jal ra, sort

    # restore stack
    lw ra, 0(sp)
    addi sp, sp, 4
    
    # Exit program
    # (was: wfi) -- the wfi is now the last instruction of the file (program_exit below). RARS keeps executing
    # past a wfi, so a wfi in the middle of the file makes the RARS trace run into sort again and the comparison fails.
    j    program_exit

# void sort(int* array, int size);
.globl sort
sort:
# TODO: Implement your sorting algorithm here.
    li   t0, 2
    blt  a1, t0, sort_leaf       # size < 2: already sorted

    addi sp, sp, -16             # activation record: ra, s0 (array), s1 (size), s2 (mid)
    sw   ra, 12(sp)
    sw   s0, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)

    mv   s0, a0                  # s0 = array
    mv   s1, a1                  # s1 = size
    srli s2, a1, 1               # s2 = mid = size / 2

    mv   a1, s2                  # sort(array, mid)                    left half
    jal  ra, sort

    slli t0, s2, 2               # sort(array + mid, size - mid)       right half
    add  a0, s0, t0
    sub  a1, s1, s2
    jal  ra, sort

    mv   a0, s0                  # merge(array, mid, size)
    mv   a1, s2
    mv   a2, s1
    jal  ra, merge

    lw   ra, 12(sp)
    lw   s0, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 16
sort_leaf:
    jr   ra

# void merge(int* array, int mid, int size);
# array[0 .. mid) and array[mid .. size) are each sorted. Leaf function, uses only temporary registers.
#   a0 = array, a1 = mid, a2 = size
#   t0 = temp, t1 = i (index into temp), t2 = j (index into array, right run), t3 = k (index into array, output)
merge:
    la   t0, temp
    li   t1, 0
copy_left:                       # temp[0 .. mid) = array[0 .. mid)
    slli t2, t1, 2
    add  t3, a0, t2
    lw   t4, 0(t3)
    add  t3, t0, t2
    sw   t4, 0(t3)
    addi t1, t1, 1
    blt  t1, a1, copy_left

    li   t1, 0                   # i = 0
    mv   t2, a1                  # j = mid
    li   t3, 0                   # k = 0
merge_loop:
    bge  t1, a1, merge_done      # left run used up: the rest of the right run is already in place
    bge  t2, a2, drain_left      # right run used up: copy the rest of the left run
    slli t4, t1, 2
    add  t4, t0, t4
    lw   t5, 0(t4)               # t5 = temp[i]
    slli t6, t2, 2
    add  t6, a0, t6
    lw   a3, 0(t6)               # a3 = array[j]
    slli a4, t3, 2
    add  a4, a0, a4              # a4 = &array[k]
    blt  a3, t5, take_right      # array[j] < temp[i]: take the right element (equal: take left, keeps the sort stable)
    sw   t5, 0(a4)               # array[k] = temp[i]
    addi t1, t1, 1
    j    merge_next
take_right:
    sw   a3, 0(a4)               # array[k] = array[j]
    addi t2, t2, 1
merge_next:
    addi t3, t3, 1
    j    merge_loop
drain_left:                      # array[k ..] = temp[i .. mid)
    bge  t1, a1, merge_done
    slli t4, t1, 2
    add  t4, t0, t4
    lw   t5, 0(t4)
    slli a4, t3, 2
    add  a4, a0, a4
    sw   t5, 0(a4)
    addi t1, t1, 1
    addi t3, t3, 1
    j    drain_left
merge_done:
    jr   ra

program_exit:
    wfi
