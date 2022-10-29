; 7654 3210  Segment header ($00-$EF)
; |||| ++++- segment duration (0: 1 frame; 15: 16 frames)
; |||+------ 1: pitch change follows
; ||+------- 1: deep parameter follows
; ++-------- quick parameter
;
; If deep parameter and pitch change are used together, deep parameter comes first.

; 7654 3210  Pulse/noise deep parameter: Envelope
; |||| ||||
; |||| |+++- Decay period (0: no decay; 1-7: frames per change)
; |||| +---- Decay direction (0: -1; 1: +1)
; ++++------ Starting volume (0: mute; 1-15: linear)
;
; For sound effects, pitch is an offset in semitones above the lowest supported pitch, which is low C (65.4 Hz).

;7654 3210  Noise pitch parameter
;|||| |+++- Period divider r (1, 2, 4, 6, 8, 10, 12, 14)
;|||| +---- Periodic flag (0: 32767 steps, more noise-like;
;||||       1: 127 steps; more tone-like)
;++++------ Period prescaler s

; Channels
def PULSE1 equ 0
def PULSE2 equ 1
def WAVE equ 2
def NOISE equ 3

; Segments
; Define the next byte as an envelope deep parameter.
def ENVF_DPAR equ $20
; Define the next byte as am envelope pitch parameter.
def ENVF_PITCH equ $10

; Pulse Channel:
def PULQ_DUTY8 equ 0 << 6
def PULQ_DUTY4 equ 1 << 6
def PULQ_DUTY2 equ 2 << 6
def PUL_DECAY_DOWN equ 0
def PUL_DECAY_UP equ 1

; Wave Channel:
def WAVQ_VOLUME1 equ 0 << 6
def WAVQ_VOLUME2 equ 1 << 6
def WAVQ_VOLUME4 equ 2 << 6
def WAVQ_VOLUME0 equ 3 << 6

; Noise Channel
def NOIP_PER_NOISE equ 0
def NOIP_PER_TONE equ 1
macro sound
    db \3, \4
    dw \1
    def \2 rb 1
    export \2
endm

section "Sound Effects", romx, ALIGN[4]

sfx_table::
  sound fx_roll,          SFX_ROLL,          NOISE,  0
  sound fx_jump,          SFX_JUMP,          PULSE1, 0
  sound fx_land,          SFX_LAND,          PULSE1, 0
  sound fx_fall,          SFX_FALL,          PULSE1, 0
  sound fx_rolltojump,    SFX_ROLLTOJUMP,    NOISE,  0
  sound fx_point,         SFX_POINT,         PULSE2, 0
  sound fx_complete,      SFX_COMPLETE,      PULSE2, 0
  sound fx_launch,        SFX_LAUNCH,        PULSE1, 0
  sound fx_land2,         SFX_LAND2,         NOISE,  0
  sound fx_achieve,       SFX_ACHIEVE,       PULSE2, 0
  sound fx_combostop,     SFX_COMBOSTOP,     PULSE2, 0
  sound fx_lowcombo_bonk, SFX_LOWCOMBO_BONK, NOISE,  0

wavebank::
    ; Toothy Wave
    db $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

fx_roll:
    db ENVF_DPAR|ENVF_PITCH|1, $10, $6E
    db ENVF_PITCH|7, $64
    db ENVF_PITCH|5, $57
    db ENVF_PITCH|7, $64
    db ENVF_PITCH|5, $57
fx_land2:
    db ENVF_DPAR|ENVF_PITCH|5, $10, $6C
    db ENVF_PITCH|2, $65
    db ENVF_PITCH|1, $66
    db ENVF_PITCH|1, $67
    db $FF
fx_rolltojump:
    db ENVF_DPAR|ENVF_PITCH|1, $10, $5E
    db ENVF_PITCH|2, $54
    db ENVF_DPAR|ENVF_PITCH|2, $50, $25
    db $FF
fx_jump:
    db ENVF_DPAR|ENVF_PITCH|$80, $59, 45
    db ENVF_PITCH|$80, 47
    db ENVF_PITCH|$80, 49
    db ENVF_DPAR|ENVF_PITCH|$80, $81, 51
    db ENVF_PITCH|$80, 53
    db ENVF_PITCH|$80, 55
    db ENVF_PITCH|$80, 56
    db ENVF_PITCH|$80, 57
    db $FF
fx_land:
    db ENVF_DPAR|ENVF_PITCH|$80, $81, 16
    db ENVF_PITCH|$80, 12
    db ENVF_PITCH|$80, 9
    db ENVF_PITCH|$80, 7
    db ENVF_PITCH|$80, 5
    db ENVF_PITCH|$81, 3
    db ENVF_PITCH|$82, 2
    db $FF
fx_fall:
    db ENVF_DPAR|ENVF_PITCH|$81, $4A, 57
    db ENVF_PITCH|$81, 56
    db ENVF_PITCH|$81, 55
    db ENVF_PITCH|$81, 54
    db ENVF_DPAR|ENVF_PITCH|$81, $80, 53
    db ENVF_PITCH|$81, 52
    db ENVF_PITCH|$81, 51
    db ENVF_PITCH|$81, 50
    db ENVF_DPAR|ENVF_PITCH|$81, $72, 49
    db ENVF_PITCH|$81, 48
    db ENVF_PITCH|$81, 47
    db ENVF_PITCH|$81, 46
    db $FF
fx_point:
    db ENVF_DPAR|ENVF_PITCH|$84, $C1, 48
    db ENVF_DPAR|ENVF_PITCH|$88, $C1, 55
    db $FF
fx_complete:
    db ENVF_DPAR|ENVF_PITCH|$43, $C1, 36
    db ENVF_DPAR|ENVF_PITCH|$43, $C1, 38
    db ENVF_DPAR|ENVF_PITCH|$43, $C1, 40
    db ENVF_DPAR|ENVF_PITCH|$43, $C1, 36
    db ENVF_DPAR|ENVF_PITCH|$43, $D1, 40
    db ENVF_DPAR|ENVF_PITCH|$43, $E1, 43
    db ENVF_DPAR|ENVF_PITCH|$43, $F1, 48
    db ENVF_PITCH|$41, 43
    db ENVF_PITCH|$43, 48
    db ENVF_PITCH|$41, 43
    db ENVF_PITCH|$41, 48
    db ENVF_PITCH|$41, 43
    db ENVF_PITCH|$41, 48
    db $FF
fx_launch:
    db ENVF_DPAR|ENVF_PITCH|$80, $F1, 58
    db ENVF_PITCH|$40, 28
    db ENVF_PITCH|$8D, 26
    db $FF
fx_achieve:
    db ENVF_DPAR|ENVF_PITCH|$81, $C1, 37
    db $42
    db $81
    db ENVF_DPAR|ENVF_PITCH|$43, $C1, 49
    db $42
    db $84
    db $FF
fx_combostop:
    db ENVF_DPAR|ENVF_PITCH|$42, $A1, 31
    db ENVF_DPAR|ENVF_PITCH|$42, $A1, 36
    db ENVF_DPAR|ENVF_PITCH|$41, $A1, 40
    db $82
    db ENVF_DPAR|ENVF_PITCH|$42, $A1, 31
    db ENVF_DPAR|ENVF_PITCH|$42, $A1, 34
    db ENVF_DPAR|ENVF_PITCH|$41, $A1, 38
    db $86
    db $FF
fx_lowcombo_bonk:
    db ENVF_DPAR|ENVF_PITCH|2, $43, $5D
    db ENVF_PITCH|2, $4D
    db $FF
