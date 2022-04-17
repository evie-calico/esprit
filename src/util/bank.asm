;
; bank.asm
; Functions related to switching and managing ROMX banks.
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

SECTION "Swap Bank", ROM0[$0020 - 1]
BankReturn::
	pop af
; Sets rROMB0 and hCurrentBank to `a`
; @param a: Bank
SwapBank::
	ASSERT @ == $20
	ld [rROMB0], a
	ldh [hCurrentBank], a
	ret

SECTION "Far Call", ROM0[$0028]
; Calls a function in another bank
; @param  b:  Target bank
; @param hl: Target function.
FarCall::
	ldh a, [hCurrentBank]
	push af
	ld a, b
	rst SwapBank
	rst CallHL
	pop af
	jr SwapBank

SECTION "Memory Copy Far", ROM0
; Switches the bank before performing a copy.
; @param  b:  bank
; @param  c:  length
; @param de: destination
; @param hl: source
MemCopyFar::
	ldh a, [hCurrentBank]
	push af
	ld a, b
	rst SwapBank
.copy
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copy
	pop af
	rst SwapBank
	ret

SECTION "Current Bank", HRAM
hCurrentBank::
	DS 1
