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
