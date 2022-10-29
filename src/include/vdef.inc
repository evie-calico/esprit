;
; Static VRAM allocation macro pack for RGBDS
;
; Copyright 2022, Evie M.
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

	if !def(VDEF_INC)
def VDEF_INC equ 1

macro dtile_section ; address
	assert _NARG == 1, "Expected 1 argument."
	redef _dtile_section = \1
endm

macro dtile_align
	if _dtile_section & 1
		redef _dtile_section = \1 + 1
	endc
endm

; Define a tile in VRAM. Must provide a name for the tile, and optionally its
; size in tiles. This produces 2 constants, an address pointing to the beginning
; of the tile, and an idof_ constant to get the tile's ID
macro dtile ; Name, [Size in tiles]
	assert _NARG == 1 || _NARG == 2, "Expected 1 or 2 arguments!"
	assert def(_dtile_section), "Please set dtile_section."
	assert _dtile_section >= $8000 && _dtile_section < $9800, "Address {_dtile_section} is outside of VRAM tile range!"
	if _dtile_section >= $9000
		def idof_\1 equ (_dtile_section - $9000) / 16
	else
		def idof_\1 equ (_dtile_section - $8000) / 16
	endc
	if _NARG == 1
		def \1 equ _dtile_section
		def sizeof_\1 equ 16
		redef _dtile_section = _dtile_section + 16
	else
		def \1 equ _dtile_section
		def sizeof_\1 equ (\2) * 16
		redef _dtile_section = _dtile_section + (\2) * 16
	endc
endm

macro dtile_union ; Name
	assert _NARG == 1 || _NARG == 2, "Expected 1 argument!"
	assert def(_dtile_section), "Please set dtile_section."
	assert _dtile_section >= $8000 && _dtile_section < $9800, "Address {_dtile_section} is outside of VRAM tile range!"
	if _dtile_section >= $9000
		def idof_\1 equ (_dtile_section - $9000) / 16
	else
		def idof_\1 equ (_dtile_section - $8000) / 16
	endc
	def \1 equ _dtile_section
endm

macro dtile_anon ; [Size in tiles]
	assert _NARG == 1, "Expected 1 argument!"
	assert def(_dtile_section), "Please set dtile_section."
	assert _dtile_section >= $8000 && _dtile_section < $9800, "Address {_dtile_section} is outside of VRAM tile range!"
	redef _dtile_section = _dtile_section + (\1) * 16
endm

macro get_id ; dest
	if _dtile_section >= $9000
		def \1 equ (_dtile_section - $9000) / 16
	else
		def \1 equ (_dtile_section - $8000) / 16
	endc
endm

; Create a tile region in VRAM.
macro dregion ; Name, x, y, width, height, [address]
	if _NARG == 5
		def \1 equ $9800 + \2 + \3 * 32
	elif _NARG == 6
		def \1 equ \6 + \2 + \3 * 32
	else
		assert _NARG == 5 || _NARG == 6, "Expected 5 or 6 arguments!"
	endc
	def \1_X equ \2
	def \1_Y equ \3
	def \1_Width equ \4
	def \1_Height equ \5
endm

	endc
