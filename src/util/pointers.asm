;
; pointers.asm
;
; Copyright 2021 Eievui
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.

SECTION "Null", ROM0[$0000]
null::
    db 0
    ret

SECTION "Call HL", ROM0[$0008]
; Used to call the address pointed to by `hl`. Mapped to `rst $08` or `rst CallHL`
CallHL::
    jp hl

SECTION "Call DE", ROM0
; Calls the value in `de` by pushing it and returning
CallDE::
    push de
    ret

SECTION "Jump Table", ROM0
; Jumps the the `a`th pointer. 128 pointers max. Place pointers after the call
; using `dw`. This function is faster than a decrement table if there are 8 or
; more destinations, and is always smaller.
; @param  a: Jump Offset.
; @param hl: Jump Table Pointer.
HandleJumpTable::
    ; a * 2 (pointers are 2 bytes!)
    add a, a
    ; add hl, a
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; Load pointer into hl
    ld a, [hli] ; low byte
    ld h, [hl] ; high byte
    ld l, a
    ; Now jump!
    jp hl
