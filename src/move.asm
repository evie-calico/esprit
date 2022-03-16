INCLUDE "entity.inc"
INCLUDE "res/charmap.inc"

SECTION "Use Move", ROM0
; @param a: Move index
; @param b: Entity pointer high byte
UseMove::
    ; Each move pointer is 3 bytes.
    ld c, a
    add a, a ; a * 2
    add a, c ; a * 3
    add a, LOW(wEntity0_Moves)
    ld c, a
    ; Deref move into de.
    ld a, [bc]
    and a, a
    ret z ; Exit if the move's bank is 0.
    inc bc
    rst SwapBank
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a
    ; Check move action and execute.
    ASSERT Move_Action == 0
    ld a, [de]
    ld hl, .moveActions
    jp HandleJumpTable

; Functions to handle move behaviors.
; @param b: Entity pointer high byte
; @param de: Move pointer
.moveActions
    ASSERT MOVE_ACTION_ATTACK == 0
    dw MoveActionAttack

; Basic attack. Check <range> tiles in front of <entity>, and attack the first
; entity seen. Deals <power> damage and has a <chance> chance of succeeding.
; @param b: Entity pointer high byte
; @param de: Move pointer
MoveActionAttack:
    ASSERT Move_Chance == 3
    inc de
    inc de
    inc de
    push bc
    push de
    call Rand
    pop de
    pop bc
    ld c, a
    ld a, [de]
    cp a, c
    jr c, .miss

.miss
    ld c, LOW(wEntity0_Bank)
    ld a, [bc]
    inc c
    ld [wMissedEntity], a
    rst SwapBank
    ld a, [bc]
    ld l, a
    inc c
    ld a, [bc]
    ld h, a
    ASSERT EntityData_Name == 4
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hli]
    ld [wMissedEntity + 1], a
    ld a, [hl]
    ld [wMissedEntity + 2], a

    ld hl, wEntityAnimation
    ld a, LOW(EntityAttackAnimation)
    ld [hli], a
    ld a, HIGH(EntityAttackAnimation)
    ld [hli], a
    xor a, a
    ld [hli], a
    ld [hli], a
    ld [hl], b

    ld b, BANK(MissedText)
    ld hl, MissedText
    jp PrintHUD

MissedText:
    db "<CALL_PTR>"
    dw wMissedEntity
    db " missed!<END>"

SECTION "Missed text variable", WRAM0
wMissedEntity:: ds 3
