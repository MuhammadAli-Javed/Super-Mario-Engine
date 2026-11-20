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

fillRect:
    push bp
    mov bp, sp
    sub sp, 8            ; local: left, right, top, bottom
    push ax
    push cx
    push dx
    push di
    push es
    mov ax, [bp+4]
    mov [bp-2], ax
    add ax, [bp+8]
    mov [bp-4], ax
    mov ax, [bp+6]
    mov [bp-6], ax
    add ax, [bp+10]
    mov [bp-8], ax
    cmp word [bp-2], 0
    jge .leftOk
    mov word [bp-2], 0
.leftOk:
    cmp word [bp-4], 320
    jle .rightOk
    mov word [bp-4], 320
.rightOk:
    cmp word [bp-6], 0
    jge .topOk
    mov word [bp-6], 0
.topOk:
    cmp word [bp-8], 200
    jle .bottomOk
    mov word [bp-8], 200
.bottomOk:
    mov ax, [bp-2]
    cmp ax, [bp-4]
    jge .end
    mov dx, [bp-6]
    cmp dx, [bp-8]
    jge .end
    mov ax, [bufferSeg]
    mov es, ax
