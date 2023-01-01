; Build-time config options.

; Define some common presets
if def(DEV)
	def DEBUG_SELECT equ 1
	def SKIP_TITLE equ 1
endc

; The node the player will start in on the map screen.
if !def(FIRST_NODE)
	def FIRST_NODE equs "xVillageNode"
endc

; If enabled, causes SELECT to auto-complete the level, rather than skip a turn.
if !def(DEBUG_SELECT)
	def DEBUG_SELECT equ 0
endc

if !def(SKIP_TITLE)
	def SKIP_TITLE equ 0
endc
