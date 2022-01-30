IF !DEF(DUNGEON_INC)
DEF DUNGEON_INC EQU 1

INCLUDE "enum.inc"

    start_enum TILE
        enum CLEAR
        enum WALL
    end_enum

ENDC
