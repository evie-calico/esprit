IF !DEF(DUNGEON_INC)
DEF DUNGEON_INC EQU 1

INCLUDE "enum.inc"
INCLUDE "structs.inc"

    start_enum TILE
        enum CLEAR
        enum WALL
    end_enum

    struct Dungeon
        words 1, Tileset
        words 1, Palette
    end_struct

ENDC
