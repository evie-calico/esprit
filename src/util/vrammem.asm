;
; vrammem.asm
; Memory functions which wait for VRAM access before writing.
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

INCLUDE "hardware.inc"

SECTION "VRAM Memory Copy", ROM0
; Waits for VRAM access before copying data.
; @param bc: length
; @param de: destination
; @param hl: source
VRAMCopy::
    dec bc
    inc b
    inc c
.loop:
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, .loop

    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
    ret

SECTION "VRAM Small Memory Copy", ROM0
; Waits for VRAM access before copying data. Slightly faster than vmemcopy with
; less setup, but can only copy 256 bytes at a time.
; @param  c: length
; @param de: destination
; @param hl: source
VRAMCopySmall::
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, VRAMCopySmall
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, VRAMCopySmall
    ret

SECTION "VRAM Memory Set", ROM0
; Waits for VRAM access before setting data.
; @param  d: source (is preserved)
; @param bc: length
; @param hl: destination
VRAMSet::
    inc b
    inc c
    jr .decCounter
.loadByte
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, .loadByte

    ld a, d
    ld [hli], a
.decCounter
    dec c
    jr nz, .loadByte
    dec b
    jr nz, .loadByte
    ret

SECTION "VRAM Memory Set Small", ROM0
; Waits for VRAM access before setting data.
; @param  b: source (is preserved)
; @param  c: length
; @param hl: destination
VRAMSetSmall::
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, VRAMSetSmall

    ld a, b
    ld [hli], a
    dec c
    jr nz, VRAMSetSmall
    ret
