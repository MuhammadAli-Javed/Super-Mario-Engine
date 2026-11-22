; world.asm - Ali
; tile map lookup and map reset

; getTile
;finds which tile is at a pixel position (x, y)
;inputs: x at [bp+4], y at [bp+6] (both pushed on the stack, y first, then x)
; output: AL = tile code (AH is cleared, so AX = tile code too)
;returns 1 (ground) for outside left/right or the HUD row
; returns 0 (sky) below the map, so mario falls into pits
; changes : AX and FLAGS only (everything else is saved and restored)
;tile index = row*60 + column

getTile:
    push bp
    mov bp, sp
    push bx ; save the registers we use
    push dx
    push di

    mov ax, [bp+4]; ax = x
    cmp ax, 0
    jl .solid ; x is left of the world, act like a wall
    cmp ax, 960 ; world is 60 tiles * 16 pixels = 960 wide
    jge .solid ; x is right of the world, wall too

    mov dx, [bp+6]  ; dx = y
    cmp dx, 16
    jl .solid ; row 0 is the HUD, treat it as a roof
    cmp dx, 192;  12 rows*16 = 192, below this is outside
    jge .sky ; nothing there, so mario can fall

    ; turn x into a column: x/16 (shift right 4 times)
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    mov bx, ax ; bx = column

    ; turn y into a row: y/16
    shr dx, 1
    shr dx, 1
    shr dx, 1
    shr dx, 1
    mov di, dx ; di = row

    ; row*60 = row*64 - row*4 (shifts are faster than mul)
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1 ; di = row*64
    shl dx, 1
    shl dx, 1; dx = row*4
    sub di, dx ; di = row*60
    add di, bx ; di = row*60 + column

    mov al, [gameMap+di] ; read the tile from the working map
    jmp .done

.solid:
    mov al, 1 ; ground tile code
    jmp .done

.sky:
    xor al, al ; 0 = sky

.done:
    xor ah, ah; clear AH so AX holds just the tile code
    pop di
    pop dx
    pop bx
    pop bp
    ret


; resetMap
;copies originalMap into gameMap (720 bytes) so the level goes back to how it started
; inputs: none (DS must point to our data segment)
; output: gameMap is a fresh copy of originalMap
;changes: FLAGS only (all registers are saved and restored)

resetMap:
    push ax
    push cx
    push si
    push di
    push es

    push ds
    pop es ; movsb writes to ES:DI, so make ES = DS

    mov si, originalMap   ; copy from here
    mov di, gameMap ; copy to here
    mov cx, MAP_SIZE ; 720 bytes
    cld ; make SI and DI go forward
    rep movsb ; copy CX bytes

    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret