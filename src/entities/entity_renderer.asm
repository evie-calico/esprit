include "entity.inc"
include "hardware.inc"

section "Load Entity Graphics", rom0
; Flag an entity as needing an update and reload their palettes.
; @param h: high byte of entity pointer
; @clobbers bank
LoadEntityGraphics::
	; Forcefully load entity graphics.
	ld l, low(wEntity0_LastDirection)
	ld [hl], -1

	ldh a, [hSystem]
	and a, a
	ret z

	push hl

	ld a, h
	sub a, high(wEntity0)
	ld b, a
	ld l, low(wEntity0_Bank)

	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	assert EntityData_Palette == 2
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
	add a, low(wOBJPaletteBuffer)
	ld e, a
	adc a, high(wOBJPaletteBuffer)
	sub a, e
	ld d, a
	ld c, 9
	call MemCopySmall

	pop hl
	ret

section "Update entity graphics", rom0
; Check each entity to see if their graphics must be updated.
UpdateEntityGraphics::
	ld h, high(wEntity0)
.loop
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .next
	ld l, low(wEntity0_Direction)
	ld a, [hli]
	assert Entity_Direction + Entity_LastDirection
	cp a, [hl]
	jr z, .next
	ld [hl], a
	ld c, a
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	assert Entity_Bank + 1 == Entity_Data
	rst SwapBank
	push hl
		; Save the index in B for later
		ld a, h
		sub a, high(wEntity0)
		ld b, a
		; Dereference data and graphics.
		ld a, [hli]
		ld h, [hl]
		ld l, a
		assert EntityData_Graphics == 0
		ld a, [hli]
		ld h, [hl]
		ld l, a
		; Offset graphics by direction
		assert SPRITE_DIRECTION_SIZE == 384
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
		call VramCopySmall
	pop hl
.next
	inc h
	ld a, h
	cp a, high(wEntity0) + NB_ENTITIES
	jr nz, .loop
	ret

section "Render entities", romx
; Render each on-screen entity to OAM.
xRenderEntities::
	; Load OAM pointer.
	ld d, high(wShadowOAM)
	ldh a, [hOAMIndex]
	ld e, a
	; Initialize entity index.
	ld h, high(wEntity0)
.loop
	ld l, low(wEntity0_Bank)
	ld a, [hl]
	and a, a
	jp z, .next

	ld l, low(wEntity0_Hidden)
	ld a, [hl]
	and a, a
	jp nz, .next
	
	ld l, low(wEntity0_SpriteY + 1)
	; Now check if the entity is within the camera bounds
	ld a, [wDungeonCameraY + 1]
	cp a, [hl] ; possibly need to inc/dec here?
	jr z, :+
	jp nc, .next
:   add a, 9
	cp a, [hl]
	jp c, .next
	assert Entity_SpriteY + 3 == Entity_SpriteX + 1
	inc l
	inc l
	ld a, [wDungeonCameraX + 1]
	cp a, [hl] ; possibly need to inc/dec here?
	jr z, :+
	jp nc, .next
:   add a, 11
	cp a, [hl]
	jp c, .next
	assert Entity_SpriteX - 2 == Entity_SpriteY
	dec l
	dec l
	; Read Y position.
	ldh a, [hShadowSCY]
	ld c, a
	ld a, [hld]
	ld b, a
	ld a, [hli]
	; Adjust 12.4 position down to a 12-bit integer.
	rept 4
		srl b
		rra
	endr
	add a, 16
	sub a, c
	ldh [hRenderTempByte], a

	assert Entity_SpriteY + 2 == Entity_SpriteX
	inc l
	inc l
	; Read X position.
	ldh a, [hShadowSCX]
	ld c, a
	ld a, [hld]
	ld b, a
	ld a, [hli]
	; Adjust 12.4 position down to a 12-bit integer.
	rept 4
		srl b
		rra
	endr
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
	call xRenderEntity.customArgs
.next
	inc h
	ld a, h
	cp a, high(wEntity0) + NB_ENTITIES
	jp nz, .loop
	ret

; Similar to xRenderEntities, but for the scene state.
xRenderNPCs::
	ld h, high(wEntity0)
.loop
	ld l, low(wEntity0_Bank)
	ld a, [hl]
	and a, a
	jp z, .next

	; Check if the entity is within the camera bounds
	ld l, low(wEntity0_SpriteX) + 1
	ld a, [wSceneCamera.x + 1]
	cp a, [hl]
	jr z, :+
	jr nc, .next
:   add a, 11
	cp a, [hl]
	jr c, .next

	ld bc, wSceneCamera.x
	ld a, [bc]
	inc bc
	ld d, a
	ld a, [bc]
	inc bc
	rept 4
		rra
		rr d
	endr
	ld a, [bc]
	inc bc
	ld e, a
	ld a, [bc]
	inc bc
	rept 4
		rra
		rr e
	endr
	ld l, low(wEntity0_SpriteY)
	ld a, [hli]
	ld b, [hl]
	rept 4
		rr b
		rra
	endr
	add a, 16
	sub a, e
	ldh [hRenderTempByte], a
	inc l
	ld a, [hli]
	ld b, [hl]
	rept 4
		rr b
		rra
	endr
	add a, 8
	sub a, d
	ld b, a
	ldh a, [hOAMIndex]
	ld e, a
	ld d, high(wShadowOAM)
	call xRenderEntity.customArgs
.next
	inc h
	ld a, h
	cp a, high(wEntity0) + NB_ENTITIES
	jp nz, .loop
	ret

; @param h: Entity pointer high byte
xRenderEntity::
	ld l, low(wEntity0_SpriteY)
	ld a, [hli]
	ld b, [hl]
	rept 4
		rr b
		rra
	endr
	add a, 16
	ldh [hRenderTempByte], a
	inc l
	ld a, [hli]
	ld b, [hl]
	rept 4
		rr b
		rra
	endr
	add a, 8
	ld b, a
	ldh a, [hOAMIndex]
	ld e, a
	ld d, high(wShadowOAM)
; @param b: X
; @param de: OAM pointer
; @param h: Entity pointer high byte
; @param hRenderTempByte: Y
.customArgs::
	for I, 2
		; The following is an unrolled loop which writes both halves of the sprite.
		ldh a, [hRenderTempByte]
		ld [de], a
		inc e
		ld a, b
		if I
			add a, 8
		endc
		ld [de], a
		inc e
		; Determine entity index and render.
		ld a, h
		sub a, high(wEntity0)
		swap a ; a * 16
		ld c, a
		ld l, low(wEntity0_Frame)
		ld a, [hl]
		ld l, low(wEntity0_WasMovingLastFrame)
		cp a, ENTITY_FRAME_STEP
		jr nz, .notMoving\@
		ld [hl], 3
		jr .moving\@
.notMoving\@
		ld a, [hl]
		and a, a
		jr z, .moving\@
		dec [hl]
.moving\@

		ld l, low(wEntity0_Frame)
		ld a, [hl]
		cp a, ENTITY_FRAME_ATTK
		ld a, 0
		jr nc, :+
		ld l, low(wEntity0_AnimationDesync)
		ldh a, [hFrameCounter]
		add a, [hl]
		and a, %00010000
		rra
		rra
:
		if I
			add a, 2
		endc
		add a, c
		ld c, a
		ld l, low(wEntity0_Frame)
		ld a, [hl]
		ld l, low(wEntity0_WasMovingLastFrame)
		or a, [hl]
		and a, a
		jr z, :+
		ld a, 8
:       add a, c
		ld [de], a
		inc e
		; Use the index and use it as the color palette.
		ld a, h
		sub a, high(wEntity0)
		ld [de], a
		inc e
	endr
	; Store final OAM index.
	ld a, e
	ldh [hOAMIndex], a
	ret

section "Update animation", romx
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
	ld e, low(wEntity0_Frame)
	ld a, [hli]
	ld [de], a
	call UpdateAnimationFrame
	jr .readByte
.hide
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, low(wEntity0_Hidden)
	ld a, 1
	ld [de], a
	jr .readByte
.show
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, low(wEntity0_Hidden)
	xor a, a
	ld [de], a
	jr .readByte
.forward
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, low(wEntity0_Direction)
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
	ld e, low(wEntity0_Direction)
	ld a, [de]
	add a, 2
	and a, %11
	jr .backwardHook
.up
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, low(wEntity0_SpriteY)
.leftHook
	ld a, [de]
	ld c, a
	inc e
	ld a, [de]
	ld b, a

	ld a, c
	sub a, 1.0
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
	ld e, low(wEntity0_SpriteY)
.rightHook
	ld a, [de]
	ld c, a
	inc e
	ld a, [de]
	ld b, a

	ld a, c
	add a, 1.0
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
	ld e, low(wEntity0_SpriteX)
	jr .leftHook
.right
	ld a, [wEntityAnimation.target]
	ld d, a
	ld e, low(wEntity0_SpriteX)
	jr .rightHook

EntityAttackAnimation::
	ea_wait 8
	ea_backward
	ea_wait 3
	ea_forward
	ea_frame ENTITY_FRAME_HURT
	ea_wait 8
	ea_frame ENTITY_FRAME_ATTK
	ea_wait 8
	ea_frame ENTITY_FRAME_IDLE
	ea_end

EntityHurtAnimation::
	ea_frame ENTITY_FRAME_HURT
	; Get knocked back.
	rept 3
		ea_backward
		ea_wait 2
	endr
	; Then shake.
	rept 3
		ea_forward
		ea_wait 4
		ea_backward
		ea_wait 4
	endr
	rept 3
		ea_forward
		ea_wait 2
	endr
	ea_frame ENTITY_FRAME_IDLE
	ea_end

EntityDefeatAnimation::
	ea_frame ENTITY_FRAME_HURT
	rept 10
		ea_hide
		ea_wait 2
		ea_show
		ea_wait 2
	endr
	ea_end

EntityFlickerAnimation::
	ea_frame ENTITY_FRAME_IDLE
	rept 10
		ea_hide
		ea_wait 2
		ea_show
		ea_wait 2
	endr
	ea_end

EntityDelayAnimation::
	ea_wait 16
	ea_end

EntityFlyAnimation::
	ea_frame ENTITY_FRAME_IDLE
	rept 10
		ea_hide
		ea_wait 2
		ea_show
		ea_wait 2
	endr
	ea_frame ENTITY_FRAME_STEP
	rept 20
		rept 8
			ea_forward
		endr
		ea_wait 1
	endr
	ea_end

EntityMoveAndShakeAnimation::
	ea_frame ENTITY_FRAME_IDLE
	ea_forward
	ea_wait 2
	ea_forward
	ea_wait 2
	ea_forward
	ea_wait 2
	rept 3
		ea_forward
		ea_wait 20
		ea_backward
		ea_wait 20
	endr
	ea_backward
	ea_wait 2
	ea_backward
	ea_wait 2
	ea_backward
	ea_end

EntityShakeAnimation::
	ea_frame ENTITY_FRAME_IDLE
	rept 3
		ea_forward
		ea_wait 20
		ea_backward
		ea_wait 20
	endr
	ea_end

section "Entity animation graphics update", rom0
UpdateAnimationFrame::
	push hl
	ldh a, [hCurrentBank]
	push af

	; Dereference the entity's data
	; Save the entity's frame for later.
	ld e, low(wEntity0_Frame)
	ld a, [de]
	cp a, ENTITY_FRAME_STEP ; The idle and step frames should defer updates.
	jr nc, :+
	ld e, low(wEntity0_LastDirection)
	ld a, -1
	ld [de], a
	jr .exit
:   ldh [hRenderTempByte], a
	ld e, low(wEntity0_Bank)
	ld a, [de]
	rst SwapBank
	inc e
	ld a, [de]
	ld l, a
	inc e
	ld a, [de]
	ld h, a
	assert EntityData_Graphics == 0
	ld a, [hli]
	ld h, [hl]
	ld l, a
	; Determine index
	ld a, d
	sub a, high(wEntity0)
	ld b, a
	; Save the entity's direction for later.
	ld e, low(wEntity0_Direction)
	ld a, [de]
	ld c, a
	; Determine the source and destination address.
		; Offset graphics by direction
		assert SPRITE_DIRECTION_SIZE == 384
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
	cp a, ENTITY_FRAME_HURT
	jr z, .hurt
.sleep
	ld bc, 256 + 128
	add hl, bc
	jr .copy
.hurt
	ld bc, 256 + 64
	add hl, bc
	jr .copy
.attack
	inc h ; add hl, 256
.copy
	ld c, 64
	call VramCopySmall
.exit
	pop af
	rst SwapBank
	pop hl
	ret

section FRAGMENT "dungeon BSS", wram0
wEntityAnimation::
.pointer:: dw
.callback:: dw
.target:: db
.timer db

section "Render Temp", hram
hRenderTempByte:: db
