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
