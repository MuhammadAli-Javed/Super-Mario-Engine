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
