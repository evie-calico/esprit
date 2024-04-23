; Build-time config options.

; VILLAGE_OVERRIDE: make the village a cutscene instead of a trader.

if def(DEV)
	redef D_SA equs "DungeonComplete"
	redef NO_QUICKLOAD = 1
	redef INIT_LEVEL = 19
endc

; The node the player will start in on the map screen.
if !def(FIRST_NODE)
	def FIRST_NODE equs "xVillageNode"
endc

; If enabled, causes SELECT to auto-complete the level, rather than skip a turn.
if !def(D_SA)
	def D_SA equs "EndTurn"
endc

if !def(INIT_LEVEL)
	def INIT_LEVEL = 5
endc

if !def(INIT_INVENTORY)
	def INIT_INVENTORY equs "null"
endc

if !def(NO_QUICKLOAD)
	def NO_QUICKLOAD = 0
endc

if !def(REPEAT_A)
	def REPEAT_A = 0
endc

if !def(FLAGS_SET)
	if !def(SET_ALL_FLAGS)
		def FLAGS_SET = 0
	else
		def FLAGS_SET = 256
	endc
endc

for i, 256 / 8
	if FLAGS_SET < 8
		def byte = 0
		for j, FLAGS_SET
			def byte <<= 1
			def byte |= 1
		endr
	else
		def byte = $FF
	endc
	def FLAG_VALUE_{d:i} equ byte
	; This extra step is to convert FLAGS_SET from equs to equ
	def temp = FLAGS_SET - 8
	if temp < 0
		def temp = 0
	endc
	purge FLAGS_SET
	redef FLAGS_SET equ temp
	purge byte, temp
endr
