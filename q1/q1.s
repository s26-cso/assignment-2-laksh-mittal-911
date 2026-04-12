
# struct Node layout (24 bytes):
#   offset  0 - int val      (4 bytes)
#   offset  4 - padding      (4 bytes, needed so pointers are 8-byte aligned)
#   offset  8 - Node* left   (8 bytes)
#   offset 16 - Node* right  (8 bytes)

.section .text

.globl make_node
.globl insert
.globl get
.globl getAtMost





make_node:
    addi  sp, sp, -16
    sd    ra, 8(sp)
    sw    a0, 0(sp)            # save val before malloc trashes a0

    li    a0, 24
    call  malloc               # allocate 24 bytes for the node

    lw    t0, 0(sp)            # get val back
    sw    t0, 0(a0)            # node->val = val
    sd    zero, 8(a0)          # node->left = NULL
    sd    zero, 16(a0)         # node->right = NULL

    ld    ra, 8(sp)
    addi  sp, sp, 16
    ret





insert:
    addi  sp, sp, -32
    sd    ra, 24(sp)
    sd    s0, 16(sp)
    sd    s1,  8(sp)

    mv    s0, a0               # s0 = root (safe across calls)
    mv    s1, a1               # s1 = val  (safe across calls)

    beq   s0, zero, insert_base_case

    lw    t0, 0(s0)            # t0 = root->val
    blt   s1, t0, insert_go_left

    # val >= root->val, so go right
    ld    a0, 16(s0)
    mv    a1, s1
    call  insert
    sd    a0, 16(s0)           # root->right = result
    j     insert_done

insert_go_left:
    ld    a0, 8(s0)
    mv    a1, s1
    call  insert
    sd    a0, 8(s0)            # root->left = result
    j     insert_done

insert_base_case:
    mv    a0, s1
    call  make_node            # leaf node for this value
    j     insert_return        # a0 already has the new node, skip mv below

insert_done:
    mv    a0, s0               # return the original root unchanged

insert_return:
    ld    ra, 24(sp)
    ld    s0, 16(sp)
    ld    s1,  8(sp)
    addi  sp, sp, 32
    ret





get:
    addi  sp, sp, -32
    sd    ra, 24(sp)
    sd    s0, 16(sp)
    sd    s1,  8(sp)

    mv    s0, a0
    mv    s1, a1

    beq   s0, zero, get_not_found

    lw    t0, 0(s0)            # t0 = root->val
    beq   t0, s1, get_found
    blt   s1, t0, get_go_left

    ld    a0, 16(s0)           # go right
    mv    a1, s1
    call  get
    j     get_return

get_go_left:
    ld    a0, 8(s0)            # go left
    mv    a1, s1
    call  get
    j     get_return

get_found:
    mv    a0, s0
    j     get_return

get_not_found:
    li    a0, 0                # return NULL

get_return:
    ld    ra, 24(sp)
    ld    s0, 16(sp)
    ld    s1,  8(sp)
    addi  sp, sp, 32
    ret





getAtMost:
    mv    t0, a1               # t0 = current node
    mv    t1, a0               # t1 = target val
    li    t2, -1               # t2 = best result so far

getAtMost_loop:
    beq   t0, zero, getAtMost_done

    lw    t3, 0(t0)            # t3 = current->val
    blt   t1, t3, getAtMost_go_left   # current->val > val, go left

    mv    t2, t3               # current->val <= val, update best
    ld    t0, 16(t0)           # go right for potentially larger valid value
    j     getAtMost_loop

getAtMost_go_left:
    ld    t0, 8(t0)
    j     getAtMost_loop

getAtMost_done:
    mv    a0, t2
    ret
    