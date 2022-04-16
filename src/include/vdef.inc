;
; Static VRAM allocation macro pack for RGBDS
;
; Copyright 2021, Eievui
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

	IF !DEF(VDEF_INC)
DEF VDEF_INC EQU 1

MACRO dtile_section ; address
	ASSERT _NARG == 1, "Expected 1 argument."
	REDEF _dtile_section = \1
ENDM

MACRO dtile_align
	IF _dtile_section & 1
		REDEF _dtile_section = \1 + 1
	ENDC
ENDM

; Define a tile in VRAM. Must provide a name for the tile, and optionally its
; size in tiles. This produces 2 constants, an address pointing to the beginning
; of the tile, and an idof_ constant to get the tile's ID
MACRO dtile ; Name, [Size in tiles]
	ASSERT _NARG == 1 || _NARG == 2, "Expected 1 or 2 arguments!"
	ASSERT DEF(_dtile_section), "Please set dtile_section."
	ASSERT _dtile_section >= $8000 && _dtile_section < $9800, "Address {_dtile_section} is outside of VRAM tile range!"
	IF _dtile_section >= $9000
		DEF idof_\1 EQU (_dtile_section - $9000) / 16
	ELSE
		DEF idof_\1 EQU (_dtile_section - $8000) / 16
	ENDC
	IF _NARG == 1
		DEF \1 EQU _dtile_section
		REDEF _dtile_section = _dtile_section + 16
	ELSE
		DEF \1 EQU _dtile_section
		REDEF _dtile_section = _dtile_section + (\2) * 16
	ENDC
ENDM

MACRO dtile_union ; Name
	ASSERT _NARG == 1 || _NARG == 2, "Expected 1 argument!"
	ASSERT DEF(_dtile_section), "Please set dtile_section."
	ASSERT _dtile_section >= $8000 && _dtile_section < $9800, "Address {_dtile_section} is outside of VRAM tile range!"
	IF _dtile_section >= $9000
		DEF idof_\1 EQU (_dtile_section - $9000) / 16
	ELSE
		DEF idof_\1 EQU (_dtile_section - $8000) / 16
	ENDC
	DEF \1 EQU _dtile_section
ENDM

MACRO dtile_anon ; [Size in tiles]
	ASSERT _NARG == 1, "Expected 1 argument!"
	ASSERT DEF(_dtile_section), "Please set dtile_section."
	ASSERT _dtile_section >= $8000 && _dtile_section < $9800, "Address {_dtile_section} is outside of VRAM tile range!"
	REDEF _dtile_section = _dtile_section + (\1) * 16
ENDM

MACRO get_id ; dest
	IF _dtile_section >= $9000
		DEF \1 EQU (_dtile_section - $9000) / 16
	ELSE
		DEF \1 EQU (_dtile_section - $8000) / 16
	ENDC
ENDM

; Create a tile region in VRAM.
MACRO dregion ; Name, x, y, width, height, [address]
	IF _NARG == 5
		DEF \1 EQU $9800 + \2 + \3 * 32
	ELIF _NARG == 6
		DEF \1 EQU \6 + \2 + \3 * 32
	ELSE
		ASSERT _NARG == 5 || _NARG == 6, "Expected 5 or 6 arguments!"
	ENDC
	DEF \1_Width EQU \4
	DEF \1_Height EQU \5
ENDM

	ENDC
