; world.asm - Ali
; tile map lookup, map reset, camera and drawing the map


; getTile
; purpose: finds which tile is at a pixel position (x, y)
; inputs: x at [bp+4], y at [bp+6] (both pushed on the stack, y first, then x)
; output: AL = tile code (AH is cleared, so AX = tile code too)
; returns 1 (ground) for outside left/right or the HUD row
; returns 0 (sky) below the map, so mario falls into pits
; changes: AX and FLAGS only (everything else is saved and restored)
; tile index = row*60 + column

getTile:
    push bp
    mov bp, sp
    push bx ; save the registers we use
    push dx
    push di

    mov ax, [bp+4] ; ax = x
    cmp ax, 0
    jl .solid ; x is left of the world, act like a wall
    cmp ax, 960  ; world is 60 tiles * 16 pixels = 960 wide
    jge .solid ; x is right of the world, wall too

    mov dx, [bp+6] ; dx = y
    cmp dx, 16
    jl .solid ; row 0 is the HUD, treat it as a roof
    cmp dx, 192; 12 rows * 16 = 192, below this is outside
    jge .sky  ; nothing there, so mario can fall

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
    shl di, 1; di = row*64
    shl dx, 1
    shl dx, 1 ; dx = row*4
    sub di, dx  ; di = row*60
    add di, bx ; di = row*60 + column

    mov al, [gameMap+di] ; read the tile from the working map
    jmp .done

.solid:
    mov al, 1 ; ground tile code
    jmp .done

.sky:
    xor al, al ; 0 = sky

.done:
    xor ah, ah ; clear AH so AX holds just the tile code
    pop di
    pop dx
    pop bx
    pop bp
    ret


; resetMap
; purpose: copies originalMap into gameMap (720 bytes) so the level goes back to how it started
; inputs: none (DS must point to our data segment)
; output: gameMap is a fresh copy of originalMap
; changes: FLAGS only (all registers are saved and restored)

resetMap:
    push ax
    push cx
    push si
    push di
    push es

    push ds
    pop es ; movsb writes to ES:DI, so make ES = DS

    mov si, originalMap ; copy from here
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


; updateCamera
; purpose: moves the camera to follow mario once he passes the middle of the screen
;the camera never goes back left, and it stops at the end of the level
; inputs: marioX (world pixels), cameraX
; output: cameraX (0 to 640), and marioX is pushed right if he is left of the camera
; changes: FLAGS only (AX is saved and restored)
; 160 = half of the 320 pixel screen, 640 = 960 world width - 320 screen width

updateCamera:
    push ax

    mov ax, [marioX]
    sub ax, 160 ; how far mario is past the screen middle
    js .wallCheck ; negative, so mario is before the middle, camera stays
    cmp ax, 640
    jle .notAtEnd
    mov ax, 640 ; do not go past the end of the level
.notAtEnd:
    cmp ax, [cameraX]
    jle .wallCheck ; new camera is not further right, so keep the old one
    mov [cameraX], ax ; camera only moves right

.wallCheck:
    mov ax, [marioX]
    cmp ax, [cameraX]
    jge .end ; mario is on screen, nothing to fix
    mov ax, [cameraX]
    mov [marioX], ax ; mario cannot walk off the left side of the screen
    mov byte [marioXFrac], 0 ; clear the fraction part of the position
    mov word [marioVX], 0; and stop his sideways speed

.end:
    pop ax
    ret


; drawTile
; purpose: draws one 16x16 tile as simple coloured shapes (easy to change later)
; inputs: x at [bp+4], y at [bp+6], tile code at [bp+8] (pushed tile, y, x)
;         x and y are screen pixels, not world pixels
; output: the tile is drawn into the frame buffer
; changes: nothing (all registers are saved and restored)
; uses fillRect, drawText and drawSprite from the graphics module
; fillRect stack order: colour, height, width, y, x

drawTile:
    push bp
    mov bp, sp
    push ax
    push bx
    push dx

    mov bx, [bp+8] ; bx = tile code
    cmp bx, T_SKY
    je .end ; sky is the background, draw nothing
    cmp bx, T_COIN
    je .coin
    cmp bx, T_FLAG
    je .flag

    ; pick the main colour of the tile
    mov ax, 6 ; normal ground colour
    cmp bx, T_BRICK
    jne .qblock
    mov ax, 4 ; brick colour
.qblock:
    cmp bx, T_QCOIN
    je .yellow
    cmp bx, T_QMUSH
    jne .empty
.yellow:
    mov ax, 14 ; ? blocks are yellow
    jmp .base
.empty:
    cmp bx, T_EMPTY
    jne .pipe
    mov ax, 7 ; used ? block is grey
.pipe:
    cmp bx, T_PIPE_L
    jb .stair ; code is below the pipe codes
    cmp bx, T_PIPE_BR
    ja .stair; code is above the pipe codes
    mov ax, 2  ; pipes are green
.stair:
    cmp bx, T_STAIR
    jne .base
    mov ax, 6 ; stair blocks use the ground colour

.base:
    ; fill the whole 16x16 tile with the colour
    push ax ; colour
    mov ax, 16
    push ax ; height
    mov ax, 16
    push ax  ; width
    push word [bp+6] ; y
    push word [bp+4] ; x
    call fillRect
    add sp, 10

    ; add a top stripe to ground, pipes and stairs (HUD covers row 0)
    cmp bx, T_GROUND
    jne .maybePipe
    mov ax, 10 ; light green stripe on ground
    push ax
    jmp .stripe
.maybePipe:
    cmp bx, T_PIPE_L
    jb .maybeStair
    cmp bx, T_PIPE_BR
    ja .maybeStair
    mov ax, 10 ; light green stripe on pipes
    push ax
    jmp .stripe
.maybeStair:
    cmp bx, T_STAIR
    jne .maybeQuestion
    mov ax, 14 ; yellow stripe on stairs
    push ax

.stripe:
    mov ax, 3
    push ax ; height 3
    mov ax, 16
    push ax  ; width 16
    push word [bp+6] ; y
    push word [bp+4]  ; x
    call fillRect
    add sp, 10
    jmp .end

.maybeQuestion:
    cmp bx, T_QCOIN
    je .question
    cmp bx, T_QMUSH
    jne .end  ; bricks and used blocks need nothing more

.question:
    ; write a ? in the middle of the block
    mov ax, 8
    push ax ; text colour
    mov ax, textQuestion
    push ax ; address of the text
    mov ax, [bp+6]
    add ax, 5
    push ax ; y + 5
    mov ax, [bp+4]
    add ax, 5
    push ax ; x + 5
    call drawText
    add sp, 8
    jmp .end

.coin:
    mov ax, 0
    push ax  ; 0 = no mirror
    mov ax, sprCoin
    push ax ; coin sprite
    push word [bp+6]  ; y
    push word [bp+4] ; x
    call drawSprite
    add sp, 8
    jmp .end

.flag:
    ; the pole is a thin white line, 2 wide and 16 tall
    mov ax, 15
    push ax ; white
    mov ax, 16
    push ax; height
    mov ax, 2
    push ax ; width
    push word [bp+6] ; y
    mov ax, [bp+4]
    add ax, 7
    push ax  ; x + 7, so the pole is in the middle
    call fillRect
    add sp, 10

    mov ax, [bp+6]
    cmp ax, 32
    jne .end ; the cloth is only on the top tile (row 2 = y 32)
    mov ax, 4
    push ax; red
    mov ax, 9
    push ax; height
    mov ax, 10
    push ax ; width
    push word [bp+6]; y
    mov ax, [bp+4]
    add ax, 8
    push ax; x + 8, next to the pole
    call fillRect
    add sp, 10

.end:
    pop dx
    pop bx
    pop ax
    pop bp
    ret

textQuestion db '?', 0


; drawMap
; purpose: draws the visible part of the map into the frame buffer
;21 columns are drawn, the extra one is partly visible at the right edge
; inputs: cameraX and gameMap
; output: the tiles are drawn into the frame buffer
; changes: nothing (all registers are saved and restored)
; screen x = tile column*16 - cameraX (this is the "relative x")

drawMap:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, [cameraX]
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    mov si, ax ; si = first tile column on screen (cameraX/16)
    mov dx, 1 ; dx = row, start at 1 to skip the HUD row

.row:
    cmp dx, 12
    jge .done ; all 12 rows done
    xor cx, cx ; cx = screen column, 0 to 20

.column:
    cmp cx, 21
    jge .nextRow
    mov bx, si
    add bx, cx; bx = map column
    cmp bx, 60
    jge .nextRow ; past the end of the map

    ; find the tile: row*60 + column
    mov ax, dx
    mov di, ax
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1 ; di = row*64
    shl ax, 1
    shl ax, 1; ax = row*4
    sub di, ax; di = row*60
    add di, bx ; di = row*60 + column
    xor ax, ax
    mov al, [gameMap+di]
    push ax ; tile code

    mov ax, dx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    push ax ; screen y = row*16

    mov ax, bx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    sub ax, [cameraX]
    push ax ; screen x = column*16 - cameraX

    call drawTile
    add sp, 6
    inc cx
    jmp .column

.nextRow:
    inc dx
    jmp .row

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret