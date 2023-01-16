; Build-time config options.

if def(DEV)
	def D_SA equs "DungeonComplete"
	def NO_QUICKLOAD = 1
endc

; The node the player will start in on the map screen.
if !def(FIRST_NODE)
	def FIRST_NODE equs "xVillageNode"
endc

; If enabled, causes SELECT to auto-complete the level, rather than skip a turn.
if !def(D_SA)
	def D_SA equs "EndTurn"
endc

if !def(NO_QUICKLOAD)
	def NO_QUICKLOAD = 0
endc
