SECTION "Get Bit A", ROM0
; Returns the mask of the input value
; @ input:
; @ a:  Value
; @ output:
; @ a:  Mask
GetBitA::
    ; `a = 1 << a`. Used for indexing into bitfields.
    ; Thanks, calc84maniac.
    ; Check if resulting bit should be in high or low nibble
    sub a, 4
    jr nc, .highNibble
    ; Convert 0 -> $01, 1 -> $02, 2 -> $04, 3 -> $05
    add a, 2
    adc a, 3
    jr .fixupResult
.highNibble
    ; Convert 4 -> $10, 5 -> $20, 6 -> $40, 7 -> $50
    add a, -2
    adc a, 3
    swap a
.fixupResult
    ; If result was $05/$50, convert to $08/$80
    add a, a
    daa
    rra
    ret
