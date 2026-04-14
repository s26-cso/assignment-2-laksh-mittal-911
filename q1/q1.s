# struct node layout is 24 bytes total
# offset 0 is int val which takes 4 bytes
# offset 4 is padding of 4 bytes to align pointers to 8 bytes memory boundaries
# offset 8 is left node pointer which takes 8 bytes
# offset 16 is right node pointer which takes 8 bytes

.section .text

.globl make_node
.globl insert
.globl get
.globl getAtMost





make_node:
    # allocate stack space to save return address and argument
    addi  sp, sp, -16
    sd    ra, 8(sp)
    sw    a0, 0(sp)            # save our val argument because malloc will overwrite a0

    li    a0, 24
    call  malloc               # malloc 24 bytes for the new node

    lw    t0, 0(sp)            # get back our saved val from the stack
    sw    t0, 0(a0)            # store val into node at offset 0
    sd    zero, 8(a0)          # initialize left child pointer to null at offset 8
    sd    zero, 16(a0)         # initialize right child pointer to null at offset 16

    # restore return address and free stack before returning
    ld    ra, 8(sp)
    addi  sp, sp, 16
    ret





insert:
    # set up stack frame and save callee saved registers for recursive calls
    addi  sp, sp, -32
    sd    ra, 24(sp)
    sd    s0, 16(sp)
    sd    s1,  8(sp)

    mv    s0, a0               # keep root safely in s0 across recursive calls
    mv    s1, a1               # keep value safely in s1 across recursive calls

    beq   s0, zero, insert_base_case # if root is null we hit the bottom so insert here

    lw    t0, 0(s0)            # load the value of the current node
    blt   s1, t0, insert_go_left # if our value is smaller we must traverse the left subtree

    # our value is greater than or equal to current node so traverse right
    ld    a0, 16(s0)           # load right child pointer as first argument
    mv    a1, s1               # set our value as second argument
    call  insert               # recursively insert into right subtree
    sd    a0, 16(s0)           # link the returned node back as our new right child
    j     insert_done          # skip over the left insertion logic

insert_go_left:
    ld    a0, 8(s0)            # load left child pointer as first argument
    mv    a1, s1               # set our value as second argument
    call  insert               # recursively insert into left subtree
    sd    a0, 8(s0)            # link the returned node back as our new left child
    j     insert_done

insert_base_case:
    mv    a0, s1
    call  make_node            # create a brand new leaf node for our value
    j     insert_return        # the new node is already in a0 so just return it

insert_done:
    mv    a0, s0               # return the original root node pointer unchanged

insert_return:
    # restore all saved registers and clean up stack
    ld    ra, 24(sp)
    ld    s0, 16(sp)
    ld    s1,  8(sp)
    addi  sp, sp, 32
    ret





get:
    # create stack frame and save registers for recursion
    addi  sp, sp, -32
    sd    ra, 24(sp)
    sd    s0, 16(sp)
    sd    s1,  8(sp)

    mv    s0, a0               # save root node pointer safely
    mv    s1, a1               # save target search value safely

    beq   s0, zero, get_not_found # if we hit a null node the value is not in the tree

    lw    t0, 0(s0)            # load current node value
    beq   t0, s1, get_found    # if it exactly matches our target we are done
    blt   s1, t0, get_go_left  # if target is smaller we need to search left

    # target is larger so search the right subtree
    ld    a0, 16(s0)           # pass right child pointer
    mv    a1, s1               # pass target value
    call  get                  # recursive call
    j     get_return

get_go_left:
    # target is smaller so search the left subtree
    ld    a0, 8(s0)            # pass left child pointer
    mv    a1, s1               # pass target value
    call  get                  # recursive call
    j     get_return

get_found:
    mv    a0, s0               # put the found node pointer in a0 to return it
    j     get_return

get_not_found:
    li    a0, 0                # put null in a0 to indicate failure

get_return:
    # restore registers and pop stack frame
    ld    ra, 24(sp)
    ld    s0, 16(sp)
    ld    s1,  8(sp)
    addi  sp, sp, 32
    ret





getAtMost:
    # this function is iterative so no stack frame is needed
    mv    t0, a1               # t0 tracks the current node starting at root
    mv    t1, a0               # t1 holds the target value we want to stay under or equal to
    li    t2, -1               # t2 holds the best valid value found so far initialized to minus 1

getAtMost_loop:
    beq   t0, zero, getAtMost_done # stop looping when we reach a leaf node child

    lw    t3, 0(t0)            # load the value of our current node
    blt   t1, t3, getAtMost_go_left   # if current value is strictly greater than target it is invalid so go left

    # current value is less than or equal to target so it is a valid candidate
    mv    t2, t3               # update our best result with this valid value
    ld    t0, 16(t0)           # traverse right to see if we can find an even larger valid value
    j     getAtMost_loop       # continue searching

getAtMost_go_left:
    ld    t0, 8(t0)            # traverse left to find smaller values
    j     getAtMost_loop       # continue searching

getAtMost_done:
    mv    a0, t2               # move the best valid value into return register
    ret
