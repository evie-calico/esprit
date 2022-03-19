INCLUDE "bank.inc"
INCLUDE "entity.inc"
INCLUDE "text.inc"

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
    ldh a, [hCurrentBank]
    push af ; don't forget to save the current bank.

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
    ; Save parameters to be used by animation callbacks.
    ld hl, wMoveState
    ASSERT wMoveState.userIndex + 1 == wMoveState.moveBank
    ld a, b
    ld [hli], a
    ldh a, [hCurrentBank]
    ld [hli], a
    ld a, e
    ld [hli], a
    ld [hl], d

    ; Load up printing variables
    ; First the move name
    ASSERT Move_Name == 1
    inc de
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld d, a
    ld e, l
    ld hl, wUsedMove.move
    ldh a, [hCurrentBank]
    ld [hli], a
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    ; Then the user's name
    ld c, LOW(wEntity0_Bank)
    ld a, [bc]
    ld [hli], a
    rst SwapBank
    inc c
    ld a, [bc]
    ld l, a
    inc c
    ld a, [bc]
    ld h, a
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, l
    ld [wUsedMove.user + 1], a
    ld a, h
    ld [wUsedMove.user + 2], a

    ld hl, wEntityAnimation
    ld a, LOW(EntityAttackAnimation)
    ld [hli], a
    ld a, HIGH(EntityAttackAnimation)
    ld [hli], a
    ld a, LOW(.dispatchMoveAction)
    ld [hli], a
    ld a, HIGH(.dispatchMoveAction)
    ld [hli], a
    ld [hl], b

    ld b, BANK(xUsedText)
    ld hl, xUsedText
    call PrintHUD

    pop af
    rst SwapBank
    ret

.dispatchMoveAction
    ldh a, [hCurrentBank]
    push af

    ld hl, wMoveState
    ASSERT wMoveState.userIndex + 1 == wMoveState.moveBank
    ld a, [hli]
    ld b, a
    ld a, [hli]
    rst SwapBank
    ld a, [hli]
    ld e, a
    ld d, [hl]
    ; Check move action and execute.
    ASSERT Move_Action == 0
    ld a, [de]
    ld hl, .moveActions
    call HandleJumpTable

    pop af
    rst SwapBank
    ret

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
    ld b, b
    ld h, b ; Move the index to h; a more useful register.
    ld a, b
    ldh [hSaveUserIndex], a

    ASSERT Move_Chance == 3
    inc de
    inc de
    inc de
    push de
    push hl
    call Rand
    pop hl
    pop de
    ld c, a
    ld a, [de]
    cp a, c
    jp c, .miss

    ASSERT Move_Chance + 1 == Move_Range
    inc de
    ld a, [de] ; Load range and store for later.
    ldh [hRangeCounter], a

    ld l, LOW(wEntity0_PosX)
    ld a, [hli]
    ld b, a
    ld c, [hl]
.offsetDirection
    push de
        ld l, LOW(wEntity0_Direction)
        ld a, [hl]
        add a, a
        add a, LOW(DirectionVectors)
        ld e, a
        adc a, HIGH(DirectionVectors)
        sub a, e
        ld d, a
        ld a, [de]
        add a, b
        ld b, a
        inc de
        inc l
        ASSERT Entity_PosX + 1 == Entity_PosY
        ld a, [de]
        add a, c
        ld c, a
    pop de

    bankcall xCheckForEntity
    ld a, h
    and a, a
    jr nz, .found
    ; if not found, keep searching for each unit of range.
    ldh a, [hRangeCounter]
    dec a
    jr z, .miss
    ldh [hRangeCounter], a
    jr .offsetDirection

.found
    push hl
    ASSERT Move_Range + 1 == Move_Power
    inc de
    ; TODO: Damage target with move power here.
    ld a, [de]
    ld e, a ; Save the move power in e. We don't need de anymore.
    ld l, LOW(wEntity0_Health)
    ld a, [hl]
    sub a, e
    ld [hli], a
    ld a, [hl]
    sbc a, 0
    ld [hl], a
    ; Prepare for printing.
    ld a, e
    ld [wDealtDamage.value], a
    xor a, a
    ld [wDealtDamage.value + 1], a
    ld l, LOW(wEntity0_Bank)
    ld a, [hli]
    ld [wDealtDamage.target], a
    rst SwapBank
    ld a, [hli]
    ld h, [hl]
    ld l, a
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hli]
    ld [wDealtDamage.target + 1], a
    ld a, [hl]
    ld [wDealtDamage.target + 2], a

    ld b, BANK(xDealtText)
    ld hl, xDealtText
    call PrintHUD
    pop hl

    ; Finally, play the damage animation.
    ld b, h
    ld hl, wEntityAnimation
    ld a, LOW(EntityHurtAnimation)
    ld [hli], a
    ld a, HIGH(EntityHurtAnimation)
    ld [hli], a
    ld a, LOW(DefeatCheck)
    ld [hli], a
    ld a, HIGH(DefeatCheck)
    ld [hli], a
    ld [hl], b
    ld a, b
    ld [wDefeatCheckTarget], a
    ret

.miss
    ldh a, [hSaveUserIndex]
    ld h, a
    ld l, LOW(wEntity0_Bank)
    ld a, [hli]
    ld [wMissedMove.user], a
    rst SwapBank
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ASSERT EntityData_Name == 4
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hli]
    ld [wMissedMove.user + 1], a
    ld a, [hl]
    ld [wMissedMove.user + 2], a

    ld b, BANK(xMissedText)
    ld hl, xMissedText
    jp PrintHUD

SECTION "Defeat check", ROM0
DefeatCheck::
    ld a, [wDefeatCheckTarget]
    ld h, a
    ld l, LOW(wEntity0_Health)
    ld a, [hli]
    or a, [hl]
    jr z, .defeat
    bit 7, [hl]
    ret z
.defeat
    ld b, h
    ld hl, wEntityAnimation
    ld a, LOW(EntityDefeatAnimation)
    ld [hli], a
    ld a, HIGH(EntityDefeatAnimation)
    ld [hli], a
    ld a, LOW(.final)
    ld [hli], a
    ld a, HIGH(.final)
    ld [hli], a
    ld [hl], b
    ret

.final
    ld a, [wDefeatCheckTarget]
    ld h, a
    ld l, LOW(wEntity0_Bank)
    xor a, a
    ld [hli], a
    ret

SECTION "Used move text", ROMX
xUsedText:
    textcallptr wUsedMove.user
    db " used "
    textcallptr wUsedMove.move
    db "!<END>"

SECTION "Dealt damage text", ROMX
xDealtText:
    db "Dealt <U16>"
    dw wDealtDamage.value
    db " damage to "
    textcallptr wDealtDamage.target
    db "!<END>"

SECTION "Missed move text", ROMX
xMissedText:
    textcallptr wMissedMove.user
    db " missed!<END>"

SECTION UNION "Move text variables", WRAM0
wUsedMove:
.move ds 3
.user ds 3

SECTION UNION "Move text variables", WRAM0
wMissedMove:
.user ds 3

SECTION UNION "Move text variables", WRAM0
wDealtDamage:
.value dw
.target ds 3

; User to save the parameters of UseMove for animation callbacks.
SECTION "Move state", WRAM0
wMoveState:
.userIndex db
.moveBank db
.movePointer dw

SECTION "Defeat check target", WRAM0
; High byte of the entity for the coming defeat check to target.
wDefeatCheckTarget: db

SECTION "Attack range counter", HRAM
hRangeCounter: db
hSaveUserIndex: db
