if !def(ENTITY_INC)
def ENTITY_INC equ 1

include "structs.inc"

def NB_ALLIES equ 3
def NB_ENEMIES equ 5
def NB_ENTITIES equ 8

def ENTITY_MOVE_COUNT equ 4
def PLAYER_MAXIMUM_LEVEL equ 20
def PLAYER_MINIMUM_LEVEL equ 5
def ENTITY_MAX_FATIGUE equ 100
def ENTITY_ATTACK_BUFF_DECAY_SPEED equ 4

def SPRITE_DIRECTION_SIZE equ 128 * 3

	enum EntityFrame
		case Idle
		case Step
		case Attack
		case Hurt
		case Sleep
	end_enum

rsreset
def ENTITY_FRAME_IDLE_OFFSET rb 128
def ENTITY_FRAME_STEP_OFFSET rb 128
def ENTITY_FRAME_ATTACK_OFFSET rb 64
def ENTITY_FRAME_HURT_OFFSET rb 64

; Move actions. Must not exceed 128, as this is the limit for a jump table.
rsreset
	enum MoveAction
		case Attack ; A simple attack, dealing damage to an enemy in front of the user.
		case Heal ; Heals an ally in front of the user
		case Poison ; Inflicts poison on an enemy in front of the user.
		case PoisonAttack; Inflicts poison on and deals damage to an enemy in front of the user.
		case Fly ; Fly away from the battle and appear somewhere else.
		case TendWounds 
		case AttackBuff
		case Wish 
	end_enum

def MOVE_MAXIMUM_LENGTH equ 16

rsreset
def WISH_STATE_NONE rb
def WISH_STATE_RUBY rb
def WISH_STATE_SAPPHIRE rb
def WISH_STATE_EMERALD rb

; This determines when the "Tired" status should appear.
def TIRED_THRESHOLD equ 35

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
		; this to an invalid value, usually -1/$FF.
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
		; Fatigue is naturally restored as you walk around
		bytes 1, Fatigue
		; How many turns are left until poison is cured. 0 = No poison
		bytes 1, PoisonTurns
		; How many turns are left until the party is warped. 0 = no instability.
		bytes 1, BlinkTurns
		; If set, the next blink will take the party to the exit.
		bytes 1, IsBlinkPure
		; Heatstroke disables fatigue regen until cured.
		bytes 1, IsHeatstroked
		; If this is set, use the moving sprite for one more frame
		bytes 1, WasMovingLastFrame
		; Added to the frame counter so that animations aren't all synced up
		bytes 1, AnimationDesync
		bytes 1, CanRevive
		; if nonzero, the entity will not be rendered
		bytes 1, Hidden
		; Bonus damage applied to attacks. Decays over time
		bytes 1, AttackBuff
	end_struct

	; Any information about an entity that must persist.
	struct EntityBase
		bytes 1, Bank
		words 1, Data
		bytes 1, Level
		words 1, Experience
		bytes 1, CanRevive
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

	enum EntityAnimation
		case Wait
			bytes 1, Frames
		case Frame
			bytes 1, Frame
		case Hide
		case Show
		case Forward
		case Backward
		case End
	end_enum

	; Wait a number of frames before continuing the script.
	def ea_wait     equs "db EntityAnimation_Wait, "
	; Change the entity's frame.
	def ea_frame    equs "db EntityAnimation_Frame, "
	; Moves the entity's sprite to an unreachable position.
	def ea_hide     equs "db EntityAnimation_Hide"
	; Resets the position of the entity's sprite.
	def ea_show     equs "db EntityAnimation_Show"
	; Move the entity forward by one pixel.
	def ea_forward  equs "db EntityAnimation_Forward"
	; Move the entity backward by one pixel.
	def ea_backward equs "db EntityAnimation_Backward"
	; End the animation and jump to the callback function, before returning to
	; normal gameplay
	def ea_end      equs "db EntityAnimation_End"

endc
