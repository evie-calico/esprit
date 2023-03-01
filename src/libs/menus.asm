; ISSOtm's Menu System, adapted for use in the VuiBui engine.

include "hardware.inc"
include "menu.inc"

section "Menu system", rom0

; Adds a menu on top of the menu stack
; @param de A pointer to the menu's header in ROM
; @param b  The bank where the menu's header is located
; @destroy Loaded ROM bank
AddMenu::
	ld a, b
	rst SwapBank

	ld hl, wNbMenus
	ld a, [hl]
	inc a
	ld [hli], a
	; ld hl, wMenu0
	ld bc, sizeof_Menu
	dec a

	jr z, .skipMult
.mult
	add hl, bc
	dec a
	jr nz, .mult
.skipMult

	push hl

	ld c, Menu_ROMSize

	; Changed this to a standalone loop for now. My func is reversed.
.copy
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .copy

	xor a
	ld c, sizeof_Menu - Menu_ROMSize
	rst MemSetSmall

	pop hl
	ld a, [hli] ; Get bank
	rst SwapBank
	; Run init func
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	ret z
	jp hl


; Processes one frame of the menu stack (thus, the topmost)
ProcessMenus::
	; By default, no menu is closing
	xor a
	ld [wMenuClosingReason], a

	ld a, [wNbMenus]
	and a
	ret z

	ld hl, wMenu0
	ld bc, sizeof_Menu
	dec a

	jr z, .skipMult
.mult
	add hl, bc
	dec a
	jr nz, .mult
.skipMult

	ld a, [hli]
	rst SwapBank
	inc hl
	inc hl ; Skip init func

	; Get buttons
	ld a, [hli] ; Read button mask
	ld c, a
	ldh a, [hCurrentKeys]
	and c
	ld c, a ; Stash this, and DON'T modify it

	; Try to perform RepeatPress
	ld a, l ; Get ptr to RepeatPressCounter (will be used even if RepeatPress is disabled)
	add a, Menu_RepeatPressCounter - Menu_EnableRepeatPress
	ld e, a
	adc a, h
	sub e
	ld d, a
	ld b, 0 ; Start by supposing no button will be RepeatPress'd
	; If any (non-ignored) button is pressed, stop RepeatPress
	ldh a, [hNewKeys]
	and c ; It's fine to do this, since a pressed button is held anyways
	jr z, .dontResetRepeatPress
	xor a
	ld [de], a
.dontResetRepeatPress
	ld a, [hli] ; Read EnableRepeatPress
	and a
	jr z, .skipRepeatPress

	ld a, c ; Get held buttons
	and PADF_DOWN | PADF_UP | PADF_LEFT | PADF_RIGHT ; Get d-pad only
	; Check if exactly 1 direction is being held
	jr z, .skipRepeatPress ; If 0, don't do anything
.getFirstDirection
	add a, a
	jr nc, .getFirstDirection ; Keep going until the first bit is shifted out
	jr nz, .skipRepeatPress ; If more bits remain, more than 1 button is being held, so skip
	; So, only 1 direction is being held, and if it has just been pressed, the state is currently zero
	; Increment the counter
	ld a, [de]
	inc a
	ld [de], a
	cp 22
	jr c, .skipRepeatPress ; Unless the counter reaches 30, don't do anything
	ld a, 20
	ld [de], a ; Reset counter (to apply delay)
	ld a, c
	and PADF_DOWN | PADF_UP | PADF_LEFT | PADF_RIGHT
	ld b, a ; Mark this button as RepeatPress'd

.skipRepeatPress
	inc de ; Skip RepeatPressCounter
	; de = MiscState
	; hl = ButtonHooks
	ld a, l
	add a, 2 * 8 ; Get to the end of the ButtonHooks buffer
	ld l, a
	adc a, h
	sub a, l
	ld h, a

	; Save currently selected item
	inc hl ; Skip prev
	inc hl ; Skip flags
	ld a, [hld] ; Read cur
	dec hl ; Skip flags
	ld [hli], a ; Store cur into prev
	; hl = AllowWrapping

	; Check if a button has been pressed
	ldh a, [hNewKeys]
	and c ; Get only those that we are interested in
	jr nz, .buttonPressed
	; Check if a button is being RepeatPressed
	ld a, b
	and a
	jr z, .noButtonPressed
.buttonPressed
	push bc
	push de
	push hl
	ld b, 0
	; Look for the button we're gonna process
	; hl is 1 byte past the end of the buffer, so 2 decs will put it at the high byte of the last entry
.selectHook
	dec hl
	dec hl
	inc b
	add a, a
	jr nc, .selectHook
	; Load the default menu action
	ld a, b
	ld [wMenuAction], a
	ld a, [hld] ; Read high byte
	ld l, [hl]
	ld h, a
	or l
	jr z, .skipHook
	; The hook may choose to override the menu action, if it wishes to do so
	rst CallHL
.skipHook
	pop hl ; Get back ptr to AllowWrapping

	ld a, [wMenuAction]
	dec a
	cp MENU_ACTION_INVALID - 1
	jr nc, .menuActionNone
	; Perform the requested action
	push hl
	add a, a
	add a, low(.menuActions)
	ld e, a
	adc a, high(.menuActions)
	sub e
	ld d, a
	ld a, [de]
	ld b, a
	inc de
	ld a, [de]
	ld d, a
	ld e, b
	call CallDE
	pop hl
.menuActionNone
	pop de
	pop bc
.noButtonPressed

	inc hl ; Skip flags
	ld a, [hli] ; Get current item
	ld b, a
	inc hl ; Skip size
	; Run redraw func (if any)
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	or h
	jr z, .noRedraw
	rst CallHL
.noRedraw
	pop hl
	inc hl
	; Skip items ptr
	inc hl
	inc hl

	; Check if this menu should close
	ld a, [wMenuClosingReason]
	and a
	ret z ; jr z, .dontClose
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	jr z, .noCloseHook
	rst CallHL
.noCloseHook
	ld hl, wNbMenus
	dec [hl]
	ld a, [wMenuClosingReason]
	ld [wPreviousMenuClosingReason], a
.dontClose
	ret


.menuActions
	dw MenuMoveDown  ; DOWN
	dw MenuMoveUp    ; UP
	dw MenuDoNothing ; LEFT
	dw MenuDoNothing ; RIGHT
	dw MenuDoNothing ; START
	dw MenuDoNothing ; SELECT
	dw MenuCancel    ; B
	dw MenuValidate  ; A

	dw MenuAddNew


MenuMoveDown:
	ld a, [hli] ; Enable wrapping?
	ld e, a
	ld a, [hli] ; Current item
	inc a ; Move 1 down
	cp [hl] ; Compare to size
	jr c, .ok
	ld a, e
	rra ; Get bit 0 into carry
	ret nc ; If wrapping is disabled, do nothing
	xor a ; Wrap back to 0
.ok
	dec hl ; Get back to current item
	ld [hl], a ; Write back
	push hl
	ld hl, sfxUiClick
	call PlaySound
	pop hl
	ret

MenuMoveUp:
	ld a, [hli] ; Enable wrapping?
	ld e, a
	ld a, [hl] ; Current item
	and a ; Are we about to wrap?
	jr nz, .ok ; No, carry on
	ld a, e
	rra ; Get bit 0 into carry
	ret nc ; If wrapping is disabled, do nothing
	inc hl
	ld a, [hld]
.ok
	dec a
	ld [hl], a
	push hl
	ld hl, sfxUiClick
	call PlaySound
	pop hl
	ret

MenuValidate:
	inc hl
	ld a, [hl] ; Current item
	ld [wPreviousMenuItem], a
	ld a, MENU_VALIDATED
	jr :+
MenuCancel:
	ld a, MENU_CANCELLED
:
	ld [wMenuClosingReason], a

MenuDoNothing: ; Stub for menu actions that do nothing
	ret

; One of the menu actions
MenuAddNew:
	ld hl, wMenuAction+1
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld d, [hl]
	ld e, a
	ldh a, [hCurrentBank]
	push af
	call AddMenu
	pop af
	rst SwapBank
	ret


ForceMenuValidation::
	ld a, MENU_ACTION_VALIDATE
	ld [wMenuAction], a
	ret

PreventMenuAction::
	xor a
	ld [wMenuAction], a
	ret

; Jump back to the first menu in the menu stack and execute its closing function.
UnwindMenus::
	ld a, 1
	ld [wNbMenus], a
	ld a, [wMenu0_Bank]
	rst SwapBank
	ld hl, wMenu0_ClosingFunc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

section "Menu system vars", wram0

wNbMenus::
	db

	dstructs MENU_STACK_CAPACITY, Menu, wMenu

; What action to take after processing the menu
wMenuAction::
	db ; Action type
	ds 3 ; Action args
; The reason why this menu should be closed
wMenuClosingReason::
	db
; The reason why the last menu was closed
wPreviousMenuClosingReason::
	db
; The item selected on the last menu that was closed
; Updated when the menu is validated through the `VALIDATE` action
wPreviousMenuItem::
	db
