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
DEF PULSE1 EQU 0
DEF PULSE2 EQU 1
DEF WAVE EQU 2
DEF NOISE EQU 3

; Segments
; Define the next byte as an envelope deep parameter.
DEF ENVF_DPAR EQU $20
; Define the next byte as am envelope pitch parameter.
DEF ENVF_PITCH EQU $10

; Pulse Channel:
DEF PULQ_DUTY8 EQU 0 << 6
DEF PULQ_DUTY4 EQU 1 << 6
DEF PULQ_DUTY2 EQU 2 << 6
DEF PUL_DECAY_DOWN EQU 0
DEF PUL_DECAY_UP EQU 1

; Wave Channel:
DEF WAVQ_VOLUME1 EQU 0 << 6
DEF WAVQ_VOLUME2 EQU 1 << 6
DEF WAVQ_VOLUME4 EQU 2 << 6
DEF WAVQ_VOLUME0 EQU 3 << 6

; Noise Channel
DEF NOIP_PER_NOISE EQU 0
DEF NOIP_PER_TONE EQU 1
MACRO sound
    db \3, \4
    dw \1
    DEF \2 RB 1
    EXPORT \2
ENDM

SECTION "Sound Effects", ROMX, ALIGN[4]

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
    DB $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

fx_roll:
    DB ENVF_DPAR|ENVF_PITCH|1, $10, $6E
    DB ENVF_PITCH|7, $64
    DB ENVF_PITCH|5, $57
    DB ENVF_PITCH|7, $64
    DB ENVF_PITCH|5, $57
fx_land2:
    DB ENVF_DPAR|ENVF_PITCH|5, $10, $6C
    DB ENVF_PITCH|2, $65
    DB ENVF_PITCH|1, $66
    DB ENVF_PITCH|1, $67
    DB $FF
fx_rolltojump:
    DB ENVF_DPAR|ENVF_PITCH|1, $10, $5E
    DB ENVF_PITCH|2, $54
    DB ENVF_DPAR|ENVF_PITCH|2, $50, $25
    DB $FF
fx_jump:
    DB ENVF_DPAR|ENVF_PITCH|$80, $59, 45
    DB ENVF_PITCH|$80, 47
    DB ENVF_PITCH|$80, 49
    DB ENVF_DPAR|ENVF_PITCH|$80, $81, 51
    DB ENVF_PITCH|$80, 53
    DB ENVF_PITCH|$80, 55
    DB ENVF_PITCH|$80, 56
    DB ENVF_PITCH|$80, 57
    DB $FF
fx_land:
    DB ENVF_DPAR|ENVF_PITCH|$80, $81, 16
    DB ENVF_PITCH|$80, 12
    DB ENVF_PITCH|$80, 9
    DB ENVF_PITCH|$80, 7
    DB ENVF_PITCH|$80, 5
    DB ENVF_PITCH|$81, 3
    DB ENVF_PITCH|$82, 2
    DB $FF
fx_fall:
    DB ENVF_DPAR|ENVF_PITCH|$81, $4A, 57
    DB ENVF_PITCH|$81, 56
    DB ENVF_PITCH|$81, 55
    DB ENVF_PITCH|$81, 54
    DB ENVF_DPAR|ENVF_PITCH|$81, $80, 53
    DB ENVF_PITCH|$81, 52
    DB ENVF_PITCH|$81, 51
    DB ENVF_PITCH|$81, 50
    DB ENVF_DPAR|ENVF_PITCH|$81, $72, 49
    DB ENVF_PITCH|$81, 48
    DB ENVF_PITCH|$81, 47
    DB ENVF_PITCH|$81, 46
    DB $FF
fx_point:
    DB ENVF_DPAR|ENVF_PITCH|$84, $C1, 48
    DB ENVF_DPAR|ENVF_PITCH|$88, $C1, 55
    DB $FF
fx_complete:
    DB ENVF_DPAR|ENVF_PITCH|$43, $C1, 36
    DB ENVF_DPAR|ENVF_PITCH|$43, $C1, 38
    DB ENVF_DPAR|ENVF_PITCH|$43, $C1, 40
    DB ENVF_DPAR|ENVF_PITCH|$43, $C1, 36
    DB ENVF_DPAR|ENVF_PITCH|$43, $D1, 40
    DB ENVF_DPAR|ENVF_PITCH|$43, $E1, 43
    DB ENVF_DPAR|ENVF_PITCH|$43, $F1, 48
    DB ENVF_PITCH|$41, 43
    DB ENVF_PITCH|$43, 48
    DB ENVF_PITCH|$41, 43
    DB ENVF_PITCH|$41, 48
    DB ENVF_PITCH|$41, 43
    DB ENVF_PITCH|$41, 48
    DB $FF
fx_launch:
    DB ENVF_DPAR|ENVF_PITCH|$80, $F1, 58
    DB ENVF_PITCH|$40, 28
    DB ENVF_PITCH|$8D, 26
    DB $FF
fx_achieve:
    DB ENVF_DPAR|ENVF_PITCH|$81, $C1, 37
    DB $42
    DB $81
    DB ENVF_DPAR|ENVF_PITCH|$43, $C1, 49
    DB $42
    DB $84
    DB $FF
fx_combostop:
    DB ENVF_DPAR|ENVF_PITCH|$42, $A1, 31
    DB ENVF_DPAR|ENVF_PITCH|$42, $A1, 36
    DB ENVF_DPAR|ENVF_PITCH|$41, $A1, 40
    DB $82
    DB ENVF_DPAR|ENVF_PITCH|$42, $A1, 31
    DB ENVF_DPAR|ENVF_PITCH|$42, $A1, 34
    DB ENVF_DPAR|ENVF_PITCH|$41, $A1, 38
    DB $86
    DB $FF
fx_lowcombo_bonk:
    DB ENVF_DPAR|ENVF_PITCH|2, $43, $5D
    DB ENVF_PITCH|2, $4D
    DB $FF
