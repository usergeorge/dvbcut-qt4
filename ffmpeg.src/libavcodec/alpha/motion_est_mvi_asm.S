/*
 * Alpha optimized DSP utils
 * Copyright (c) 2002 Falk Hueffner <falk@debian.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include "regdef.h"

/* Some nicer register names.  */
#define ta t10
#define tb t11
#define tc t12
#define td AT
/* Danger: these overlap with the argument list and the return value */
#define te a5
#define tf a4
#define tg a3
#define th v0
        
        .set noat
        .set noreorder
        .arch pca56
        .text

/*****************************************************************************
 * int pix_abs16x16_mvi_asm(uint8_t *pix1, uint8_t *pix2, int line_size)
 *
 * This code is written with a pca56 in mind. For ev6, one should
 * really take the increased latency of 3 cycles for MVI instructions
 * into account.
 *
 * It is important to keep the loading and first use of a register as
 * far apart as possible, because if a register is accessed before it
 * has been fetched from memory, the CPU will stall.
 */
        .align 4
        .globl pix_abs16x16_mvi_asm
        .ent pix_abs16x16_mvi_asm
pix_abs16x16_mvi_asm:
        .frame sp, 0, ra, 0
        .prologue 0

#ifdef HAVE_GPROF
        lda     AT, _mcount
        jsr     AT, (AT), _mcount
#endif

        and     a1, 7, t0
        clr     v0
        lda     a3, 16
        beq     t0, $aligned
        .align 4
$unaligned:
        /* Registers:
           line 0:
           t0:  left_u -> left lo -> left
           t1:  mid
           t2:  right_u -> right hi -> right
           t3:  ref left
           t4:  ref right
           line 1:
           t5:  left_u -> left lo -> left
           t6:  mid
           t7:  right_u -> right hi -> right
           t8:  ref left
           t9:  ref right
           temp:
           ta:  left hi
           tb:  right lo
           tc:  error left
           td:  error right  */

        /* load line 0 */
        ldq_u   t0, 0(a1)       # left_u
        ldq_u   t1, 8(a1)       # mid
        ldq_u   t2, 16(a1)      # right_u
        ldq     t3, 0(a0)       # ref left
        ldq     t4, 8(a0)       # ref right
        addq    a0, a2, a0      # pix1
        addq    a1, a2, a1      # pix2
        /* load line 1 */        
        ldq_u   t5, 0(a1)       # left_u
        ldq_u   t6, 8(a1)       # mid
        ldq_u   t7, 16(a1)      # right_u
        ldq     t8, 0(a0)       # ref left
        ldq     t9, 8(a0)       # ref right
        addq    a0, a2, a0      # pix1
        addq    a1, a2, a1      # pix2
        /* calc line 0 */
        extql   t0, a1, t0      # left lo
        extqh   t1, a1, ta      # left hi
        extql   t1, a1, tb      # right lo
        or      t0, ta, t0      # left
        extqh   t2, a1, t2      # right hi
        perr    t3, t0, tc      # error left
        or      t2, tb, t2      # right
        perr    t4, t2, td      # error right
        addq    v0, tc, v0      # add error left
        addq    v0, td, v0      # add error left
        /* calc line 1 */
        extql   t5, a1, t5      # left lo
        extqh   t6, a1, ta      # left hi
        extql   t6, a1, tb      # right lo
        or      t5, ta, t5      # left
        extqh   t7, a1, t7      # right hi
        perr    t8, t5, tc      # error left
        or      t7, tb, t7      # right
        perr    t9, t7, td      # error right
        addq    v0, tc, v0      # add error left
        addq    v0, td, v0      # add error left
        /* loop */
        subq    a3,  2, a3      # h -= 2
        bne     a3, $unaligned
        ret

        .align 4
$aligned:
        /* load line 0 */
        ldq     t0, 0(a1)       # left
        ldq     t1, 8(a1)       # right
        addq    a1, a2, a1      # pix2
        ldq     t2, 0(a0)       # ref left
        ldq     t3, 8(a0)       # ref right
        addq    a0, a2, a0      # pix1
        /* load line 1 */
        ldq     t4, 0(a1)       # left
        ldq     t5, 8(a1)       # right
        addq    a1, a2, a1      # pix2
        ldq     t6, 0(a0)       # ref left
        ldq     t7, 8(a0)       # ref right
        addq    a0, a2, a0      # pix1
        /* load line 2 */
        ldq     t8, 0(a1)       # left
        ldq     t9, 8(a1)       # right
        addq    a1, a2, a1      # pix2
        ldq     ta, 0(a0)       # ref left
        ldq     tb, 8(a0)       # ref right
        addq    a0, a2, a0      # pix1
        /* load line 3 */
        ldq     tc, 0(a1)       # left
        ldq     td, 8(a1)       # right
        addq    a1, a2, a1      # pix2
        ldq     te, 0(a0)       # ref left
        ldq     tf, 8(a0)       # ref right
        /* calc line 0 */
        perr    t0, t2, t0      # error left
        addq    a0, a2, a0      # pix1
        perr    t1, t3, t1      # error right
        addq    v0, t0, v0      # add error left
        /* calc line 1 */
        perr    t4, t6, t0      # error left
        addq    v0, t1, v0      # add error right
        perr    t5, t7, t1      # error right
        addq    v0, t0, v0      # add error left
        /* calc line 2 */
        perr    t8, ta, t0      # error left
        addq    v0, t1, v0      # add error right
        perr    t9, tb, t1      # error right
        addq    v0, t0, v0      # add error left
        /* calc line 3 */
        perr    tc, te, t0      # error left
        addq    v0, t1, v0      # add error right
        perr    td, tf, t1      # error right
        addq    v0, t0, v0      # add error left
        addq    v0, t1, v0      # add error right
        /* loop */
        subq    a3,  4, a3      # h -= 4
        bne     a3, $aligned
        ret
        .end pix_abs16x16_mvi_asm
