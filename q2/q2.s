.section .text
.globl main

main:
    # save all callee saved registers so standard c functions 
    # like malloc atoi and printf do not wreck our state
    addi  sp, sp, -64
    sd    ra, 56(sp)
    sd    s0, 48(sp)
    sd    s1, 40(sp)
    sd    s2, 32(sp)
    sd    s3, 24(sp)
    sd    s4, 16(sp)
    sd    s5,  8(sp)
    sd    s6,  0(sp)

    mv    s6, a1               # save argv safely before calling malloc because a1 will be overwritten
    addi  s0, a0, -1           # calculate n as argc minus 1 to skip the program name itself

    # allocate space for the array of parsed integers
    slli  a0, s0, 2            # multiply n by 4 to get total bytes needed
    call  malloc
    mv    s1, a0               # store the pointer to our parsed integers array in s1

    # allocate space for the array of final answers
    slli  a0, s0, 2            # multiply n by 4 again
    call  malloc
    mv    s2, a0               # store the pointer to our results array in s2

    # allocate space for the stack array which stores indices rather than actual values
    slli  a0, s0, 2
    call  malloc
    mv    s3, a0               # store the pointer to our stack array in s3

    li    s4, -1               # set stack top pointer to minus 1 which means the stack is currently empty
    li    s5, 0                # set our loop iterator to 0 for the parsing phase





parse_loop:
    bge   s5, s0, parse_done   # exit loop if our iterator reaches n

    # extract the pointer to the next argument string
    addi  t0, s5, 1            # add 1 to skip the program name at index 0
    slli  t0, t0, 3            # multiply by 8 because pointers are 8 bytes in riscv64
    add   t0, s6, t0           # add offset to the base argv pointer
    ld    a0, 0(t0)            # load the string pointer into a0 for atoi
    
    # convert the string to a 32 bit integer
    call  atoi
    slli  t1, s5, 2            # calculate byte offset for the current array index by multiplying by 4
    add   t1, s1, t1           # add offset to the base address of our parsed integers array
    sw    a0, 0(t1)            # store the converted integer into the array

    addi  s5, s5, 1            # increment our loop iterator
    j     parse_loop

parse_done:
    addi  s5, s0, -1           # set iterator to n minus 1 so we can scan right to left





algo_loop:
    blt   s5, zero, algo_done  # exit the main algorithm loop when we have processed all elements

    # calculate memory address and load the current element
    slli  t0, s5, 2            # multiply current index by 4
    add   t0, s1, t0           # add offset to the base address of our integers array
    lw    t2, 0(t0)            # load the current integer value into t2

    # check the stack to find the next strictly greater element
    # if the element pointed to by the stack top is smaller or equal we pop it
    # we pop it because it is blocked by our current element and can never be the answer for elements to our left
pop_loop:
    blt   s4, zero, pop_done   # stop popping if the stack pointer drops below zero meaning the stack is empty

    slli  t0, s4, 2            # calculate offset for the stack top index
    add   t0, s3, t0           # add offset to the stack array base address
    lw    t1, 0(t0)            # load the stored original array index from the top of the stack

    slli  t3, t1, 2            # calculate offset to find the actual value in our parsed integers array
    add   t3, s1, t3           # add offset to the integers array base address
    lw    t3, 0(t3)            # load the actual integer value that corresponds to the index on the stack

    bgt   t3, t2, pop_done     # if the value on the stack is strictly greater than our current element we stop popping
    
    addi  s4, s4, -1           # pop the stack by decrementing the stack top pointer
    j     pop_loop

pop_done:
    # we finished popping so now we store the result for our current element
    slli  t0, s5, 2            # calculate offset for the current index
    add   t0, s2, t0           # add offset to the results array base address

    blt   s4, zero, store_neg1 # if the stack is completely empty it means no greater element exists to the right

    # the stack is not empty so the index sitting at the top of the stack is our answer
    slli  t1, s4, 2            # calculate offset for the top of the stack
    add   t1, s3, t1           # add offset to the stack array base address
    lw    t1, 0(t1)            # load the index from the stack
    sw    t1, 0(t0)            # save this index into our results array
    j     push_i

store_neg1:
    li    t1, -1               # load minus 1 to indicate no greater element was found
    sw    t1, 0(t0)            # save minus 1 into our results array

push_i:
    # push our current index onto the stack so elements to our left can potentially use it as their answer
    addi  s4, s4, 1            # increment the stack top pointer
    slli  t0, s4, 2            # calculate offset for the new stack top
    add   t0, s3, t0           # add offset to the stack array base address
    sw    s5, 0(t0)            # store our current index onto the stack

    addi  s5, s5, -1           # decrement our main loop iterator to move one step left
    j     algo_loop

algo_done:
    li    s5, 0                # reset our iterator to zero for the printing phase





print_loop:
    bge   s5, s0, print_done   # exit the print loop when we reach n

    beq   s5, zero, skip_space # skip printing a space if this is the very first element
    la    a0, space_str        # load the space string address
    call  printf

skip_space:
    slli  t0, s5, 2            # calculate offset for the current index
    add   t0, s2, t0           # add offset to the results array base address
    lw    a1, 0(t0)            # load the answer value into a1 for printing
    la    a0, int_fmt          # load the integer format string address
    call  printf               # print the answer

    addi  s5, s5, 1            # increment our print loop iterator
    j     print_loop

print_done:
    la    a0, newline_str      # load the newline string address
    call  printf               # print a newline at the very end of the output

    # restore all callee saved registers to their original state
    ld    ra, 56(sp)
    ld    s0, 48(sp)
    ld    s1, 40(sp)
    ld    s2, 32(sp)
    ld    s3, 24(sp)
    ld    s4, 16(sp)
    ld    s5,  8(sp)
    ld    s6,  0(sp)
    addi  sp, sp, 64           # deallocate our stack frame

    li    a0, 0                # set return value to zero indicating success
    ret





.section .rodata
int_fmt:     .string "%d"
space_str:   .string " "
newline_str: .string "\n"
