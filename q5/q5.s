.section .rodata
filename: .string "input.txt"
mode:     .string "r"
yes_str:  .string "Yes\n"
no_str:   .string "No\n"

.section .text
.globl main

main:
    # allocate stack space to save our return address and callee saved registers
    addi  sp, sp, -48
    sd    ra, 40(sp)
    sd    s0, 32(sp)           # s0 will safely hold our file pointer across function calls
    sd    s1, 24(sp)           # s1 will track the left index scanning from the start
    sd    s2, 16(sp)           # s2 will track the right index scanning from the end
    sd    s3,  8(sp)           # s3 will temporarily hold the character read from the left side

    # load the address of our filename and mode strings to call fopen
    la    a0, filename
    la    a1, mode
    call  fopen
    mv    s0, a0               # store the returned file pointer safely into s0 so it survives other calls

    # seek to the very end of the file so we can determine the total length
    mv    a0, s0
    li    a1, 0                # offset is zero
    li    a2, 2                # 2 represents seek end mode telling fseek to go to the end of the file
    call  fseek

    # call ftell to get the current position which tells us the total number of bytes in the file
    mv    a0, s0
    call  ftell
    
    addi  s2, a0, -1           # set our right index to total length minus one because of zero indexing
    li    s1, 0                # set our left index to zero representing the very beginning of the file

check_loop:
    bge   s1, s2, is_palindrome # if the left index crosses or equals the right index everything matched perfectly

    # prepare to read the character at the left index
    mv    a0, s0
    mv    a1, s1               # set our offset to the current left index
    li    a2, 0                # 0 represents seek set mode telling fseek to count from the start of the file
    call  fseek

    # read the character at the current file position
    mv    a0, s0
    call  fgetc
    mv    s3, a0               # stash the left character safely in s3 so we can reuse a0 for the next read

    # prepare to read the character at the right index
    mv    a0, s0
    mv    a1, s2               # set our offset to the current right index
    li    a2, 0                # again use seek set mode to count from the start
    call  fseek

    # read the character at the new file position
    mv    a0, s0
    call  fgetc                # a0 now contains the character from the right side of the file

    # check if the character from the left matches the character from the right
    bne   s3, a0, not_palindrome # if they are not equal we break out immediately and print no

    # they matched so we move our pointers one step closer to the middle
    addi  s1, s1, 1            # move left index forward by one
    addi  s2, s2, -1           # move right index backward by one
    j     check_loop           # jump back to the top of the loop to compare the next pair

is_palindrome:
    la    a0, yes_str          # load the success string
    call  printf               # print yes
    j     cleanup              # jump to the cleanup phase to close the file

not_palindrome:
    la    a0, no_str           # load the failure string
    call  printf               # print no

cleanup:
    # pass our saved file pointer to fclose to avoid any resource leaks
    mv    a0, s0
    call  fclose

    # restore all callee saved registers back to their original state before we exit
    li    a0, 0                # set our program return value to zero indicating success
    ld    ra, 40(sp)
    ld    s0, 32(sp)
    ld    s1, 24(sp)
    ld    s2, 16(sp)
    ld    s3,  8(sp)
    addi  sp, sp, 48           # deallocate our stack space
    ret
    