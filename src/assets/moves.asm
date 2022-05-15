INCLUDE "entity.inc"

MACRO attack
SECTION "\1 Move", ROMX
x\1::
	db MOVE_ACTION_ATTACK
	dw .name
	db \4
	db \3
	db \2
.name db "\1", 0
ENDM

	attack Bite, 8, 1, 224
	attack Pounce, 6, 2, 224
	attack Scratch, 6, 1, -1
