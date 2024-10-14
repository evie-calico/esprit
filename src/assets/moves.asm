include "entity.inc"
include "regex.inc"

def percent equs "* $FF / 100"

macro move
section "\2 Move", romx
\2::
	db MoveAction_\1
	regex "([^%]+)(%?)", "\6", value, percent
	if strlen("{percent}")
		db value * 255 / 100
	else
		db value
	endc
	db \5
	db \4
	db \7

assert STRLEN(\3) <= MOVE_MAXIMUM_LENGTH
.name:: db \3, 0
endm

	;  | Type     | Identifier  | Name          | Power | Range | Chance | Cost
	; Luvui's moves
	move Attack,    xScratch,     "Scratch",         3,      1,    100%,     0, ; level 5
	move Attack,    xLunge,       "Lunge",          12,      2,    100%,    15, ; level 6
	move TendWounds,xTendWounds,  "Tend",           16,      1,    100%,    20, ; level 8
	move Attack,    xMagicMissile,"Magic Missile",  10,      5,     80%,    20, ; level 10
	; Aris's moves
	move Attack,    xBite,        "Bite",            6,      1,    100%,     0, ; level 5
	move AttackBuff,xHowl,        "Howl",           12,      1,    100%,    20, ; level 7
	; TODO: ATK_DEBUFF for Growl
	move AttackBuff,xGrowl,       "Growl",          12,      1,    100%,    20, ; level 8
	; Very little damage as tradeoff for  movement.
	move Attack,    xPounce,      "Pounce",          3,      2,     85%,    15, ; level 10
	; Enemy moves
	move Attack,    xNibble,      "Nibble",          3,      1,     90%,     0,
	move Attack,    xClawBite,    "Claw Bite",      12,      1,     50%,    15,
	move Heal,      xMoonlight,   "Moonlight",       8,      3,     50%,     0,
	move Poison,    xPoison,      "Poison",          0,      1,    100%,    20,
	move PoisonAttack,xPoisonFangs,"Poison Fangs",   8,      1,     50%,     0,
	move PoisonAttack,xPoisonBarbs,"Poison Barbs",   6,      1,    100%,     0,
	move PoisonAttack,xStingShot,  "Sting Shot",    12,      2,     20%,     0,
	move Fly,       xFly,         "Fly",             0,      3,    100%,     0,
