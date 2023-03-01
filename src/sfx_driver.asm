include "hardware.inc"
include "regex.inc"

def PULSE1 equ %0001
def PULSE2 equ %0010
def WAVE   equ %0100
def NOISE  equ %1000

macro sound ; channels (bitmask), length, [next]
	db (\1), (\2)
	if _NARG == 3
		dw \3
	elif _NARG != 2
		warn "expected 2 or 3 args"
	else
		dw null
	endc
endm

macro reg ; reg = value
	if !strcmp("\1", "end")
		db 0
	else
		regex "([^ =]*) = (.*)", "\1", register, value
		db low(register), value
	endc
endm

section "play sound", rom0

TryPlaySound::
	ldh a, [hSound.frames]
	and a, a
	ret nz
PlaySound::
	ldh a, [hCurrentBank]
	push af
	ld a, bank("SFX")
	rst SwapBank

	ld a, [hli] ; Channels
	ldh [hSound.channelMask], a
	; Mute music
	ldh [hMutedChannels], a
	; length of effect
	ld a, [hli]
	ldh [hSound.frames], a
	; queue the next segment; null for end.
	ld a, [hli]
	ldh [hSound.nextSegment + 0], a
	ld a, [hli]
	ldh [hSound.nextSegment + 1], a
	; at this point, we're looking at a regdump of the sound channels.
.setRegs:
	ld a, [hli]
	and a, a
	jp z, BankReturn
	ld c, a
	ld a, [hli]
	ldh [c], a
	jr .setRegs

UpdateSound::
	; check if a sound is playing
	ldh a, [hSound.frames]
	and a, a
	ret z
	; then decrement it and wait for it to finish
	dec a
	ldh [hSound.frames], a
	ret nz ; the first time 0 is reached, mute channels and check for a new segment.
	; unmute channels (potentially temporary)
	xor a, a
	ldh [hMutedChannels], a
	; Now just start from the next segment!
	ldh a, [hSound.nextSegment + 0]
	ld l, a
	ldh a, [hSound.nextSegment + 1]
	or a, l
	ret z
	ldh a, [hSound.nextSegment + 1]
	ld h, a
	jp PlaySound

section fragment "SFX", romx
sfxNoiseTest::
sfxReadyAttack::
	;stub
	sound 0, 1
	reg end

sfxAttack::
	sound NOISE, 20
	reg rNR41 = $00
	reg rNR42 = $B2
	reg rNR43 = $60
	reg rNR44 = $80
	reg end

sfxHeal::
	sound PULSE1, 20
	reg rNR10 = $17
	reg rNR11 = $80
	reg rNR12 = $90
	reg rNR13 = $60
	reg rNR14 = $86
	reg end

sfxRevive::
for idx, 9
	sound PULSE1, 7, :+
	reg rNR10 = $6f
	reg rNR11 = $28
	reg rNR12 = $f0
	db low(rNR13), $d3 - (idx & 1) * $10
	reg rNR14 = $c7
	reg end
:
endr
	sound 0, 1
	reg end

sfxUiClick::
sfxUiAccept::
	sound PULSE1, 7
	reg rNR10 = $00
	reg rNR11 = $40
	reg rNR12 = $71
	reg rNR13 = $b3
	reg rNR14 = $c7
	reg end

sfxGenericVoice::
	sound PULSE1, 5
	reg rNR10 = $1f
	reg rNR11 = $32
	reg rNR12 = $f0
	reg rNR13 = $25
	reg rNR14 = $c6
	reg end

sfxLuvuiVoice::
	sound PULSE1, 5
	reg rNR10 = $0f
	reg rNR11 = $36
	reg rNR12 = $f0
	reg rNR13 = $30
	reg rNR14 = $c7
	reg end

sfxArisVoice::
	sound PULSE1, 5
	reg rNR10 = $17
	reg rNR11 = $72
	reg rNR12 = $f0
	reg rNR13 = $4e
	reg rNR14 = $c6
	reg end

sfxMomVoice::
	sound PULSE1, 6
	reg rNR10 = $7f
	reg rNR11 = $28
	reg rNR12 = $f1
	reg rNR13 = $6e
	reg rNR14 = $c6
	reg end

section "sound channels", hram
hSound::
.frames:: db
.channelMask:: db
.nextSegment:: dw
