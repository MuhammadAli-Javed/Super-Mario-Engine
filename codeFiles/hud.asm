;decimal number conversion, bitmap text and the HUD

hudScoreText  db 'SCORE',0
hudCoinText   db 'COINS',0
hudWorldText  db 'WORLD',0
hudTimeText   db 'TIME',0
hudLivesText  db 'LIVES',0
hudHealthText db 'HP',0
hudWorldNum   db '1-1',0

; drawNumber(x,y,loWord,hiWord,digits,colour)
; Converts unsigned 32-bit number by repeated division by 10.
; Pushes remainders then pops into numberText, then draws with drawText.
; Preserves all registers and returns nothing.

drawNumber:
    push bp
    mov bp, sp
    sub sp, 4       ; current number low and high words
    push ax
    push bx
    push cx
    push dx
    push di
    mov ax, [bp+8]
    mov [bp-2], ax
    mov ax, [bp+10]
    mov [bp-4], ax
    mov cx, [bp+12]
    mov bx, 10
.divide:
    mov ax, [bp-4]
    xor dx, dx
    div bx
    mov [bp-4], ax
    mov ax, [bp-2]
    div bx
    mov [bp-2], ax
    push dx
    loop .divide
    mov di, numberText
    mov cx, [bp+12]
.nextDigit:
    pop dx
    add dl, '0'
    mov [di], dl
    inc di
    loop .nextDigit
    mov byte [di], 0
    push word [bp+14]
    mov ax, numberText
    push ax
    push word [bp+6]
    push word [bp+4]
    call drawText
    add sp, 8
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

heartFull  db 036h,07Fh,07Fh,03Eh,01Ch,008h,000h
heartEmpty db 036h,049h,041h,022h,014h,008h,000h

; Draw a 7x7 heart bitmap. Stack x,y,filled(1 or 0).
; Inputs on stack, output framebuffer; preserves all registers.
drawHeart:
    push bp
    mov bp, sp
    sub sp, 4
    push ax
    push bx
    push cx
    push si
    mov si, heartEmpty
    cmp word [bp+8], 1
    jne .setRows
    mov si, heartFull
.setRows:
    mov word [bp-2], 0
.row:
    cmp word [bp-2], 7
    jge .done
    mov word [bp-4], 0
.col:
    mov bl, 40h
    mov cx, [bp-4]
    shr bl, cl
    mov al, [si]
    test al, bl
    jz .skip
    mov ax, 15
    cmp word [bp+8], 1
    jne .colour
    mov ax, 4
.colour:
    push ax
    mov ax, [bp+6]
    add ax, [bp-2]
    push ax
    mov ax, [bp+4]
    add ax, [bp-4]
    push ax
    call putPixel
    add sp, 6
.skip:
    inc word [bp-4]
    cmp word [bp-4], 7
    jl .col
    inc si
    inc word [bp-2]
    jmp .row
.done:
    pop si
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

; Draw score, coin total, world, clock, lives and two heart boxes.
; Inputs: current game variables. Returns framebuffer. Preserves all registers.
drawHUD:
    push ax
    push bx
    mov ax, 1
    push ax
    mov ax, 16
    push ax
    mov ax, 320
    push ax
    mov ax, 0
    push ax
    mov ax, 0
    push ax
    call fillRect
    add sp, 10

    mov ax, 15
    push ax
    mov ax, hudScoreText
    push ax
    mov ax, 4
    push ax
    mov ax, 2
    push ax
    call drawText
    add sp, 8
    mov ax, 14
    push ax
    mov ax, 6
    push ax
    push word [scoreHigh]
    push word [scoreLow]
    mov ax, 4
    push ax
    mov ax, 33
    push ax
    call drawNumber
    add sp, 12

    mov ax, 15
    push ax
    mov ax, hudCoinText
    push ax
    mov ax, 4
    push ax
    mov ax, 74
    push ax
    call drawText
    add sp, 8
    xor bx, bx
    mov bl, [coins]
    mov ax, 14
    push ax
    mov ax, 2
    push ax
    mov ax, 0
    push ax
    push bx
    mov ax, 4
    push ax
    mov ax, 105
    push ax
    call drawNumber
    add sp, 12

    mov ax, 15
    push ax
    mov ax, hudWorldText
    push ax
    mov ax, 4
    push ax
    mov ax, 119
    push ax
    call drawText
    add sp, 8
    mov ax, 14
    push ax
    mov ax, hudWorldNum
    push ax
    mov ax, 4
    push ax
    mov ax, 150
    push ax
    call drawText
    add sp, 8

    mov ax, 15
    push ax
    mov ax, hudTimeText
    push ax
    mov ax, 4
    push ax
    mov ax, 171
    push ax
    call drawText
    add sp, 8
    mov ax, 14
    push ax
    mov ax, 3
    push ax
    mov ax, 0
    push ax
    push word [levelTime]
    mov ax, 4
    push ax
    mov ax, 197
    push ax
    call drawNumber
    add sp, 12

    mov ax, 15
    push ax
    mov ax, hudLivesText
    push ax
    mov ax, 4
    push ax
    mov ax, 218
    push ax
    call drawText
    add sp, 8
    xor bx, bx
    mov bl, [lives]
    mov ax, 14
    push ax
    mov ax, 2
    push ax
    mov ax, 0
    push ax
    push bx
    mov ax, 4
    push ax
    mov ax, 249
    push ax
    call drawNumber
    add sp, 12

    mov ax, 15
    push ax
    mov ax, hudHealthText
    push ax
    mov ax, 4
    push ax
    mov ax, 268
    push ax
    call drawText
    add sp, 8
    ; Filled heart, followed by a filled or empty outline heart.
    mov ax, 1
    push ax
    mov ax, 3
    push ax
    mov ax, 293
    push ax
    call drawHeart
    add sp, 6
    xor ax, ax
    cmp byte [health], 2
    jne .emptyHeart
    mov ax, 1
.emptyHeart:
    push ax
    mov ax, 3
    push ax
    mov ax, 303
    push ax
    call drawHeart
    add sp, 6
    pop bx
    pop ax
    ret

; Draw the player pose; skip alternate frames while invulnerable.
; Uses camera-relative position. All registers preserved.

drawMario:
    push ax
    push bx
    push dx
    mov ax, [lastTick]
    and ax, 1
    cmp byte [invuln], 0
    je .sprite
    cmp ax, 0
    jne .done
.sprite:
    xor dx, dx
    xor ax, ax
    mov al, [marioFace]
    mov dx, ax
    mov bx, sprSmallStand
    cmp byte [marioPose], 0
    je .form
    mov bx, sprSmallRun
    cmp byte [marioPose], 1
    je .form
    mov bx, sprSmallJump
.form:
    cmp byte [health], 2
    jne .render
    or dx, 2
    mov bx, sprSuperStand
    cmp byte [marioPose], 0
    je .render
    mov bx, sprSuperRun
    cmp byte [marioPose], 1
    je .render
    mov bx, sprSuperJump
.render:
    mov ax, [marioX]
    sub ax, [cameraX]
    push dx
    push bx
    push word [marioY]
    push ax
    call drawSprite
    add sp, 8
.done:
    pop dx
    pop bx
    pop ax
    ret

