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
.row:
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
    add di, [bp-2]
    mov cx, [bp-4]
    sub cx, [bp-2]
    mov ax, [bp+12]
    cld
    rep stosb
    inc dx
    cmp dx, [bp-8]
    jl .row
.end:
    pop es
    pop di
    pop dx
    pop cx
    pop ax
    mov sp, bp
    pop bp
    ret

clearFrame:
    push ax
    push cx
    push di
    push es
    mov ax, [bufferSeg]
    mov es, ax
    xor di, di
    mov ax, 0909h
    mov cx, 32000
    cld
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    ret

showFrame:
    push ax
    push cx
    push si
    push di
    push ds
    push es
    mov ax, [bufferSeg]
    mov ds, ax
    mov ax, 0A000h
    mov es, ax
    xor si, si
    xor di, di
    mov cx, 32000
    cld
    rep movsw
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret

drawSprite:
    push bp
    mov bp, sp
    sub sp, 4            ; current row and column
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, [bp+8]
    mov word [bp-2], 0
.nextRow:
    mov ax, 16
    test word [bp+10], 2
    jz .heightSet
    mov ax, 32
.heightSet:
    cmp [bp-2], ax
    jge .done
    mov word [bp-4], 0
.nextCol:
    mov al, [si]
    inc si
    or al, al
    jz .skipPixel
    xor ah, ah
    push ax             ; colour
    mov bx, [bp+6]
    add bx, [bp-2]
    push bx             ; y
    mov bx, [bp-4]
    test word [bp+10], 1
    jz .notMirror
    mov cx, 15
    sub cx, bx
    mov bx, cx
.notMirror:
    add bx, [bp+4]
    push bx             ; x
    call putPixel
    add sp, 6
.skipPixel:
    inc word [bp-4]
    cmp word [bp-4], 16
    jl .nextCol
    inc word [bp-2]
    jmp .nextRow
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret
