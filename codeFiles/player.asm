; player.asm - Ali
; mario movement: 8.8 velocity, 16.8 position, gravity and tile collision
; velocity: high byte = whole pixels per frame, low byte = fraction (1/256 pixel)
; position: marioX/marioY = whole pixels, marioXFrac/marioYFrac = fraction
; the world is 960 pixels wide so x needs 16 bits, that is why position is 16.8


; marioHeight
; purpose: gives the height of mario right now (small = 16, super = 32)
; inputs: health (1 = small, 2 = super)
; output: AX = 16 or 32
; changes: AX and FLAGS only

marioHeight:
    mov ax, 16 ; assume small
    cmp byte [health], 2
    jne .done
    mov ax, 32 ;super mario is 2 tiles tall
.done:
    ret


; stepMarioX / stepMarioY
; purpose: adds the 8.8 velocity to the 16.8 position
; inputs: marioVX or marioVY (signed 8.8)
; output: marioX + marioXFrac (or marioY + marioYFrac) moved by the velocity
; changes: FLAGS only (AX and BX are saved and restored)
; the low byte (fraction) is added first, and adc carries into the pixel part
; cbw sign-extends the high byte, so a negative velocity moves left/up

stepMarioX:
    push ax
    push bx
    mov ax, [marioVX]
    mov bl, al ; bl = fraction part of the speed
    mov al, ah ; al = whole pixel part of the speed
    cbw ; ax = signed whole pixels
    add byte [marioXFrac], bl ; add the fractions, this sets carry
    adc [marioX], ax  ; add the pixels plus the carry
    pop bx
    pop ax
    ret

stepMarioY:
    push ax
    push bx
    mov ax, [marioVY]
    mov bl, al ; bl = fraction part
    mov al, ah ; al = whole pixel part
    cbw
    add byte [marioYFrac], bl
    adc [marioY], ax
    pop bx
    pop ax
    ret


; moveMario
; purpose: one frame of mario: controls, gravity, collisions and pose
; inputs: keysDown, health and all the mario variables
; output: updated mario variables, may call hitBlock and beginDeath
; changes: nothing (all registers are saved and restored)
; called once per frame while the game state is PLAYING
; getTile is called with y pushed first, then x (so x is at [bp+4])
; tiles 1 to 10 are solid, 0 is sky, 11 coin and 12 flag can be walked through

moveMario:
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [marioY]
    mov [oldMarioY], ax ; remember where mario was (enemies use this for stomps)

    ; ---- horizontal speed ----
    ; bx = top speed: 0180h walking, 0280h when shift (run) is held
    mov bx, 0180h
    cmp byte [keysDown+K_SHIFT], 0
    je .speedSet
    mov bx, 0280h
.speedSet:
    cmp byte [keysDown+K_RIGHT], 0
    je .notRight
    cmp byte [keysDown+K_LEFT], 0
    jne .friction ; both arrows held, act like none
    mov byte [marioFace], 0 ; facing right
    add word [marioVX], 0020h ; speed up
    mov ax, [marioVX]
    cmp ax, bx
    jle .jump
    mov [marioVX], bx ; do not go over the top speed
    jmp .jump

.notRight:
    cmp byte [keysDown+K_LEFT], 0
    je .friction ; no arrow held, slow down
    mov byte [marioFace], 1 ; facing left
    sub word [marioVX], 0020h
    mov ax, bx
    neg ax  ;ax= -top speed
    cmp [marioVX], ax
    jge .jump
    mov [marioVX], ax
    jmp .jump

.friction:
    ; no key pressed, slow mario down towards 0 and never past it
    cmp word [marioVX], 0
    je .jump
    jg .frictionRight
    add word [marioVX], 0010h  ; moving left, add to slow down
    cmp word [marioVX], 0
    jle .jump
    mov word [marioVX], 0; do not start moving the other way
    jmp .jump
.frictionRight:
    sub word [marioVX], 0010h ; moving right, subtract to slow down
    cmp word [marioVX], 0
    jge .jump
    mov word [marioVX], 0

    ; ---- jump ----
.jump:
    cmp byte [keysDown+K_SPACE], 0
    jne .spaceHeld
    mov byte [jumpReady], 1 ; space released, a new jump is allowed
    cmp word [marioVY], 0FE00h
    jge .gravity
    mov word [marioVY], 0FE00h ; space let go early, cut the jump short
    jmp .gravity
.spaceHeld:
    cmp byte [onGround], 1
    jne .gravity ; no jumping in the air (no double jump)
    cmp byte [jumpReady], 1
    jne .gravity ; space must be released and pressed again
    mov byte [jumpReady], 0
    mov byte [onGround], 0
    mov word [marioVY], 0FA80h ; jump speed, about -5.5 pixels per frame

    ; ---- gravity ----
.gravity:
    add word [marioVY], 0040h ; falls faster every frame
    cmp word [marioVY], 0400h
    jle .horizontal
    mov word [marioVY], 0400h ; maximum falling speed

    ; ---- move sideways, then check walls ----
.horizontal:
    mov ax, [marioX]
    mov cx, ax ; cx and dl keep the old position
    mov dl, [marioXFrac] ; in case the move is blocked
    call stepMarioX
    cmp word [marioX], 944
    jle .leftBoundary
    mov word [marioX], 944 ; right end of the level (960 - 16)
    mov byte [marioXFrac], 0
    mov word [marioVX], 0
.leftBoundary:
    mov ax, [cameraX]
    cmp [marioX], ax
    jge .testWall
    mov [marioX], ax ; cannot go left of the camera
    mov byte [marioXFrac], 0
    mov word [marioVX], 0

.testWall:
    mov bx, [marioX]
    cmp word [marioVX], 0
    jl .leftHitbox
    add bx, 13 ; moving right, check the right side of mario
    jmp .probeWall
.leftHitbox:
    add bx, 2 ; moving left, check the left side
.probeWall:
    mov si, [marioY]
    add si, 2 ; upper body
    push si ; y
    push bx ; x
    call getTile
    add sp, 4
    cmp al, 1
    jb .lowerWall ; below 1 = sky, free
    cmp al, 10
    jbe .wallBlocked ; 1 to 10 = solid
.lowerWall:
    call marioHeight
    add si, ax
    sub si, 4 ; lower body (4 pixels above the feet)
    push si
    push bx
    call getTile
    add sp, 4
    cmp al, 1
    jb .vertical
    cmp al, 10
    ja .vertical
.wallBlocked:
    mov [marioX], cx ; put mario back where he was
    mov [marioXFrac], dl
    mov word [marioVX], 0 ; and stop his sideways speed

    ; ---- move up/down, then check floor and ceiling ----
.vertical:
    mov byte [onGround], 0 ; assume in the air until we land
    call stepMarioY
    cmp word [marioVY], 0
    jl .headCollision ; going up, check the ceiling
    call marioHeight
    mov bx, [marioY]
    add bx, ax ; bx = new bottom edge (feet)
    mov si, [marioX]
    add si, 3 ; left foot
    push bx
    push si
    call getTile
    add sp, 4
    cmp al, 1
    jb .footRight
    cmp al, 10
    jbe .land
.footRight:
    add si, 9 ; right foot
    push bx
    push si
    call getTile
    add sp, 4
    cmp al, 1
    jb .pit
    cmp al, 10
    ja .pit

.land:
    and bx, 0FFF0h ; top of the tile the feet are in
    call marioHeight
    sub bx, ax  ; stand mario on top of that tile
    mov [marioY], bx
    mov byte [marioYFrac], 0
    mov word [marioVY], 0
    mov byte [onGround], 1
    mov byte [stompCount], 0 ; landing resets the stomp chain
    jmp .pose

.headCollision:
    mov si, [marioX]
    add si, 8 ; middle of mario
    mov bx, [marioY] ; top of mario
    push bx
    push si
    call getTile
    add sp, 4
    cmp al, 1
    jb .pose
    cmp al, 10
    ja .pose
    ; head hit the bottom of a solid tile, let the block react once
    push bx
    push si
    call hitBlock ; from the events module
    add sp, 4
    and bx, 0FFF0h
    add bx, 16  ; put mario just below the tile
    mov [marioY], bx
    mov byte [marioYFrac], 0
    mov word [marioVY], 0 ; stop going up
    jmp .pose

.pit:
    cmp word [marioY], 192
    jl .pose ; not below the map yet
    mov byte [pitDeath], 1
    call beginDeath ; from the states module

    ; ---- pose for the sprite: 0 stand, 1 walk, 2 jump ----
.pose:
    mov byte [marioPose], 0
    cmp byte [onGround], 0
    je .jumpPose
    cmp word [marioVX], 0
    je .done
    mov byte [marioPose], 1
    jmp .done
.jumpPose:
    mov byte [marioPose], 2

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret