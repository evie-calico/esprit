INCLUDE "entity.inc"

SECTION "Inflict status", ROM0
; @param h: Entity index
; @param b: Status effect
InflictStatus::
	ld l, LOW(wEntity0_StatusEffect)
	ld [hl], b
	inc l
	ld [hl], 24
	ret
