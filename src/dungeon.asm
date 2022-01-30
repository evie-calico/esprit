INCLUDE "entity.inc"
INCLUDE "hardware.inc"

DEF DUNGEON_WIDTH EQU 64
DEF DUNGEON_HEIGHT EQU 64

SECTION "Init dungeon", ROMX
xInitDungeon::
    xor a, a
    ASSERT wDungeonMap + DUNGEON_WIDTH * DUNGEON_HEIGHT == wDungeonCameraX
    ASSERT wDungeonCameraX + 2 == wDungeonCameraY
    ld bc, DUNGEON_WIDTH * DUNGEON_HEIGHT + 4
    ld hl, wDungeonMap
    call MemSet

    ; Null out all entities.
    xor a, a
    FOR I, NB_ENTITIES
        ld bc, sizeof_Entity
        ld hl, wEntity{d:I}
        call MemSet
    ENDR
    ret

SECTION "Draw dungeon", ROMX
xDrawDungeon::
    ; Calculate the VRAM destination by (Camera >> 4) / 8 % 32 * 32
    ld hl, wDungeonCameraY + 1
    ld a, [hld]
    and a, %00001111
    ld d, a
    ld a, [hli]
    and a, %10000000
    REPT 2
        srl d
        rra
    ENDR
    ld e, a
    ; de = (Camera >> 4) / 8 % 32 * 32
    ld hl, $9800
    add hl, de ; Add to VRAM
    ; Adjust the X down by converting to an integer and then dividing by 8 (Camera >> 4) / 8
    ld a, [wDungeonCameraX + 1]
    ld b, a
    ld a, [wDungeonCameraX]
    ; Rather than shifting right 7 times, we can shift left once and then take the high byte.
    add a, a
    rl b
    ld a, b
    and a, 31
    ; Now we have the neccessary X index on the tilemap.
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; de = $9800 + CameraX % 32 + CameraY % 32 * 32
    push hl ; Save this value for later so that the following code can use hl

        ; Now find the top-left corner of the map to begin drawing from.
        ; Begin with Y
        ld a, [wDungeonCameraY + 1]
        ld l, a
        ld h, 0
        ld bc, wDungeonMap
        add hl, hl ; Camera Y * 2
        add hl, hl ; Camera Y * 4
        add hl, hl ; Camera Y * 8
        add hl, hl ; Camera Y * 16
        add hl, hl ; Camera Y * 32
        add hl, hl ; Camera Y * 64
        add hl, bc ; wDungeonMap + CameraY * 64
        ; Now X
        ld a, [wDungeonCameraX + 1]
        ; Use this add to move the value to de
        add a, l
        ld e, a
        adc a, h
        sub a, e
        ld d, a
        ; de = wDungonMap + CameraX + CameraY * 64
    pop hl

    ; Now copy the Dungeon map into VRAM
    ; Initialize counters.
    ld a, 10
    ldh [hMapDrawY], a
.drawRow
    ld a, 11
    ld [hMapDrawX], a
    push hl
.drawTile
        push hl
            call xDrawTile
        pop hl
        call xVramWrapRight
        ld a, [hMapDrawX]
        dec a
        ld [hMapDrawX], a
        jr nz, .drawTile
    pop hl
    call xVramWrapDown
    ld a, [hMapDrawY]
    dec a
    ld [hMapDrawY], a
    jr nz, .drawRow
    ret

; Draw a tile pointed to by HL to VRAM at DE.
xDrawTile:
    ld a, [de]
    inc e
    add a, $80
    ld c, a
:   ldh a, [rSTAT]
    and a, STATF_BUSY
    jr nz, :-
    ; After waiting for VRAM we have at least 17 safe cycles of VRAM address.
    ; The following code takes 14.
    ld a, c
    ld [hli], a
    ld [hli], a
    ld bc, $20 - 2
    add hl, bc
    ld [hli], a
    ld [hli], a
    ret

; Move the VRAM pointer to the right by 16 pixels, wrapping around to the left
; if needed.
; @hl: VRAM pointer
; @clobbers a, b
xVramWrapRight:
    ld a, l
    and a, %11100000 ; Grab the upper bits, which should stay constant.
    ld b, a
    ld a, l
    add a, 2
    and a, %00011111
    or a, b
    ld l, a
    ret

; Move the VRAM pointer down by 16 pixels, wrapping around to the top if needed.
; @hl: VRAM pointer
; @clobbers a
xVramWrapDown:
    ld a, $40
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; If the address is still below $9C00, we do not yet need to wrap.
    cp a, $9C
    ret c
    ; Otherwise, wrap the address around to the top.
    ld h, $98
    ret

SECTION "Dungeon map", WRAM0
; This map uses 4096 bytes of WRAM, but is only ever used in dungeons.
; If more RAM is needed for other game states, it should be unionized with this
; map.
wDungeonMap:: ds DUNGEON_WIDTH * DUNGEON_HEIGHT
wDungeonCameraX:: dw
wDungeonCameraY:: dw

SECTION "Map drawing counters", HRAM
hMapDrawX: db
hMapDrawY: db
