INCLUDE "draw_menu.inc"

SECTION "Draw Pause Menu", ROMX
xSimpleFrame:
	INCBIN "res/ui/hud_frame.png"

xDrawPauseMenu::
	set_frame xSimpleFrame
	set_background idof_vFrameCenter
	menu_end
