IF !DEF(ENTITY_INC)
DEF ENTITY_INC EQU 1

INCLUDE "structs.inc"

DEF NB_ALLIES EQU 3
DEF NB_ENEMIES EQU 5
DEF NB_ENTITIES EQU 8

DEF ENTITY_MOVE_COUNT EQU 4
DEF ENTITY_MAXIMUM_LEVEL EQU 20

DEF SPRITE_DIRECTION_SIZE EQU 128 * 3
DEF ENTITY_FRAME_IDLE EQU 0
DEF ENTITY_FRAME_STEP EQU 1
DEF ENTITY_FRAME_ATTK EQU 2
DEF ENTITY_FRAME_HURT EQU 3
RSRESET
DEF ENTITY_FRAME_IDLE_OFFSET RB 128
DEF ENTITY_FRAME_STEP_OFFSET RB 128
DEF ENTITY_FRAME_ATTK_OFFSET RB 64
DEF ENTITY_FRAME_HURT_OFFSET RB 64

; Move actions. Must not exceed 128, as this is the limit for a jump table.
RSRESET
DEF MOVE_ACTION_ATTACK RB 1 ; A simple attack, dealing damage to an enemy in front of the user.
DEF MOVE_ACTION_HEAL RB 1 ; Heals an ally in front of the user
DEF MOVE_ACTION_POISON RB 1 ; Inflicts poison on an enemy in front of the user.
DEF MOVE_ACTION_COUNT RB 1

RSRESET
DEF STATUS_OK RB 1
DEF STATUS_POISON RB 1 ; Lose 1-4 health every 8 turns
DEF STATUS_COUNT RB 1

; Animation bytecode
RSRESET
DEF ENTITY_ANIMATION_WAIT RB 1
DEF ENTITY_ANIMATION_FRAME RB 1
DEF ENTITY_ANIMATION_HIDE RB 1
DEF ENTITY_ANIMATION_SHOW RB 1
DEF ENTITY_ANIMATION_FORWARD RB 1
DEF ENTITY_ANIMATION_BACKWARD RB 1
DEF ENTITY_ANIMATION_END RB 1

; This determines when the "Tired" status should appear.
DEF TIRED_THRESHOLD EQU 35

	; Constant data about an entity, such as graphics, moves, and stats.
	struct EntityData
		; All of these pointers are assumed to share a bank with this struct.
		; The entity's graphics are an array of 96 uncompressed tiles, split up
		; into 4 slices for each direction that the entity can face in. This
		; is enough room for two idle frames, two walking frames, as well as an
		; attack and hurt frame in each direction.
		; These limits are mostly hard-coded into the engine, but they could be
		; increased with a few changes. Updating SPRITE_DIRECTION_SIZE should
		; flag most of the changes need.
		words 1, Graphics
		; This palette is entirely owned by the entity, meaning 8 different
		; entities can be spawned at a time. Ironically, this actually means
		; that the CGB is limiting the number of entities; The DMG likely has
		; enough object VRAM for another 4.
		words 1, Palette
		; TODO: find out an appropriate limit for entity names, considering how
		; they appear in UI.
		words 1, Name
		; A list of levels and moves which are to be learned upon leveling up.
		; Terminated by a level of 0.
		words 1, MoveTable
	end_struct

	struct Entity
		; Far pointer to a EntityData struct in ROM. If Bank is 0, the entity
		; does not exist.
		bytes 1, Bank
		words 1, Data
		; The current position of the entity's sprite, in 12.4 fixed-point.
		words 1, SpriteY
		words 1, SpriteX
		; The entity's current position on a 16x16 tile grid. This is the high
		; byte of the sprite position, so can be used to re-anchor the entity.
		bytes 1, PosX
		bytes 1, PosY
		; The entity's current direction is used to determine the direction of
		; their attacks, and which part of their spritesheet should be used.
		bytes 1, Direction
		; The entities direction on the last frame is used to check if its
		; graphics should be updated. A graphics update can be forced by setting
		; this to an invalid value, usually -1 or $FF.
		bytes 1, LastDirection
		; Determines what the latter 8 tiles should be. These tiles are only
		; used if the frame is non-zero.
		bytes 1, Frame
		; The following pointers are used as scripts within scenes, and moves
		; within a dungeon.
		; Each of the entity's learned moves. If the bank is 0, the move does
		; not exist.
		alias Moves
		alias IdleScript ; Executed each frame when movement is not locked.
		bytes 3, Move0
		alias InteractionScript ; Executed when the player interacts with this entity.
		bytes 3, Move1
		bytes 3, Move2
		bytes 3, Move3
		; Stats are very basic. There is no attack or defense stat, only a
		; maximum health. This value is the same for all species, and is derived
		; From the level. The main difference between species lies in their
		; available movepool.
		bytes 1, Level
		; Health is a signed 16-bit integer. When it is below 1, the entity will
		; play the defeat animation upon the next damage check. After the
		; defeat animation finishes, the entity should be destroyed by the
		; callback. Damage checks should be scheduled to happen after damage has
		; been taken, using the damage animation's callback function.
		words 1, Health
		words 1, Experience
		; Maximum of 100, displayed as a percentage.
		; Each move has a fatigue cost to prevent rapidly using powerful moves.
		; Every couple of steps recovers 1% of fatigue.
		bytes 1, Fatigue
		; 0/OK == no effect
		bytes 1, StatusEffect
		; How many turns are left until the status is cured.
		bytes 1, StatusTurns
	end_struct

	struct Move
		; The behavior of this move.
		bytes 1, Action
		; The move succeeds if a randomly generated 8-bit integer is below this
		; value.
		bytes 1, Chance
		; Used to determine the reach of a move's effects.
		bytes 1, Range
		; The strength of the move's effect, usually damage. If 0, power is not
		; displayed.
		bytes 1, Power
		; The amount of fatigue used up by this attack. If 0, this attack is
		; always available; otherwise this amount of fatigue is required.
		bytes 1, Fatigue
		alias Name
	end_struct

	; Wait a number of frames before continuing the script.
	DEF ea_wait     EQUS "db ENTITY_ANIMATION_WAIT,"
	; Change the entity's frame.
	DEF ea_frame    EQUS "db ENTITY_ANIMATION_FRAME,"
	; Moves the entity's sprite to an unreachable position.
	DEF ea_hide     EQUS "db ENTITY_ANIMATION_HIDE"
	; Resets the position of the entity's sprite.
	DEF ea_show     EQUS "db ENTITY_ANIMATION_SHOW"
	; Move the entity forward by one pixel.
	DEF ea_forward  EQUS "db ENTITY_ANIMATION_FORWARD"
	; Move the entity backward by one pixel.
	DEF ea_backward EQUS "db ENTITY_ANIMATION_BACKWARD"
	; End the animation and jump to the callback function, before returning to
	; normal gameplay
	DEF ea_end      EQUS "db ENTITY_ANIMATION_END"

ENDC
