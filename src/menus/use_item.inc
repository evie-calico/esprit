include "entity.inc"

def PLAYER_SPACING equ 24

def vPlayerDescriptions equ $9540
def idof_vPlayerDescriptions equ (vPlayerDescriptions >> 4) & $FF

rsreset
def USE_ITEM_ANIM_STOPPED rb 1
def USE_ITEM_ANIM_BEGIN rb 11
def USE_ITEM_ANIM_HURT rb 8
def USE_ITEM_ANIM_ATTK rb 8
def USE_ITEM_ANIM_IDLE rb 16
def USE_ITEM_ANIM_END rb 0

xUseItemMenu::
	db bank(@)
	dw xUseItemMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw xUseItemMenuA, xUseItemBlockAction, null, null, \
		null, null, xUseItemBlockAction, xUseItemBlockAction
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	db 3
	; Redraw
	dw xUseItemMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xUseItemMenuClose

xUseItemMenuInit:
	ld hl, wUseItemMenuCursor
	ld a, SCRN_VX - SCRN_X + 4
	ld [hli], a
	ld a, SCRN_Y + 4
	ld [hli], a
	ld a, idof_vItemCursor
	ld [hli], a
	ld [hl], OAMF_PAL1 | 1

	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	ld a, 12 * 8
	ld [wScrollInterp.y], a

	lb bc, idof_vPlayerDescriptions, $FF
	lb de, SCRN_Y_B, $90
	ld a, 12 * 8
	call TextInit
	ld hl, wUseItemCurrentPalette
	ld a, low(wOBJPaletteBuffer + 3 * 3 * 2)
	ld [hli], a
	ld [hl], high(wOBJPaletteBuffer + 3 * 3 * 2)
	for I, 3
		ld hl, wCurrentTextPosition
		ld a, low($9800 + 17 + (19 + I * 3) * 32)
		ld [hli], a
		ld [hl], high($9800 + 17 + (19 + I * 3) * 32)
		ld h, high(wEntity{d:I})
		ld de, vPlayer{d:I}
		call UseItemLoadEntity
	endr

	xor a, a
	ld [wUseAnimationTimer], a

	ret

xUseItemMenuRedraw:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	dec hl
	dec hl ; Size
	dec hl ; Selection
	ld b, [hl]
	push bc
		inc b
		ld a, SCRN_Y + 4 - PLAYER_SPACING
	.multiplySelection
		add a, PLAYER_SPACING
		dec b
		jr nz, .multiplySelection
		ld b, a
		ld c, SCRN_VX - SCRN_X + 4
		ld hl, wUseItemMenuCursor
		call DrawCursor
		ld hl, wSubMenuCursor
		ld a, [hli]
		ld c, a
		ld a, [hld]
		ld b, a
		call DrawCursor
	pop bc

	; Animate the player if the animation is playing
	ld hl, wUseAnimationTimer
	ld a, [hl]
	and a, a
	jr z, .noAnimation
		; a: value of wUseAnimationTimer
		; b: selection
		; hl: wUseAnimationTimer
		inc [hl]
		cp a, USE_ITEM_ANIM_BEGIN
		jr z, .begin
		cp a, USE_ITEM_ANIM_HURT
		jr z, .hurt
		cp a, USE_ITEM_ANIM_ATTK
		jr z, .attack
		cp a, USE_ITEM_ANIM_IDLE
		jr z, .idle
		cp a, USE_ITEM_ANIM_END
		jr nz, .noAnimation
		ld a, MENU_VALIDATED
		ld [wMenuClosingReason], a
		ld [hl], 0
		jr .noAnimation
	.idle
		; Idle is where the item is actually used, so call its handler and then
		; redraw stats.
		push bc
		ld a, b
		add a, high(wEntity0)
		ld b, a
		ld a, [wInventorySelection]
		call InventoryUseItem
		pop bc
		ld de, SPRITE_DIRECTION_SIZE * DOWN + ENTITY_FRAME_IDLE_OFFSET
		jr .load
	.begin
		ld de, SPRITE_DIRECTION_SIZE * LEFT + ENTITY_FRAME_IDLE_OFFSET
		jr .load
	.hurt
		ld de, SPRITE_DIRECTION_SIZE * LEFT + ENTITY_FRAME_HURT_OFFSET
		jr .load
	.attack
		ld de, SPRITE_DIRECTION_SIZE * LEFT + ENTITY_FRAME_ATTK_OFFSET
	.load
		call UseItemLoadAnimation
		PUSHS
		section "Use Item Handle Animation", rom0
		UseItemLoadAnimation:
			; b: selection
			; de: Entity graphic offset
			ld a, b
			add a, high(wEntity0)
			ld h, a
			ld l, low(wEntity0_Bank)
			ld a, [hli]
			; There's no way bank can be null if we're in the middle of an
			; animation
			rst SwapBank
			ld a, [hli]
			ld h, [hl]
			ld l, a
			assert EntityData_Graphics == 0
			ld a, [hli]
			ld h, [hl]
			ld l, a
			add hl, de
			ld de, (vPlayer0 & $7FFF) << 1
			assert (vPlayer1 - vPlayer0) << 1 == 256
		.mult
			inc d
			dec b
			jr nz, .mult
			assert vPlayer0 & $8000 != 0
			scf
			rr d
			rr e
			ld c, 64
			call VramCopySmall
			ld a, bank("Pause Menu")
			rst SwapBank
			ret
		POPS
.noAnimation
	lb bc, SCRN_Y + 4, SCRN_VX - SCRN_X + 24
	lb de, idof_vPlayer0, 2
	call xUseItemDrawPlayer
	lb bc, SCRN_Y + 4 + PLAYER_SPACING, SCRN_VX - SCRN_X + 24
	lb de, idof_vPlayer1, 3
	call xUseItemDrawPlayer
	lb bc, SCRN_Y + 4 + PLAYER_SPACING * 2, SCRN_VX - SCRN_X + 24
	lb de, idof_vPlayer2, 4
	call xUseItemDrawPlayer

	jp xScrollInterp

xUseItemMenuClose:
	ld a, [wActiveEntity]
	dec a
	jp z, UnwindMenus
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a
	ld a, 1
	ld [wInventoryRedrawDesc], a
	ld hl, xDrawInventoryMenu
	call DrawMenu
	jp xInventoryDrawItemNames

xUseItemMenuA:
	xor a, a
	ld [wMenuAction], a

	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hli]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Bank)
	ld a, [hl]
	and a, a
	ret z

	ld a, [wUseAnimationTimer]
	and a, a
	ret nz
	inc a ; ld a, 1
	ld [wUseAnimationTimer], a
	ld [wActiveEntity], a
	ret

xUseItemBlockAction:
	ld a, [wUseAnimationTimer]
	and a, a
	ret z
	xor a, a
	ld [wMenuAction], a
	ret

; @param b: Y
; @param c: X
; @param d: Tile
; @param e: Color
xUseItemDrawPlayer:
	ld a, [wUseAnimationTimer]
	and a, a
	jr nz, .noIdle
		ldh a, [hFrameCounter]
		and a, %00010000
		rra
		rra
		add a, d
		ld d, a
.noIdle
	push bc
	call RenderSimpleSprite
	pop bc
	ld a, c
	add a, 8
	ld c, a
	inc d
	inc d
	jp RenderSimpleSprite

PUSHS
section "Use item Menu rom0", rom0
UseItemLoadEntity:
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr nz, .exists
		ld hl, wUseItemCurrentPalette
		ld a, [hl]
		add a, 9
		ld [hli], a
		ld a, [hl]
		adc a, 0
		ld [hl], a

		ld h, d
		ld l, e
		lb bc, 0, 128
		jp VramSetSmall
.exists
	rst SwapBank
	ld a, h
	ld [wfmt_xPauseStatusString_target], a
	push hl ; Save entity pointer so you can print info later.
		ld a, [hli]
		ld h, [hl]
		ld l, a
		assert EntityData_Graphics == 0
		ld a, [hli]
		push hl
			ld h, [hl]
			ld l, a
			; Now get the facing forward idle frames
			assert SPRITE_DIRECTION_SIZE * DOWN >> 8 == 3
			inc h
			inc h
			inc h
			; Copy both
			ld c, 128
			call VramCopySmall
		pop hl
		inc hl
		ld a, [hli]
		ld h, [hl]
		ld l, a
		assert EntityData_Palette == 2
		ld de, wUseItemCurrentPalette
		ld a, [de]
		inc de
		ld b, a
		ld a, [de]
		ld d, a
		ld e, b
		ld c, 3 * 3
		call MemCopySmall
		ld hl, wUseItemCurrentPalette
		ld a, e
		ld [hli], a
		ld [hl], d
		call ReloadColor
	pop hl
	; Now throw in the level, health, and max health.
	ld b, h
	ld l, low(wEntity0_Level)
	ld a, [hli]
	call GetMaxHealth
	ld a, l
	ld [wfmt_xPauseStatusString_maxHealth], a
	ld a, h
	ld [wfmt_xPauseStatusString_maxHealth + 1], a
	ld h, b
	ld l, low(wEntity0_Health)
	ld a, [hli]
	ld [wfmt_xPauseStatusString_health], a
	ld a, [hli]
	ld [wfmt_xPauseStatusString_health + 1], a

	; Finally, print!
	ld a, 1
	ld b, bank(xPauseStatusString)
	ld hl, xPauseStatusString
	call PrintVWFText
	lb de, 12, 4
	ld hl, wCurrentTextPosition
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call TextDefineBox
	call PrintVWFChar
	call DrawVWFChars
	ld a, bank("Pause Menu")
	rst SwapBank
	ret

section "Use Item vars", wram0
wUseItemCurrentPalette: dw
wCurrentTextPosition: dw
wUseAnimationTimer: db

POPS
