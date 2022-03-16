IF !DEF(ENTITY_INC)
DEF ENTITY_INC EQU 1

INCLUDE "enum.inc"
INCLUDE "structs.inc"

DEF NB_ALLIES EQU 3
DEF NB_ENEMIES EQU 5
DEF NB_ENTITIES EQU 8

DEF ENTITY_FRAME_IDLE EQU 0
DEF ENTITY_FRAME_STEP EQU 1
DEF ENTITY_FRAME_ATTK EQU 2
DEF ENTITY_FRAME_HURT EQU 3

    ; Constant data about an entity, such as graphics, moves, and stats.
    struct EntityData
        words 1, Graphics
        words 1, Palette
        words 1, Name
    end_struct

    struct Entity
        ; Far pointer to a EntityData struct in ROM.
        bytes 1, Bank
        words 1, Data
        ; The current position of the entity's sprite, in 12.4 fixed-point.
        words 1, SpriteY
        words 1, SpriteX
        ; The entity's current position on a 16x16 tile grid.
        bytes 1, PosX
        bytes 1, PosY
        ; The entity's current and last direction, used to update graphics.
        bytes 1, Direction
        bytes 1, LastDirection
        ; Decides what the latter 8 tiles should be. These tiles are only used
        ; if the frame is non zero.
        bytes 1, Frame
        ; Each of the entity's learned moves. If the bank is 0, the move does
        ; not exist.
        bytes 3 * 4, Moves
    end_struct

    ; Must not exceed 128, as this is the limit for a jump table.
    start_enum MOVE_ACTION
        enum ATTACK
    end_enum

    struct Move
        bytes 1, Action ; The behavior of this move.
        words 1, Name
        bytes 1, Chance
        bytes 1, Range
        bytes 1, Power ; If 0, power is not displayed.
    end_struct

    start_enum ENTITY_ANIMATION
        enum WAIT
        enum FRAME
        enum HIDE
        enum SHOW
        enum FORWARD
        enum BACKWARD
        enum END
    end_enum

    MACRO ea_wait ; frames
        db ENTITY_ANIMATION_WAIT, \1
    ENDM

    MACRO ea_frame ; frame
        db ENTITY_ANIMATION_FRAME, \1
    ENDM

    DEF ea_hide     EQUS "db ENTITY_ANIMATION_HIDE"
    DEF ea_show     EQUS "db ENTITY_ANIMATION_SHOW"
    DEF ea_forward  EQUS "db ENTITY_ANIMATION_FORWARD"
    DEF ea_backward EQUS "db ENTITY_ANIMATION_BACKWARD"
    DEF ea_end      EQUS "db ENTITY_ANIMATION_END"

ENDC
