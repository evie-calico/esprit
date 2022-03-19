INCLUDE "entity.inc"
INCLUDE "res/charmap.inc"

SECTION "Luvui data", ROMX
xLuvui::
    dw .graphics
    dw .palette
    dw .name
.graphics INCBIN "res/sprites/luvui.2bpp"
.palette
    db $FF, $FF, $A0
    db $20, $90, $30
    db $00, $20, $00
.name db "Luvui<END>"

xDebugMove::
    db MOVE_ACTION_ATTACK
    dw .name
    db 128
    db 1
    db 10
.name db "Debug<END>"
