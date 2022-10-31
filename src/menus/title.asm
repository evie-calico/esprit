include "config.inc"
include "defines.inc"
include "draw_menu.inc"
include "hardware.inc"

section "Title screen", romx
xTitleScreen::
	db bank(@)
	dw xTitleScreenInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_START
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw null, null, null, null, null, null, null, null
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	db 0
	; Redraw
	dw xTitleScreenRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xTitleScreenClose

xTitleTiles:
	incbin "res/ui/title/title_screen.2bpp"
.end
xTitleMap:
	incbin "res/ui/title/title_screen.map"
xTitleAttrmap:
	incbin "res/ui/title/title_screen.pmap"
xTitlePalettes:
	incbin "res/ui/title/title_screen.pal8"

xTitleTilesDmg:
	incbin "res/ui/title/title_screen_dmg.2bpp"
.end
xTitleMapDmg:
	incbin "res/ui/title/title_screen_dmg.map"

xSleepingProtags:
	incbin "res/ui/title/luvui_sleeping.2bpp"
	incbin "res/ui/title/aris_sleeping.2bpp"
	incbin "res/ui/title/campfire.2bpp"
.end
xProtagPalettes:
	incbin "res/ui/title/luvui_sleeping.pal8", 3
	incbin "res/ui/title/aris_sleeping.pal8", 3
	incbin "res/ui/title/campfire.pal8", 3

xTitleScreenInit:
	xor a, a
	ld [wTextLetterDelay], a

	ld bc, xSleepingProtags.end - xSleepingProtags
	ld de, $8000
	ld hl, xSleepingProtags
	call VRAMCopy

	ldh a, [hSystem]
	and a, a
	jr z, .noCgb
		ld bc, 128 * 16
		ld de, $9000
		ld hl, xTitleTiles
		call VRAMCopy

		ld bc, 128 * 16
		ld de, $8800
		call VRAMCopy

		ld a, 1
		ldh [rVBK], a
			lb bc, SCRN_X_B, SCRN_Y_B
			ld de, $9800
			ld hl, xTitleAttrmap
			call MapRegion
		xor a, a
		ldh [rVBK], a

		ld c, 4 * 3 * 8
		ld de, wBGPaletteBuffer
		ld hl, xTitlePalettes
		rst MemCopySmall

		ld c, 3 * 3 * 8
		ld de, wOBJPaletteBuffer
		ld hl, xProtagPalettes
		rst MemCopySmall

		lb bc, SCRN_X_B, SCRN_Y_B
		ld de, $9800
		ld hl, xTitleMap
		call MapRegion
		jr .noDmg
.noCgb
		ld bc, 128 * 16
		ld de, $9000
		ld hl, xTitleTilesDmg
		call VRAMCopy

		ld bc, 128 * 16
		ld de, $8800
		call VRAMCopy

		lb bc, SCRN_X_B, SCRN_Y_B
		ld de, $9800
		ld hl, xTitleMapDmg
		call MapRegion
.noDmg

	ld a, $FF
	ld [wBGPaletteMask], a
	ld [wOBJPaletteMask], a

	ld a, BANK(xLakeMusic)
	ld de, xLakeMusic
	call StartSongTrampoline

	xor a, a
	ld [wFadeDelta], a ; Initialize this value to fade in from white
	jp FadeIn

PUSHS
SECTION "Start Song Trampoline", ROM0
StartSongTrampoline:
	call StartSong
	ld a, BANK(xTitleScreen)
	rst SwapBank
	ret
POPS

xTitleScreenRedraw:
	call Rand

	def LUVUI_POSITION EQUS "97, 86"
	def ARIS_POSITION EQUS "97, 59"
	def FIRE_POSITION EQUS "91, 72"

	lb bc, {LUVUI_POSITION}
	lb de, 0, 0
	call RenderSimpleSprite
	lb bc, {LUVUI_POSITION} + 8
	lb de, 2, 0
	call RenderSimpleSprite

	lb bc, {ARIS_POSITION}
	lb de, 4, 1
	call RenderSimpleSprite
	lb bc, {ARIS_POSITION} + 8
	lb de, 6, 1
	call RenderSimpleSprite

	lb bc, {FIRE_POSITION}
	ld e, 2
	ldh a, [hFrameCounter]
	rra
	rra
	and a, 3 << 2
	add a, 8
	ld d, a
	call RenderSimpleSprite
	lb bc, {FIRE_POSITION} + 8
	ld e, 2
	ldh a, [hFrameCounter]
	rra
	rra
	and a, 3 << 2
	add a, 10
	ld d, a
	jp RenderSimpleSprite

xTitleScreenClose:
	; Set palettes
	ld a, %11111111
	ld [wBGPaletteMask], a
	ld a, %11111111
	ld [wOBJPaletteMask], a
	call FadeToBlack

	; Game Setup
	ld hl, wActiveDungeon
	ld a, bank(FIRST_DUNGEON)
	ld [hli], a
	ld a, low(FIRST_DUNGEON)
	ld [hli], a
	ld a, high(FIRST_DUNGEON)
	ld [hli], a

	ld hl, wActiveMapNode
	ld a, bank(FIRST_NODE)
	ld [hli], a
	ld a, low(FIRST_NODE)
	ld [hli], a
	ld a, high(FIRST_NODE)
	ld [hli], a

	lb bc, bank(xLuvui), 5
	ld de, xLuvui
	ld h, high(wEntity0)
	call SpawnEntity

	lb bc, bank(xAris), 6
	ld de, xAris
	ld h, high(wEntity1)
	call SpawnEntity

	xor a, a
	ld hl, wInventory
	ld c, wInventory.end - wInventory
	call MemSetSmall

	ld hl, wFadeCallback
	ld a, low(InitDungeon)
	ld [hli], a
	ld [hl], high(InitDungeon)
	ret
