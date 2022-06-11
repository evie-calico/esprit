INCLUDE "defines.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "menu.inc"
INCLUDE "text.inc"
INCLUDE "vdef.inc"

DEF POPUP_SPEED EQU 8

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
	dtile vUIFrameBottom
	dtile vPlayerStatus, 16
	dtile vPartnerStatus, 16

SECTION "User interface graphics", ROMX
xUIFrame:
	INCBIN "res/ui/hud_frame.2bpp", 16, 16 ; top
	INCBIN "res/ui/hud_frame.2bpp", 48, 16 ; left
	INCBIN "res/ui/hud_frame.2bpp", 80, 16 ; right
	INCBIN "res/ui/hud_frame.2bpp",  0, 16 ; top left
	INCBIN "res/ui/hud_frame.2bpp", 32, 16 ; top right
	INCBIN "res/ui/arrows.2bpp"
	INCBIN "res/ui/hud_frame.2bpp", 112, 16 ; bottom
.end

SECTION "Initialize user interface", ROM0
InitUI::
	ld a, [hCurrentBank]
	push af

	ld a, BANK(xUIFrame)
	rst SwapBank
	ld c, xUIFrame.end - xUIFrame
	ld de, vUIFrameTop
	ld hl, xUIFrame
	call VRAMCopySmall

	lb bc, 0, 16
	ld hl, vBlankTile
	call VRAMSetSmall

	xor a, a
	ld [wPrintString], a

	lb bc, idof_vBlankTile, vHUD_Width - 2
	ld hl, vHUD + 33
	call VRAMSetSmall
	ld c, vHUD_Width - 2
	ld hl, vHUD + 65
	call VRAMSetSmall
	ld c, vHUD_Width - 2
	ld hl, vHUD + 97
	call VRAMSetSmall
	call DrawStatusBar

	lb bc, idof_vUIFrameTop, vHUD_Width - 2
	ld hl, vHUD + 1
	call VRAMSetSmall
:       ldh a, [rSTAT]
		and a, STATF_BUSY
		jr nz, :-
	; 17.75 safe cycles.
	ld a, idof_vUIFrameRightCorner ; 2
	ld [vHUD + vHUD_Width - 1], a ; 5
	ASSERT idof_vUIFrameRightCorner - 1 == idof_vUIFrameLeftCorner
	dec a ; 6
	ld [vHUD], a ; 9
	ASSERT idof_vUIFrameLeftCorner - 1 == idof_vUIFrameRight
	dec a ; 10
	ld [vHUD + vHUD_Width - 1 + 32], a ; 13
	ld [vHUD + vHUD_Width - 1 + 64], a ; 16
:       ldh a, [rSTAT]
		and a, STATF_BUSY
		jr nz, :-
	; 17.75 safe cycles.
	ld a, idof_vUIFrameRight ; 2
	ld [vHUD + vHUD_Width - 1 + 96], a ; 5
	ASSERT idof_vUIFrameRight - 1 == idof_vUIFrameLeft
	dec a ; 6
	ld [vHUD + 32], a ; 9
	ld [vHUD + 64], a ; 12
	ld [vHUD + 96], a ; 15

	ld a, LOW(ShowTextBox)
	ld [wSTATTarget], a
	ld a, HIGH(ShowTextBox)
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
		ASSERT MenuPal_Colors == 3
		inc hl
		inc hl
		inc hl
		call MemCopySmall

		ld a, 1
		ldh [rVBK], a
		ld d, 7
		ld bc, $400
		ld hl, $9C00
		call VRAMSet
		xor a, a
		ldh [rVBK], a
.skipCGB

	jp BankReturn

SECTION "Print HUD", ROM0
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

SECTION "Draw print string", ROM0
; Draw a string to the HUD.
; This is called during the game loop after rendering entities, to ensure they
; do not fail to render if printing takes too long.
DrawPrintString::
	ld a, vTextbox_Width * 8
	lb bc, idof_vTextboxTiles, idof_vTextboxTiles + vTextbox_Width * vTextbox_Height
	lb de, vTextbox_Height, HIGH(vTextboxTiles) & $F0
	call TextInit

	xor a, a
	ld [wTextLetterDelay], a

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
	ld a, BANK(TextClear)
	rst SwapBank
	call TextClear
	call PrintVWFChar
	jp DrawVWFChars

SECTION "Draw Status bar", ROM0
; @clobbers bank
DrawStatusBar::
	ld hl, wEntity0
	call .prepareFormatting

	ld a, vStatusBar_Width * 8
	lb bc, idof_vPlayerStatus, idof_vPlayerStatus + vStatusBar_Width
	lb de, 1, HIGH(vPlayerStatus) & $F0
	call TextInit

	xor a, a
	ld [wTextLetterDelay], a

	ld a, 1
	ld b, BANK(xStatusString)
	ld hl, xStatusString
	call PrintVWFText

	lb de, vStatusBar_Width, 1
	ld hl, vStatusBar + 1
	call TextDefineBox
	ld a, BANK(TextClear)
	rst SwapBank
	call TextClear
	call PrintVWFChar
	call DrawVWFChars
.printPartner
	ld hl, wEntity1
	ld a, [hl]
	and a, a
	ret z
	call .prepareFormatting

	ld a, vStatusBar_Width * 8
	lb bc, idof_vPartnerStatus, idof_vPartnerStatus + vStatusBar_Width
	lb de, vStatusBar_Height, HIGH(vPartnerStatus) & $F0
	call TextInit

	xor a, a
	ld [wTextLetterDelay], a

	ld a, 1
	ld b, BANK(xStatusString)
	ld hl, xStatusString
	call PrintVWFText

	lb de, vStatusBar_Width, 1
	ld hl, vStatusBar + 33
	call TextDefineBox
	ld a, BANK(TextClear)
	rst SwapBank
	call TextClear
	call PrintVWFChar
	jp DrawVWFChars

.prepareFormatting
	ld de, wPrintStatus
	push hl
		ld a, [hli]
		ld [de], a
		inc de
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
		ld [de], a
		inc de
		ld a, [hli]
		ld [de], a
		inc de
	pop hl
	ld l, LOW(wEntity0_Level)
	ld a, [hli]
	push hl
		call GetMaxHealth
		ld a, l
		ld [de], a
		inc de
		ld a, h
		ld [de], a
		inc de
	pop hl
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	; If garbage is shown on the status bar after the partner dies, move this
	; check outside this function and clear the text tiles.
	bit 7, a
	jr z, :+
		xor a, a
		ld [de], a
		dec de
		ld [de], a
:
	ret

SECTION "Status String", ROMX
xStatusString:
	textcallptr wPrintStatus.name
	db ": "
	print_u16 wPrintStatus.health
	db "/"
	print_u16 wPrintStatus.maxHealth
	db " HP", 0

SECTION "Status Format", WRAM0
wPrintStatus:
.name ds 3
.maxHealth dw
.health dw

SECTION "Attack window", ROM0
UpdateAttackWindow::
	ldh a, [hCurrentBank]
	push af

	ld a, [wShowMoves]
	and a, a
	jp z, .close
.open
	ldh a, [hNewKeys]
	bit PADB_A, a
	jp z, .skipRedraw
		xor a, a
		ld [wWindowBounce], a
:           ldh a, [rSTAT]
			and a, STATF_BUSY
			jr nz, :-
		ld a, idof_vUIFrameLeftCorner ; 2
		ld [vAttackWindow], a ; 6
		ld a, idof_vUIFrameLeft ; 8
		ld [vAttackWindow + 32], a ; 12
		ld [vAttackWindow + 64], a ; 16
		lb bc, idof_vUIFrameTop, vAttackWindow_Width + 2
		ld hl, vAttackWindow + 1
		call VRAMSetSmall
		; We actually have ~7 cycles coming out of this function.
		ld a, idof_vUIFrameLeft ; 2
		ld [vAttackWindow + 128], a ; 6
:           ldh a, [rSTAT]
			and a, STATF_BUSY
			jr nz, :-
		ld a, idof_vUIArrowUp ; 2
		ld [vAttackWindow + 1 + 32], a ; 6
		inc a ; 7
		ld [vAttackWindow + 1 + 64], a ; 11
		inc a ; 12
		ld [vAttackWindow + 1 + 96], a ; 16
:           ldh a, [rSTAT]
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
		ld hl, wEntity0_Moves
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
		ASSERT Move_Name == 1
		inc hl
		ld a, [hli]
		ld h, [hl]
		ld l, a
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
		lb de, vAttackText_Height + 2, HIGH(vAttackTiles) & $F0
		call TextInit

		lb de, vAttackText_Width, vAttackText_Height
		ld hl, vAttackText
		call TextDefineBox
		call PrintVWFChar
		call DrawVWFChars
.skipRedraw
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
	jp BankReturn
.close
	ld a, SCRN_X
	ldh [hShadowWX], a
	ld a, SCRN_Y
	ldh [hShadowWY], a
	jp BankReturn
.bounceEffect
	dec a
	jr nz, .in
	ldh a, [hShadowWX]
	sub a, POPUP_SPEED / 2
	ldh [hShadowWX], a
	cp a, SCRN_X - vAttackWindow_Width * 8 - 12
	jp nz, BankReturn
	ld [wWindowBounce], a
	jp BankReturn
.in
	ldh a, [hShadowWX]
	add a, POPUP_SPEED / 4
	ldh [hShadowWX], a
	cp a, SCRN_X - vAttackWindow_Width * 8
	jp nz, BankReturn
	xor a, a
	ld [wWindowBounce], a
	jp BankReturn

SECTION "Show HP bar", ROM0
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
	ld a, LOW(ShowDungeonView)
	ld [wSTATTarget], a
	ld a, HIGH(ShowDungeonView)
	ld [wSTATTarget + 1], a
	ret

SECTION "Show dungeon", ROM0
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
	ld a, LOW(ShowTextBox)
	ld [wSTATTarget], a
	ld a, HIGH(ShowTextBox)
	ld [wSTATTarget + 1], a
	ret

SECTION "Show text box", ROM0
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
	ld a, LOW(ShowHPBar)
	ld [wSTATTarget], a
	ld a, HIGH(ShowHPBar)
	ld [wSTATTarget + 1], a
	ret

SECTION "Window effect bounce", WRAM0
wWindowBounce: db
wWindowSticky:: db

SECTION "Print string", WRAM0
wPrintString:: ds 3

SECTION "Move Window Buffer", WRAM0
wMoveWindowBuffer: ds 8 * 4
