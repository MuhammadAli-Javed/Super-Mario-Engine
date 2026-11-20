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


    .end:
    pop es
    pop di
    pop dx
    pop bx
    pop ax
    pop bp
    ret

