; Moiz: enemy records and interactions
; Record: type, state, worldX(word), y(word), direction, timer, active, fraction

enemyOriginal:
    db E_GOOMBA, ES_WALK
    dw 160, 144
    db 0, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 192, 144
    db 1, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 512, 144
    db 0, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 688, 144
    db 0, 0, 0, 0
    db E_KOOPA, ES_WALK
    dw 456, 144
    db 0, 0, 0, 0
    db E_KOOPA, ES_WALK
    dw 752, 144
    db 0, 0, 0, 0
enemyList: times 6*EN_SIZE db 0

; Restore all enemies from their original records.
; Input none; output enemyList; preserves all registers.
resetEnemies:
    push cx
    push si
    push di
    push es
    push ds
    pop es
    mov si, enemyOriginal
    mov di, enemyList
    mov cx, 6*EN_SIZE
    cld
    rep movsb
    pop es
    pop di
    pop si
    pop cx
    ret
;Second movement part

; Moiz: enemy records and interactions
; Record: type, state, worldX(word), y(word), direction, timer, active, fraction

enemyOriginal:
    db E_GOOMBA, ES_WALK
    dw 160, 144
    db 0, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 192, 144
    db 1, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 512, 144
    db 0, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 688, 144
    db 0, 0, 0, 0
    db E_KOOPA, ES_WALK
    dw 456, 144
    db 0, 0, 0, 0
    db E_KOOPA, ES_WALK
    dw 752, 144
    db 0, 0, 0, 0
enemyList: times 6*EN_SIZE db 0

; Restore all enemies from their original records.
; Input none; output enemyList; preserves all registers.
resetEnemies:
    push cx
    push si
    push di
    push es
    push ds
    pop es
    mov si, enemyOriginal
    mov di, enemyList
    mov cx, 6*EN_SIZE
    cld
    rep movsb
    pop es
    pop di
    pop si
    pop cx
    ret

; Advance walking enemies and shells one timer frame.
; SI indexes the current record; BX/CX/DX are temporary. All preserved.
updateEnemies:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, enemyList
    mov cx, 6
.one:
    cmp byte [si+1], ES_DEAD
    je .next
    cmp byte [si+1], ES_FLAT
    jne .notFlat
    inc byte [si+7]
    cmp byte [si+7], 18
    jb .next
    mov byte [si+1], ES_DEAD
    jmp .next
.notFlat:
    mov ax, [si+2]
    add ax, 32
    cmp ax, [cameraX]
    jl .killOffscreen
    mov ax, [cameraX]
    add ax, 336
    cmp [si+2], ax
    jg .next
    mov byte [si+8], 1
    cmp byte [si+1], ES_SHELL
    je .next
    ; Walking at 0.5 / 0.75 pixels per frame, shell at 3.
    mov bl, 80h
    cmp byte [si], E_KOOPA
    jne .speedReady
    mov bl, 0C0h
.speedReady:
    cmp byte [si+1], ES_SLIDE
    jne .walking
    cmp byte [si+7], 0
    je .shellSpeed
    dec byte [si+7]
.shellSpeed:
    mov bl, 0
    cmp byte [si+6], 0
    je .slideLeft
    add word [si+2], 3
    jmp .worldCheck
.slideLeft:
    sub word [si+2], 3
    jmp .worldCheck
.walking:
    cmp byte [si+6], 0
    je .goLeft
    add [si+9], bl
    adc word [si+2], 0
    jmp .worldCheck
.goLeft:
    sub [si+9], bl
    sbb word [si+2], 0
.worldCheck:
    ; Reverse direction on a wall. Avoid leaving the level bounds.
    cmp word [si+2], 32
    jl .turn
    cmp word [si+2], 920
    jg .turn
    mov bx, [si+2]
    cmp byte [si+6], 0
    je .wallProbe
    add bx, 15
.wallProbe:
    mov dx, [si+4]
    add dx, 8
    push dx
    push bx
    call getTile
    add sp, 4
    cmp al, 1
    jb .support
    cmp al, 10
    jbe .turn
.support:
    ; Koopas turn at platform edges. Goombas walk off and fall.
    mov bx, [si+2]
    add bx, 8
    mov dx, [si+4]
    add dx, 17
    push dx
    push bx
    call getTile
    add sp, 4
    cmp al, 1
    jb .noGround
    cmp al, 10
    jbe .shellCollision
.noGround:
    cmp byte [si], E_KOOPA
    je .turn
    add word [si+4], 2
    cmp word [si+4], 192
    jge .killOffscreen
.shellCollision:
    cmp byte [si+1], ES_WALK
    jne .shellNext
    call bumpEnemies
.shellNext:
    cmp byte [si+1], ES_SLIDE
    jne .next
    call shellHitsEnemies
    jmp .next
.turn:
    xor byte [si+6], 1
    jmp .next
.killOffscreen:
    mov byte [si+1], ES_DEAD
.next:
    add si, EN_SIZE
    dec cx
    jnz .one
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

 ; NOTE: bump cooldown reuses timer byte on walking enemies.
; When walking enemies overlap, turn both (8-frame cooldown avoids jitter).
; SI=current enemy record. All registers preserved.
bumpEnemies:
    push ax
    push bx
    push cx
    push di
    cmp byte [si+7], 0
    je .scan
    dec byte [si+7]
    jmp .done
.scan:
    mov di, enemyList
    mov cx, 6
.check:
    cmp di, si
    je .next
    cmp byte [di+1], ES_WALK
    jne .next
    mov ax, [di+2]
    sub ax, [si+2]
    cmp ax, -14
    jl .next
    cmp ax, 14
    jg .next
    mov ax, [di+4]
    sub ax, [si+4]
    cmp ax, -14
    jl .next
    cmp ax, 14
    jg .next
    xor byte [si+6], 1
    xor byte [di+6], 1
    mov byte [si+7], 8
    mov byte [di+7], 8
    jmp .done
.next:
    add di, EN_SIZE
    dec cx
    jnz .check
.done:
    pop di
    pop cx
    pop bx
    pop ax
    ret

; SI points at a sliding shell. Remove intersected enemies and award +500.
; Returns nothing; preserves every register.
shellHitsEnemies:
    push ax
    push bx
    push cx
    push dx
    push di
    mov di, enemyList
    mov cx, 6
.test:
    cmp di, si
    je .next
    cmp byte [di+1], ES_DEAD
    je .next
    cmp byte [di+1], ES_FLAT
    je .next
    cmp byte [di+1], ES_SHELL
    je .next
    mov ax, [di+2]
    sub ax, [si+2]
    cmp ax, -14
    jl .next
    cmp ax, 14
    jg .next
    mov ax, [di+4]
    sub ax, [si+4]
    cmp ax, -14
    jl .next
    cmp ax, 14
    jg .next
    mov byte [di+1], ES_DEAD
    mov ax, 500
    push ax
    call addScore
    add sp, 2
.next:
    add di, EN_SIZE
    dec cx
    jnz .test
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Check hero against enemies. Stomps take priority over side damage.
; Called after player and enemy movement. Preserves registers.
checkEnemyCollisions:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, enemyList
    mov cx, 6
.one:
    cmp byte [si+1], ES_DEAD
    je .next
    cmp byte [si+1], ES_FLAT
    je .next
    mov ax, [marioX]
    add ax, 14
    cmp ax, [si+2]
    jle .next
    mov ax, [si+2]
    add ax, 16
    mov bx, [marioX]
    add bx, 2
    cmp ax, bx
    jle .next
    call marioHeight
    mov bx, [marioY]
    add bx, ax
    cmp bx, [si+4]
    jle .next
    mov ax, [si+4]
    add ax, 16
    cmp ax, [marioY]
    jle .next
    ; A stationary Koopa shell is always kicked, not damaging.
    cmp byte [si+1], ES_SHELL
    je .kick
    cmp word [marioVY], 0
    jle .side
    call marioHeight
    add ax, [oldMarioY]
    mov bx, [si+4]
    add bx, 8
    cmp ax, bx
    jle .stomp
.side:
    cmp byte [si+1], ES_SLIDE
    jne .possibleHurt
    cmp byte [si+7], 0
    jne .next
.possibleHurt:
    call hurtMario
    jmp .next
.stomp:
    cmp byte [si+1], ES_SLIDE
    jne .normalStomp
    mov byte [si+1], ES_SHELL
    jmp .bounce
.normalStomp:
    cmp byte [si], E_KOOPA
    jne .flat
    mov byte [si+1], ES_SHELL
    jmp .bounce
.flat:
    mov byte [si+1], ES_FLAT
    mov byte [si+7], 0
.bounce:
    call giveStompPoints
    call marioHeight
    mov bx, [si+4]
    sub bx, ax
    mov [marioY], bx
    mov byte [marioYFrac], 0
    mov word [marioVY], 0FD00h
    mov byte [onGround], 0
    jmp .next
.kick:
    mov byte [si+1], ES_SLIDE
    mov byte [si+7], 8
    mov byte [si+6], 1
    mov ax, [marioX]
    cmp ax, [si+2]
    jl .addKick
    mov byte [si+6], 0
.addKick:
    mov ax, 400
    push ax
    call addScore
    add sp, 2
.next:
    add si, EN_SIZE
    dec cx
    jnz .one
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Render the six records, if visible. Sprite assets provided by Abdul.
; Inputs: enemyList/cameraX, output framebuffer. Preserves registers.
drawEnemies:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, enemyList
    mov cx, 6
.one:
    cmp byte [si+1], ES_DEAD
    je .next
    mov ax, [si+2]
    sub ax, [cameraX]
    cmp ax, -16
    jle .next
    cmp ax, 320
    jge .next
    mov bx, sprGoomba
    cmp byte [si], E_KOOPA
    jne .checkFlat
    mov bx, sprKoopa
.checkFlat:
    cmp byte [si+1], ES_FLAT
    jne .checkShell
    mov bx, sprGoombaFlat
.checkShell:
    cmp byte [si+1], ES_SHELL
    je .useShell
    cmp byte [si+1], ES_SLIDE
    jne .render
.useShell:
    mov bx, sprShell
.render:
    mov ax, 0
    push ax
    push bx
    push word [si+4]
    push ax
    call drawSprite
    add sp, 8
.next:
    add si, EN_SIZE
    dec cx
    jnz .one
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
