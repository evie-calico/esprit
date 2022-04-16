IF !DEF(THEME_INC)
DEF THEME_INC EQU 1

INCLUDE "structs.inc"

	struct MenuTheme
		bytes 12, Palette
		words 1, Emblem
		; And a null-terminated string at the end.
	end_struct

ENDC
