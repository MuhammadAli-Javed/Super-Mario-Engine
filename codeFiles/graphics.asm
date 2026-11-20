putPixel:
push bp
    mov bp, sp
    push ax
    push bx
    push dx
    push di
    push es
    mov bx, [bp+4]
    cmp bx, 0
    jl .end
    cmp bx, 320
    jge .end
    mov dx, [bp+6]
    cmp dx, 0
    jl .end
    cmp dx, 200
    jge .end
    mov di, dx
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1
    mov ax, dx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add di, ax
    add di, bx
    mov ax, [bufferSeg]
    mov es, ax
    mov ax, [bp+8]
    mov [es:di], al
    .end:
    pop es
    pop di
    pop dx
    pop bx
    pop ax
    pop bp
    ret

