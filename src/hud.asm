include "defines.inc"
include "dungeon.inc"
include "entity.inc"
include "hardware.inc"
include "menu.inc"
include "vdef.inc"

def POPUP_SPEED equ 8

	dregion vStatusBar, 0, 26, 20, 2, $9C00
	dregion vHUD, 0, 28, 20, 4, $9C00
	dregion vTextbox, 1, 29, 18, 3, $9C00
	dregion vAttackWindow, 0, 0, 8, 5, $9C00
	dregion vAttackText, 2, 1, 8, 4, $9C00
	dtile_section $9000
	dtile vBlankTile
	dtile vTextboxTiles, vTextbox_Width * vTextbox_Height
	dtile vAttackTiles, vAttackText_Width * vAttackText_Height
	dtile vUIFrameTop
	dtile vUIFrameLeft
	dtile vUIFrameRight
	dtile vUIFrameLeftCorner
	dtile vUIFrameRightCorner
	dtile vUIArrowUp
	dtile vUIArrowRight
	dtile vUIArrowDown
	dtile vUIArrowLeft
	dtile vPlayerStatus, 16
	dtile vPartnerStatus, 16

section "User interface graphics", romx
xUIFrame:
	incbin "res/ui/hud_frame.2bpp", 16, 16 ; top
	incbin "res/ui/hud_frame.2bpp", 48, 16 ; left
	incbin "res/ui/hud_frame.2bpp", 80, 16 ; right
	incbin "res/ui/hud_frame.2bpp",  0, 16 ; top left
	incbin "res/ui/hud_frame.2bpp", 32, 16 ; top right
	incbin "res/ui/arrows.2bpp"
.end

section "Initialize user interface", rom0
InitUI::
	ld a, [hCurrentBank]
	push af

	ld a, bank(xUIFrame)
	rst SwapBank
	ld c, xUIFrame.end - xUIFrame
	ld de, vUIFrameTop
	ld hl, xUIFrame
	call VramCopySmall

	lb bc, 0, 16
	ld hl, vBlankTile
	call VramSetSmall

	xor a, a
	ld [wPrintString], a
	ld [wForceHudUpdate], a

	lb bc, idof_vBlankTile, vHUD_Width - 2
	ld hl, vHUD + 33
	call VramSetSmall
	ld c, vHUD_Width - 2
	ld hl, vHUD + 65
	call VramSetSmall
	ld c, vHUD_Width - 2
	ld hl, vHUD + 97
	call VramSetSmall
	call DrawStatusBar

	lb bc, idof_vUIFrameTop, vHUD_Width - 2
	ld hl, vHUD + 1
	call VramSetSmall
:       ldh a, [rSTAT]
		and a, STATF_BUSY
		jr nz, :-
	; 17.75 safe cycles.
	ld a, idof_vUIFrameRightCorner ; 2
	ld [vHUD + vHUD_Width - 1], a ; 5
	assert idof_vUIFrameRightCorner - 1 == idof_vUIFrameLeftCorner
	dec a ; 6
	ld [vHUD], a ; 9
	assert idof_vUIFrameLeftCorner - 1 == idof_vUIFrameRight
	dec a ; 10
	ld [vHUD + vHUD_Width - 1 + 32], a ; 13
	ld [vHUD + vHUD_Width - 1 + 64], a ; 16
:       ldh a, [rSTAT]
		and a, STATF_BUSY
		jr nz, :-
	; 17.75 safe cycles.
	ld a, idof_vUIFrameRight ; 2
	ld [vHUD + vHUD_Width - 1 + 96], a ; 5
	assert idof_vUIFrameRight - 1 == idof_vUIFrameLeft
	dec a ; 6
	ld [vHUD + 32], a ; 9
	ld [vHUD + 64], a ; 12
	ld [vHUD + 96], a ; 15

	ld a, low(ShowTextBox)
	ld [wSTATTarget], a
	ld a, high(ShowTextBox)
	ld [wSTATTarget + 1], a

	ld a, 144 - 32 - 1
	ldh [rLYC], a
	; Hide the window offscreen.
	ld a, SCRN_X
	ldh [hShadowWX], a
	ld a, SCRN_Y
	ldh [hShadowWY], a

	ldh a, [hSystem]
	and a, a
	jr z, .skipCGB
		; Load to the 7th palette.
		ld c, 4 * 3
		ld de, wBGPaletteBuffer + 4 * 3 * 7
		ld hl, wActiveMenuPalette
		ld a, [hli]
		rst SwapBank
		ld a, [hli]
		ld h, [hl]
		ld l, a
		assert MenuPal_Colors == 3
		inc hl
		inc hl
		inc hl
		call MemCopySmall

		ld a, 1
		ldh [rVBK], a
		ld d, 7
		ld bc, $400
		ld hl, $9C00
		call VramSet
		xor a, a
		ldh [rVBK], a
.skipCGB

	jp BankReturn

section "Print HUD", rom0
; Sets a string to print.
; @param b:  Bank of string
; @param hl: String to print
PrintHUD::
	ld a, b
	ld [wPrintString], a
	ld a, l
	ld [wPrintString + 1], a
	ld a, h
	ld [wPrintString + 2], a
	ret

section "Draw print string", rom0
; Draw a string to the HUD.
; This is called during the game loop after rendering entities, to ensure they
; do not fail to render if printing takes too long.
DrawPrintString::
	xor a, a
	ld [wTextLetterDelay], a
.customDelay::

	ld a, vTextbox_Width * 8
	lb bc, idof_vTextboxTiles, idof_vTextboxTiles + vTextbox_Width * vTextbox_Height
	lb de, vTextbox_Height, high(vTextboxTiles) & $F0
	call TextInit

	ld hl, wPrintString
	ld a, [hl]
	ld b, a
	ld [hl], 0
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, 1
	call PrintVWFText

	lb de, vTextbox_Width, vTextbox_Height
	ld hl, vTextbox
	call TextDefineBox
	call ReaderClear
	ld a, bank(TextClear)
	rst SwapBank
	call TextClear
	call PrintVWFChar
	jp DrawVWFChars

; @param h: entity high byte
PrepareStatus::
	ld a, h
	ld [wStatusString.name], a

	ld l, low(wEntity0_Level)
	ld a, [hli]
	push hl
		call GetMaxHealth
		ld a, l
		ld [wStatusString.maxHealth], a
		ld a, h
		ld [wStatusString.maxHealth + 1], a
	pop hl
	ld a, [hli]
	ld [wStatusString.health], a
	ld a, [hli]
	ld [wStatusString.health + 1], a

	; Display any active status effect
	ld l, low(wEntity0_PoisonTurns)
	ld a, [hl]
	and a, a
	jr z, .notPoisoned

	ld a, bank(xPoisonedStatus)
	ld [wStatusString.status], a
	ld a, low(xPoisonedStatus)
	ld [wStatusString.status + 1], a
	ld a, high(xPoisonedStatus)
	ld [wStatusString.status + 2], a
	ret

.notPoisoned
	; Show a tired status if fatigue is below a certain amount and no other effects are active.
	ld l, low(wEntity0_BlinkTurns)
	ld a, [hl]
	and a, a
	jr z, .notTired

	ld a, bank(xUnstableStatus)
	ld [wStatusString.status], a
	ld a, low(xUnstableStatus)
	ld [wStatusString.status + 1], a
	ld a, high(xUnstableStatus)
	ld [wStatusString.status + 2], a
	ret

.notUnstable
	; Show a tired status if fatigue is below a certain amount and no other effects are active.
	ld l, low(wEntity0_Fatigue)
	ld a, [hl]
	cp a, TIRED_THRESHOLD
	jr nc, .notTired

	ld a, bank(xTiredStatus)
	ld [wStatusString.status], a
	ld a, low(xTiredStatus)
	ld [wStatusString.status + 1], a
	ld a, high(xTiredStatus)
	ld [wStatusString.status + 2], a
	ret

.notTired
	; Show a plus sign if the entity has a revive active.
	ld l, low(wEntity0_CanRevive)
	ld a, [hl]
	and a, a
	jr z, .noStatus

	ld a, bank(xCanReviveStatus)
	ld [wStatusString.status], a
	ld a, low(xCanReviveStatus)
	ld [wStatusString.status + 1], a
	ld a, high(xCanReviveStatus)
	ld [wStatusString.status + 2], a
	ret

.noStatus
	xor a, a
	ld [wStatusString.status], a
	ld [wStatusString.status + 1], a
	ld [wStatusString.status + 2], a
	ret

section "Draw Status bar", rom0
; @clobbers bank
DrawStatusBar::
	ld h, high(wEntity0)
	call PrepareStatus

	ld a, vStatusBar_Width * 8
	lb bc, idof_vPlayerStatus, idof_vPlayerStatus + vStatusBar_Width
	lb de, 1, high(vPlayerStatus) & $F0
	call TextInit

	xor a, a
	ld [wTextLetterDelay], a

	ld a, 1
	ld b, bank(xStatusString)
	ld hl, xStatusString
	call PrintVWFText

	lb de, vStatusBar_Width, 1
	ld hl, vStatusBar + 1
	call TextDefineBox
	ld a, bank(TextClear)
	rst SwapBank
	call TextClear
	call PrintVWFChar
	call DrawVWFChars
.printPartner
	ld hl, wEntity1
	ld a, [hl]
	and a, a
	ret z
	call PrepareStatus

	ld a, vStatusBar_Width * 8
	lb bc, idof_vPartnerStatus, idof_vPartnerStatus + vStatusBar_Width
	lb de, 1, high(vPartnerStatus) & $F0
	call TextInit

	xor a, a
	ld [wTextLetterDelay], a

	ld a, 1
	ld b, bank(xStatusString)
	ld hl, xStatusString
	call PrintVWFText

	lb de, vStatusBar_Width, 1
	ld hl, vStatusBar + 33
	call TextDefineBox
	ld a, bank(TextClear)
	rst SwapBank
	call TextClear
	call PrintVWFChar
	jp DrawVWFChars

section "Attack window", romx
; TODO: make this more modular, akin to menu.asm, even if we only have 2.
; Add redraw, init, and target positions for the bounce animation
xUpdateAttackWindow::
	ld a, [wWindowMode]
	and a, a
	jr z, .close
	ld b, a
	ld a, [wWindowMode.last]
	cp a, b
	jr z, .open
	ld a, b
	ld [wWindowMode.last], a
	cp a, WINDOW_SHOW_MOVES
	call z, DrawAttackWindow
	ld a, [wWindowMode]
	cp a, WINDOW_TURNING
	call z, xDrawTurningWindow
.open
	ld a, [wWindowMode]
	cp a, WINDOW_TURNING
	jr nz, .noDirection
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, [wTrackedEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Direction)
	ld a, [hl]
	add a, idof_vUIArrowUp
	ld [vAttackWindow + 64 + 4], a
.noDirection

	ld a, [wWindowBounce]
	and a, a
	jr nz, .bounceEffect
	ldh a, [hShadowWX]
	cp a, SCRN_X - vAttackWindow_Width * 8
	jr z, :+
	sub a, POPUP_SPEED
	ldh [hShadowWX], a
	cp a, SCRN_X - vAttackWindow_Width * 8
	jr nz, :+
	ld a, 1
	ld [wWindowBounce], a
:   ld a, SCRN_Y - vAttackWindow_Height * 8 - 32
	ldh [hShadowWY], a
	ret

.close
	xor a, a
	ld [wWindowMode.last], a
	ld a, SCRN_X
	ldh [hShadowWX], a
	ld a, SCRN_Y
	ldh [hShadowWY], a
	ret

.bounceEffect
	dec a
	jr nz, .in
	ldh a, [hShadowWX]
	sub a, POPUP_SPEED / 2
	ldh [hShadowWX], a
	cp a, SCRN_X - vAttackWindow_Width * 8 - 12
	ret nz
	ld [wWindowBounce], a
	ret

.in
	ldh a, [hShadowWX]
	add a, POPUP_SPEED / 4
	ldh [hShadowWX], a
	cp a, SCRN_X - vAttackWindow_Width * 8
	ret nz
	xor a, a
	ld [wWindowBounce], a
	ret

xDrawTurningWindow:
	xor a, a
	ld [wWindowBounce], a
	ld a, SCRN_X
	ldh [hShadowWX], a
	ldh [rWX], a
	ld a, SCRN_Y
	ldh [hShadowWY], a
	ldh [rWY], a
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, idof_vUIFrameLeftCorner ; 2
	ld [vAttackWindow], a ; 6
	ld a, idof_vUIFrameLeft ; 8
	ld [vAttackWindow + 32], a ; 12
	ld [vAttackWindow + 64], a ; 16
	lb bc, idof_vUIFrameTop, vAttackWindow_Width + 2
	ld hl, vAttackWindow + 1
	call VramSetSmall
	; We actually have ~7 cycles coming out of this function.
	ld a, idof_vUIFrameLeft ; 2
	ld [vAttackWindow + 128], a ; 6
	lb bc, vAttackWindow_Width - 1, vAttackWindow_Height - 1
	ld d, idof_vBlankTile
	ld hl, vAttackWindow + 33
	call FillRegion
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, idof_vUIArrowUp
	ld [vAttackWindow + 32 + 4], a
	ld a, idof_vUIArrowLeft
	ld [vAttackWindow + 64 + 3], a
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, idof_vUIArrowRight
	ld [vAttackWindow + 64 + 5], a
	ld a, idof_vUIArrowDown
	ld [vAttackWindow + 96 + 4], a
	ret

section "Draw attack window", rom0
DrawAttackWindow::
	ldh a, [hCurrentBank]
	push af

	xor a, a
	ld [wWindowBounce], a
	ld a, SCRN_X
	ldh [hShadowWX], a
	ldh [rWX], a
	ld a, SCRN_Y
	ldh [hShadowWY], a
	ldh [rWY], a
	lb bc, vAttackWindow_Width - 1, vAttackWindow_Height - 1
	ld d, idof_vBlankTile
	ld hl, vAttackWindow + 33
	call FillRegion
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, idof_vUIFrameLeftCorner ; 2
	ld [vAttackWindow], a ; 6
	ld a, idof_vUIFrameLeft ; 8
	ld [vAttackWindow + 32], a ; 12
	ld [vAttackWindow + 64], a ; 16
	lb bc, idof_vUIFrameTop, vAttackWindow_Width + 2
	ld hl, vAttackWindow + 1
	call VramSetSmall
	; We actually have ~7 cycles coming out of this function.
	ld a, idof_vUIFrameLeft ; 2
	ld [vAttackWindow + 128], a ; 6
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, idof_vUIArrowUp ; 2
	ld [vAttackWindow + 1 + 32], a ; 6
	inc a ; 7
	ld [vAttackWindow + 1 + 64], a ; 11
	inc a ; 12
	ld [vAttackWindow + 1 + 96], a ; 16
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, idof_vUIArrowLeft ; 2
	ld [vAttackWindow + 1 + 128], a ; 6
	ld a, idof_vUIFrameLeft ; 8
	ld [vAttackWindow + 96], a ; 12

	xor a, a
	ld [wTextLetterDelay], a

	ld b, 4
	ld de, wMoveWindowBuffer
	ld a, [wTrackedEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Fatigue)
	ld c, [hl]
	ld l, low(wEntity0_Moves)
.copyMoves
	ld a, [hli]
	and a, a
	jr nz, :+
		inc hl
		inc hl
		jr .next
:
	rst SwapBank
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a

	ld a, TEXT_SET_COLOR
	ld [de], a
	inc de

	assert Move_Fatigue == 4
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, c
	cp a, [hl]
	ld a, 3
	jr nc, :+
	ld a, 1
:
	ld [de], a
	inc de
	assert Move_Fatigue + 1 == Move_Name
	inc hl
.strcpy
	ld a, [hli]
	and a, a
	jr z, .doneCopy
	ld [de], a
	inc de
	jr .strcpy
.doneCopy
	ld a, "\n"
	ld [de], a
	inc de
	pop hl
	inc hl
.next
	dec b
	jr nz, .copyMoves
.finished
	xor a, a
	ld [de], a

	ld hl, wMoveWindowBuffer
	ld a, 1
	call PrintVWFText

	; Draw move names
	ld a, vAttackText_Width * 8
	lb bc, idof_vAttackTiles, idof_vAttackTiles + vAttackText_Width * vAttackText_Height
	lb de, vAttackText_Height + 2, high(vAttackTiles) & $F0
	call TextInit

	lb de, vAttackText_Width, vAttackText_Height
	ld hl, vAttackText
	call TextDefineBox
	call PrintVWFChar
	call DrawVWFChars
	jp BankReturn

section "Show HP bar", rom0
ShowHPBar:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, ShowDungeonView
	; Set view
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_OBJ16
	ldh [rLCDC], a
	xor a, a
	ldh [rSCX], a
	ld a, 256 - 48
	ldh [rSCY], a
	; Prepare for next scanline effect
	ld a, 16
	ldh [rLYC], a
	ld a, low(ShowDungeonView)
	ld [wSTATTarget], a
	ld a, high(ShowDungeonView)
	ld [wSTATTarget + 1], a
	ret

section "Show dungeon", rom0
ShowDungeonView:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, ShowDungeonView
	; Reset view
	ldh a, [hShadowSCX]
	ldh [rSCX], a
	ldh a, [hShadowSCY]
	ldh [rSCY], a
	ldh a, [hShadowLCDC]
	ldh [rLCDC], a
	; Prepare for next scanline effect
	ld a, 144 - 32 - 1
	ldh [rLYC], a
	ld a, low(ShowTextBox)
	ld [wSTATTarget], a
	ld a, high(ShowTextBox)
	ld [wSTATTarget + 1], a
	ret

section "Show text box", rom0
ShowTextBox:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, ShowTextBox
	; Set view
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_OBJ16
	ldh [rLCDC], a
	xor a, a
	ldh [rSCX], a
	ld a, 256 - 144
	ldh [rSCY], a
	; Prepare for next scanline effect
	ld a, 145 ; A value over 144 means this will occur after the VBlank handler.
	ldh [rLYC], a
	ld a, low(ShowHPBar)
	ld [wSTATTarget], a
	ld a, high(ShowHPBar)
	ld [wSTATTarget + 1], a
	ret

section "Show only text box", rom0
ShowOnlyTextBox::
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, ShowOnlyTextBox
	; Set view
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_OBJ16
	ldh [rLCDC], a
	xor a, a
	ldh [rSCX], a
	ld a, 256 - 144
	ldh [rSCY], a
	ld a, 145 ; A value over 144 means this will occur after the VBlank handler.
	ldh [rLYC], a
	ld a, low(ResetView)
	ld [wSTATTarget], a
	ld a, high(ResetView)
	ld [wSTATTarget + 1], a
	ret

section "Reset view", rom0
ResetView:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, ResetView
	; Reset view
	ldh a, [hShadowSCX]
	ldh [rSCX], a
	ldh a, [hShadowSCY]
	ldh [rSCY], a
	ldh a, [hShadowLCDC]
	ldh [rLCDC], a
	; Prepare for next scanline effect
	ld a, 144 - 32 - 1
	ldh [rLYC], a
	ld a, low(ShowOnlyTextBox)
	ld [wSTATTarget], a
	ld a, high(ShowOnlyTextBox)
	ld [wSTATTarget + 1], a
	ret

section "Show Moves", wram0
wWindowMode:: db
.last db

section "Window effect bounce", wram0
wWindowBounce: db
wWindowSticky:: db

section "Print string", wram0
wPrintString:: ds 3
wStatusString::
.status:: ds 3
.health:: dw
.maxHealth:: dw
.name:: db

section "Move Window Buffer", wram0
wMoveWindowBuffer: ds (MOVE_MAXIMUM_LENGTH + 3) * ENTITY_MOVE_COUNT

section "Force HUD update", wram0
wForceHudUpdate:: db
