.section .text
.globl main

main:
    # save all callee saved registers so standard C functions 
    # (malloc, atoi, printf) don't wreck our state
    addi  sp, sp, -64
    sd    ra, 56(sp)
    sd    s0, 48(sp)
    sd    s1, 40(sp)
    sd    s2, 32(sp)
    sd    s3, 24(sp)
    sd    s4, 16(sp)
    sd    s5,  8(sp)
    sd    s6,  0(sp)

    mv    s6, a1               # save argv safely before calling malloc
    addi  s0, a0, -1           # n = argc - 1 (skip the program name itself)

    # Allocate three arrays of size n (4 bytes per int)
    slli  a0, s0, 2
    call  malloc
    mv    s1, a0               # s1 = arr[] (the parsed integers)

    slli  a0, s0, 2
    call  malloc
    mv    s2, a0               # s2 = result[] (the final answers)

    slli  a0, s0, 2
    call  malloc
    mv    s3, a0               # s3 = stack[] (stores indices, not the actual values)

    li    s4, -1               # stack_top = -1 (means the stack is currently empty)
    li    s5, 0





parse_loop:
    bge   s5, s0, parse_done

    # extract argv[i+1] (pointers are 8 bytes in riscv64)
    addi  t0, s5, 1
    slli  t0, t0, 3
    add   t0, s6, t0
    ld    a0, 0(t0)
    
    # convert string to integer and store in arr[i]
    call  atoi
    slli  t1, s5, 2
    add   t1, s1, t1
    sw    a0, 0(t1)            

    addi  s5, s5, 1
    j     parse_loop

parse_done:
    addi  s5, s0, -1           # set iterator to n-1 (we scan right to left)





algo_loop:
    blt   s5, zero, algo_done

    # load current element arr[i]
    slli  t0, s5, 2
    add   t0, s1, t0
    lw    t2, 0(t0)            # t2 = arr[i]

    # if the guy on top of the stack is smaller or equal, pop him. he can't be the answer
pop_loop:
    blt   s4, zero, pop_done   # Stop if stack is empty

    slli  t0, s4, 2
    add   t0, s3, t0
    lw    t1, 0(t0)            # t1 = index at stack top

    slli  t3, t1, 2
    add   t3, s1, t3
    lw    t3, 0(t3)            # t3 = arr[stack.top()]

    bgt   t3, t2, pop_done     # found a strictly greater element and stop popping
    
    addi  s4, s4, -1           # pop()
    j     pop_loop

pop_done:
    # store the result for the current element
    slli  t0, s5, 2
    add   t0, s2, t0           # &result[i]

    blt   s4, zero, store_neg1 # if stack is empty no greater element exists

    # otherwise the index at the top of the stack is our answer
    slli  t1, s4, 2
    add   t1, s3, t1
    lw    t1, 0(t1)            
    sw    t1, 0(t0)
    j     push_i

store_neg1:
    li    t1, -1
    sw    t1, 0(t0)

push_i:
    # push the current index onto the stack for the next elements to the left to see
    addi  s4, s4, 1
    slli  t0, s4, 2
    add   t0, s3, t0
    sw    s5, 0(t0)            

    addi  s5, s5, -1           # Move left (i--)
    j     algo_loop

algo_done:
    li    s5, 0





print_loop:
    bge   s5, s0, print_done

    beq   s5, zero, skip_space
    la    a0, space_str
    call  printf

skip_space:
    slli  t0, s5, 2
    add   t0, s2, t0
    lw    a1, 0(t0)
    la    a0, int_fmt
    call  printf

    addi  s5, s5, 1
    j     print_loop

print_done:
    la    a0, newline_str
    call  printf

    # restore callee-saved registers and exit cleanly
    ld    ra, 56(sp)
    ld    s0, 48(sp)
    ld    s1, 40(sp)
    ld    s2, 32(sp)
    ld    s3, 24(sp)
    ld    s4, 16(sp)
    ld    s5,  8(sp)
    ld    s6,  0(sp)
    addi  sp, sp, 64

    li    a0, 0
    ret





.section .rodata
int_fmt:     .string "%d"
space_str:   .string " "
newline_str: .string "\n"
