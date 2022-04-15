INCLUDE "entity.inc"
INCLUDE "text.inc"

SECTION "Scratch Move", ROMX
xScratch::
	db MOVE_ACTION_ATTACK
	dw .name
	db -1
	db 1
	db 6
.name db "Scratch<END>"
