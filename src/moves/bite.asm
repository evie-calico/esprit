INCLUDE "entity.inc"
INCLUDE "text.inc"

SECTION "Bite Move", ROMX
xBite::
	db MOVE_ACTION_ATTACK
	dw .name
	db 224
	db 1
	db 8
.name db "Bite<END>"
