SECTION "Get Flag", ROM0
; @param c: flag id
; @return a: flag mask
; @return hl: flag pointer
; @clobbers b
GetFlag::
    ld a, c
    and a, 7 ; Get only the bits in A
    call GetBitA
    srl c
    srl c
    srl c
    ld b, 0
    ld hl, wFlags
    add hl, bc
    ret

SECTION "Flag memory", WRAM0
wFlags::
    ds 256 / 8