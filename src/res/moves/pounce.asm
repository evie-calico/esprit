INCLUDE "entity.inc"
INCLUDE "text.inc"

SECTION "Pounce Move", ROMX
xPounce::
	db MOVE_ACTION_ATTACK
	dw .name
	db 224
	db 2
	db 6
.name db "Pounce"
