INCLUDE "entity.inc"
INCLUDE "hardware.inc"

SECTION "Load Entity Graphics", ROM0
; Flag each entity as needing an update and reload their palettes.
; @param h: high byte of entity pointer
; @clobbers bank
LoadEntityGraphics::
	ld l, LOW(wEntity0_Bank)
	ld a, [hl]
	and a, a
	ret z
	; Forcefully load entity graphics.
	ld l, LOW(wEntity0_LastDirection)
	ld [hl], -1

	ldh a, [hSystem]
	and a, a
	ret z

	push hl

	ld a, h
	sub a, HIGH(wEntity0)
	ld b, a
	ld l, LOW(wEntity0_Bank)

	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ASSERT EntityData_Palette == 2
	inc hl
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld a, b
	; An entire palette is 9 bytes
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, b ; a * 9
	add a, LOW(wOBJPaletteBuffer)
	ld e, a
	adc a, HIGH(wOBJPaletteBuffer)
	sub a, e
	ld d, a
	ld c, 9
	call MemCopySmall

	pop hl
	ret

SECTION "Update entity graphics", ROM0
; Check each entity to see if their graphics must be updated.
UpdateEntityGraphics::
	ld h, HIGH(wEntity0)
.loop
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .next
	ld l, LOW(wEntity0_Direction)
	ld a, [hli]
	ASSERT Entity_Direction + Entity_LastDirection
	cp a, [hl]
	jr z, .next
	ld [hl], a
	ld c, a
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	ASSERT Entity_Bank + 1 == Entity_Data
	rst SwapBank
	push hl
		; Save the index in B for later
		ld a, h
		sub a, HIGH(wEntity0)
		ld b, a
		; Dereference data and graphics.
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ASSERT EntityData_Graphics == 0
		ld a, [hli]
		ld h, [hl]
		ld l, a
		; Offset graphics by direction
		ASSERT SPRITE_DIRECTION_SIZE == 384
		; Begin by adding (Direction * 256)
		ld a, h
		add a, c
		ld h, a
		; Add the remaining (Direction * 128)
		bit 0, c
		jr z, :+
		ld a, l
		add a, 128
		ld l, a
		adc a, h
		sub a, l
		ld h, a
:       bit 1, c
		jr z, :+
		inc h
:       ; Now offset the destination by Index * 128 and copy 256 bytes.
		ld a, b
		add a, $80
		ld d, a
		ld e, 0
		ld c, 0
		call VRAMCopySmall
	pop hl
.next
	inc h
	ld a, h
	cp a, HIGH(wEntity0) + NB_ENTITIES
	jr nz, .loop
	ret

SECTION "Render entities", ROMX
; Render each on-screen entity to OAM.
xRenderEntities::
	; Load OAM pointer.
	ld d, HIGH(wShadowOAM)
	ldh a, [hOAMIndex]
	ld e, a
	; Initialize entity index.
	ld h, HIGH(wEntity0)
.loop
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jp z, .next
	ASSERT Entity_Bank + 4 == Entity_SpriteY + 1
	inc l
	inc l
	inc l
	; Now check if the entity is within the camera bounds
	ld a, [wDungeonCameraY + 1]
	cp a, [hl] ; possibly need to inc/dec here?
	jr z, :+
	jp nc, .next
:   add a, 9
	cp a, [hl]
	jp c, .next
	ASSERT Entity_SpriteY + 3 == Entity_SpriteX + 1
	inc l
	inc l
	ld a, [wDungeonCameraX + 1]
	cp a, [hl] ; possibly need to inc/dec here?
	jr z, :+
	jp nc, .next
:   add a, 11
	cp a, [hl]
	jp c, .next
	ASSERT Entity_SpriteX - 2 == Entity_SpriteY
	dec l
	dec l
	; Read Y position.
	ldh a, [hShadowSCY]
	ld c, a
	ld a, [hld]
	ld b, a
	ld a, [hli]
	; Adjust 12.4 position down to a 12-bit integer.
	REPT 4
		srl b
		rra
	ENDR
	add a, 16
	sub a, c
	ldh [hRenderTempByte], a

	ASSERT Entity_SpriteY + 2 == Entity_SpriteX
	inc l
	inc l
	; Read X position.
	ldh a, [hShadowSCX]
	ld c, a
	ld a, [hld]
	ld b, a
	ld a, [hli]
	; Adjust 12.4 position down to a 12-bit integer.
	REPT 4
		srl b
		rra
	ENDR
	add a, 8
	sub a, c
	ld b, a

	ldh a, [rWX]
	sub a, 4
	cp a, b
	jr nc, :+
	ldh a, [hRenderTempByte]
	ld c, a
	ldh a, [rWY]
	cp a, c
	jr c, .next
:
	FOR I, 2
		; The following is an unrolled loop which writes both halves of the sprite.
		ldh a, [hRenderTempByte]
		ld [de], a
		inc e
		ld a, b
		IF I
			add a, 8
		ENDC
		ld [de], a
		inc e
		; Determine entity index and render.
		ld a, h
		sub a, HIGH(wEntity0)
		swap a ; a * 16
		ld c, a
		ld l, LOW(wEntity0_Frame)
		ld a, [hl]
		cp a, ENTITY_FRAME_ATTK
		ld a, 0
		jr nc, :+
		ldh a, [hFrameCounter]
		and a, %00010000
		rra
		rra
:
		IF I
			add a, 2
		ENDC
		add a, c
		ld c, a
		IF !I
			ld l, LOW(wEntity0_Frame)
		ENDC
		ld a, [hl]
		and a, a
		jr z, :+
		ld a, 8
:       add a, c
		ld [de], a
		inc e
		; Use the index and use it as the color palette.
		ld a, h
		sub a, HIGH(wEntity0)
		ld [de], a
		inc e
	ENDR
.next
	inc h
	ld a, h
	cp a, HIGH(wEntity0) + NB_ENTITIES
	jp nz, .loop
	; Store final OAM index.
	ld a, e
	ldh [hOAMIndex], a
	ret

SECTION "Update animation", ROMX
xUpdateAnimation::
	ld a, [wEntityAnimation.timer]
	and a, a
	jr z, :+
	dec a
	ld [wEntityAnimation.timer], a
	ret
:
	ld hl, wEntityAnimation.pointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
.readByte
	ld a, [hli]
	; execute bytecode
	and a, a
	jr z, .wait
	dec a
	jr z, .frame
	dec a
	jr z, .hide
	dec a
	jr z, .show
	dec a
	jr z, .forward
	dec a
	jr z, .backward
	; end
	ld hl, wEntityAnimation.pointer
	xor a, a
	ld [hli], a
	ld [hli], a
	ld a, [hli]
	or a, [hl]
	ret z
	; If the callback is not NULL, jump to it!
	dec hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.wait
	ld a, [hli]
	ld [wEntityAnimation.timer], a
	ld a, l
	ld [wEntityAnimation.pointer], a
	ld a, h
	ld [wEntityAnimation.pointer + 1], a
	ret
.frame
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_Frame)
	ld a, [hli]
	ld [de], a
	call UpdateAnimationFrame
	jr .readByte
.hide
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_SpriteY)
	ld a, $F0
	ld [de], a
	inc e
	ld [de], a
	inc e
	ld [de], a
	inc e
	ld [de], a
	inc e
	jr .readByte
.show
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_PosY)
	ld a, [de]
	ASSERT Entity_PosY - 1 == Entity_PosX
	dec e
	ld b, a
	ld a, [de]
	ASSERT Entity_PosX - 2 == Entity_SpriteX
	dec e
	ld [de], a
	dec e
	xor a, a
	ld [de], a
	ASSERT Entity_SpriteX - 2 == Entity_SpriteY
	dec e
	ld a, b
	ld [de], a
	dec e
	xor a, a
	ld [de], a
	jr .readByte
.forward
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_Direction)
	ld a, [de]
.backwardHook
	and a, a
	jr z, .up
	dec a
	jr z, .right
	dec a
	jr z, .down
	jr .left
.backward
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_Direction)
	ld a, [de]
	add a, 2
	and a, %11
	jr .backwardHook
.up
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_SpriteY)
.leftHook
	ld a, [de]
	ld c, a
	inc e
	ld a, [de]
	ld b, a

	ld a, c
	sub a, 1 << 4
	ld c, a
	jr nc, :+
	dec b
:
	ld a, b
	ld [de], a
	dec e
	ld a, c
	ld [de], a
	jp .readByte
.down
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_SpriteY)
.rightHook
	ld a, [de]
	ld c, a
	inc e
	ld a, [de]
	ld b, a

	ld a, c
	add a, 1 << 4
	ld c, a
	adc a, b
	sub a, c

	ld [de], a
	dec e
	ld a, c
	ld [de], a
	jp .readByte
.left
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_SpriteX)
	jr .leftHook
.right
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, LOW(wEntity0_SpriteX)
	jr .rightHook

EntityAttackAnimation::
	ea_wait 8
	ea_backward
	ea_wait 3
	ea_show
	ea_frame ENTITY_FRAME_HURT
	ea_wait 8
	ea_frame ENTITY_FRAME_ATTK
	ea_wait 8
	ea_frame ENTITY_FRAME_IDLE
	ea_end

EntityHurtAnimation::
	ea_frame ENTITY_FRAME_HURT
	; Get knocked back.
	REPT 3
		ea_backward
		ea_wait 2
	ENDR
	; Then shake.
	REPT 3
		ea_forward
		ea_wait 4
		ea_backward
		ea_wait 4
	ENDR
	ea_show
	ea_frame ENTITY_FRAME_IDLE
	ea_end

EntityDefeatAnimation::
	ea_frame ENTITY_FRAME_HURT
	REPT 10
		ea_hide
		ea_wait 2
		ea_show
		ea_backward
		ea_backward
		ea_wait 2
	ENDR
	ea_end

SECTION "Entity animation graphics update", ROM0
UpdateAnimationFrame:
	push hl

	; Dereference the entity's data
	; Save the entity's frame for later.
	ld e, LOW(wEntity0_Frame)
	ld a, [de]
	cp a, ENTITY_FRAME_STEP ; The idle and step frames should defer updates.
	jr nc, :+
	ld e, LOW(wEntity0_LastDirection)
	ld a, -1
	ld [de], a
	jr .exit
:   ldh [hRenderTempByte], a
	ld e, LOW(wEntity0_Bank)
	ld a, [de]
	rst SwapBank
	inc e
	ld a, [de]
	ld l, a
	inc e
	ld a, [de]
	ld h, a
	ASSERT EntityData_Graphics == 0
	ld a, [hli]
	ld h, [hl]
	ld l, a
	; Determine index
	ld a, d
	sub a, HIGH(wEntity0)
	ld b, a
	; Save the entity's direction for later.
	ld e, LOW(wEntity0_Direction)
	ld a, [de]
	ld c, a
	; Determine the source and destination address.
		; Offset graphics by direction
		ASSERT SPRITE_DIRECTION_SIZE == 384
		; Begin by adding (Direction * 256)
		ld a, h
		add a, c
		ld h, a
		; Add the remaining (Direction * 128)
		bit 0, c
		jr z, :+
		ld a, l
		add a, 128
		ld l, a
		adc a, h
		sub a, l
		ld h, a
:       bit 1, c
		jr z, :+
		inc h
:       ; Now offset the destination by Index * 128 and copy 256 bytes.
		ld a, b
		add a, $80
		ld d, a
		ld e, $80
	; Finally, determine what to copy using the frame.
	ld a, [hRenderTempByte]
	cp a, ENTITY_FRAME_ATTK
	jr z, .attack
.hurt
	ld bc, 256 + 64
	add hl, bc
	ld c, 64
	jr .copy
.attack
	inc h ; add hl, 256
	ld c, 64
.copy
	call VRAMCopySmall
.exit
	ld a, BANK(xUpdateAnimation)
	rst SwapBank
	pop hl
	ret

SECTION "Entity Animation", WRAM0
wEntityAnimation::
.pointer:: dw
.callback:: dw
.target:: db
.timer db

SECTION "Render Temp", HRAM
hRenderTempByte: db
