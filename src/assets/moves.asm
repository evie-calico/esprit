INCLUDE "entity.inc"

MACRO attack
SECTION "\1 Move", ROMX
x\1::
	db MOVE_ACTION_ATTACK
	db \4
	db \3
	db \2
.name:: db "\1", 0
ENDM

	attack Nibble, 3, 1, 224
	attack Bite, 12, 1, 224
	attack Pounce, 8, 2, 224
	attack Scratch, 8, 1, -1
