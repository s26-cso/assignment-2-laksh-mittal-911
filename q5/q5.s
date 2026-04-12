.section .rodata
filename: .string "input.txt"
mode:     .string "r"
yes_str:  .string "Yes\n"
no_str:   .string "No\n"

.section .text
.globl main

main:
    # set up stack and save callee saved registers
    addi  sp, sp, -48
    sd    ra, 40(sp)
    sd    s0, 32(sp)           # s0 is file pointer
    sd    s1, 24(sp)           # s1 is left index
    sd    s2, 16(sp)           # s2 is right index
    sd    s3,  8(sp)           # s3 is character at left index

    # open input file in read mode
    la    a0, filename
    la    a1, mode
    call  fopen
    mv    s0, a0               # save file pointer safely in s0

    # seek to end of file to find length
    mv    a0, s0
    li    a1, 0
    li    a2, 2                # 2 is seek end mode
    call  fseek

    # get total bytes
    mv    a0, s0
    call  ftell
    
    addi  s2, a0, -1           # set right index to len minus one
    li    s1, 0                # set left index to zero

check_loop:
    bge   s1, s2, is_palindrome # if left crosses right everything matched

    # seek to left index
    mv    a0, s0
    mv    a1, s1
    li    a2, 0                # 0 is seek set mode
    call  fseek

    # read character
    mv    a0, s0
    call  fgetc
    mv    s3, a0               # save left character in s3

    # seek to right index
    mv    a0, s0
    mv    a1, s2
    li    a2, 0
    call  fseek

    # read character
    mv    a0, s0
    call  fgetc                # a0 now holds right character

    # compare the two characters
    bne   s3, a0, not_palindrome # abort and print no if mismatch

    # move pointers inward
    addi  s1, s1, 1            # increment left
    addi  s2, s2, -1           # decrement right
    j     check_loop

is_palindrome:
    la    a0, yes_str
    call  printf
    j     cleanup

not_palindrome:
    la    a0, no_str
    call  printf

cleanup:
    # close the file
    mv    a0, s0
    call  fclose

    # restore registers and exit
    li    a0, 0
    ld    ra, 40(sp)
    ld    s0, 32(sp)
    ld    s1, 24(sp)
    ld    s2, 16(sp)
    ld    s3,  8(sp)
    addi  sp, sp, 48
    ret
