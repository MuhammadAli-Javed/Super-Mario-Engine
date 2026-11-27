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
    mov ax, 32 ; super mario is 2 tiles tall
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