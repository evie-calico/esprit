;
; Binary to decimal (8-bit)
; Copyright 2018 Damian Yerrick
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
;
section "bcd",ROM0

;;
; Converts a 16-bit number from binary to decimal in about
; 200 cycles.
; @param HL the number
; @return C: digit in myriads place; D: digits in thousands and
; hundreds places; E: digits in tens and ones places; AB trashed
bcd16:
  ; Bits 15-13: Just shift left into A (12 c)
  xor a
  ld d,a
  ld c,a
  add hl,hl
  adc a
  add hl,hl
  adc a
  add hl,hl
  adc a

  ; Bits 12-9: Shift left into A and DAA (33 c)
  ld b,4
.l1:
  add hl,hl
  adc a
  daa
  dec b
  jr nz,.l1

  ; Bits 8-0: Shift left into E, DAA, into D, DAA, into C (139 c)
  ld e,a
  rl d
  ld b,9
.l2:
  add hl,hl
  ld a,e
  adc a
  daa
  ld e,a
  ld a,d
  adc a
  daa
  ld d,a
  rl c
  dec b
  jr nz,.l2

  ret

/*

;;
; Converts an 8-bit value to decimal.
; @param A the value
; @return A: tens and ones digits; B[1:0]: hundreds digit;
; B[7:2]: unspecified
bcd8bit_baa::

  swap a
  ld b,a
  and $0F  ; bits 3-0 in A, range $00-$0F
  or a     ; for some odd reason, AND sets half carry to 1
  daa      ; A=$00-$15

  sla b
  adc a
  daa
  sla b
  adc a
  daa      ; A=$00-$63
  rl b
  adc a
  daa
  rl b
  adc a
  daa
  rl b
  ret

section "pctdigit",ROM0
;;
; Calculates one digit of converting a fraction to a percentage.
; @param B numerator, less than C
; @param C denominator, greater than 0
; @return A = floor(10 * B / C); B = 10 * B % C;
; CHL unchanged; D clobbered; E = 0
pctdigit::
  ld de,$1000

  ; bit 3: A.E = B * 1.25
  ld a,b
  srl a
  rr e
  srl a
  rr e
  add b
  jr .have_first_carry

  ; bits 2-0: mul A.E by 2
  .bitloop:
    rl e
    adc a
  .have_first_carry:
    jr c,.yessub
    cp c
    jr c,.nosub
    .yessub:
      ; Usually A>=C so subtracting C won't borrow.  But if we
      ; arrived via yessub, A>256 so even though 256+A>=C, A<C.
      sub c
      or a
    .nosub:
    rl d
    jr nc,.bitloop

  ld b,a
  ; Binary to decimal subtracts if trial subtraction has no borrow.
  ; 6502/ARM carry: 0: borrow; 1: no borrow
  ; 8080 carry: 1: borrow; 0: borrow
  ; The 6502 interpretation is more convenient for binary to decimal
  ; conversion, so convert to 6502 discipline
  ld a,$0F
  xor d
  ret
*/
