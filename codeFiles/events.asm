; Moiz: scoring, item events, damage and goal
stompTable dw 100,200,400,500,800,1000,2000,4000,5000,8000

; AddScore(points) - stack word [bp+4]. Score is 32-bit with ADD/ADC.
; Clamp to 999999 (000F423Fh). Does not change other registers.
addScore:
    push bp
    mov bp, sp
    push ax
    push dx
    mov ax, [bp+4]
    add [scoreLow], ax
    adc word [scoreHigh], 0
    cmp word [scoreHigh], 000Fh
    ja .limit
    jb .done
    cmp word [scoreLow], 423Fh
    jbe .done
.limit:
    mov word [scoreHigh], 000Fh
    mov word [scoreLow], 423Fh
.done:
    pop dx
    pop ax
    pop bp
    ret

; Extra life until cap of 99. No input/output; preserves registers.
addLife:
    cmp byte [lives], 99
    jae .done
    inc byte [lives]
.done:
    ret

; Add a single coin and +200 points, give life at 100.
; Inputs none; output score/coins/lives; preserves registers.
addCoin:
    push ax
    inc byte [coins]
    mov ax, 200
    push ax
    call addScore
    add sp, 2
    cmp byte [coins], 100
    jb .done
    mov byte [coins], 0
    call addLife
.done:
    pop ax
    ret

; Award consecutive stomp points. 11th stomp in one jump is 1-UP.
; Inputs stompCount, output score/lives/count; all registers preserved.
giveStompPoints:
    push ax
    push bx
    inc byte [stompCount]
    mov al, [stompCount]
    cmp al, 11
    jb .regular
    call addLife
    jmp .done
.regular:
    xor ah, ah
    dec ax
    shl ax, 1
    mov bx, ax
    push word [stompTable+bx]
    call addScore
    add sp, 2
.done:
    pop bx
    pop ax
    ret

; Side contact with enemy: Super->Small with 2-second immunity;
; Small->DYING. Pits/time bypass this procedure. Preserves registers.
hurtMario:
    cmp byte [state], ST_PLAY
    jne .done
    cmp byte [invuln], 0
    jne .done
    cmp byte [health], 2
    jne .die
    mov byte [health], 1
    add word [marioY], 16  ; feet stay at the same y position
    mov byte [invuln], 36
    jmp .done
.die:
    mov byte [pitDeath], 0
    call beginDeath
.done:
    ret

; Moiz: scoring, item events, damage and goal
stompTable dw 100,200,400,500,800,1000,2000,4000,5000,8000

; AddScore(points) - stack word [bp+4]. Score is 32-bit with ADD/ADC.
; Clamp to 999999 (000F423Fh). Does not change other registers.
addScore:
    push bp
    mov bp, sp
    push ax
    push dx
    mov ax, [bp+4]
    add [scoreLow], ax
    adc word [scoreHigh], 0
    cmp word [scoreHigh], 000Fh
    ja .limit
    jb .done
    cmp word [scoreLow], 423Fh
    jbe .done
.limit:
    mov word [scoreHigh], 000Fh
    mov word [scoreLow], 423Fh
.done:
    pop dx
    pop ax
    pop bp
    ret

; Extra life until cap of 99. No input/output; preserves registers.
addLife:
    cmp byte [lives], 99
    jae .done
    inc byte [lives]
.done:
    ret

; Add a single coin and +200 points, give life at 100.
; Inputs none; output score/coins/lives; preserves registers.
addCoin:
    push ax
    inc byte [coins]
    mov ax, 200
    push ax
    call addScore
    add sp, 2
    cmp byte [coins], 100
    jb .done
    mov byte [coins], 0
    call addLife
.done:
    pop ax
    ret

; Award consecutive stomp points. 11th stomp in one jump is 1-UP.
; Inputs stompCount, output score/lives/count; all registers preserved.
giveStompPoints:
    push ax
    push bx
    inc byte [stompCount]
    mov al, [stompCount]
    cmp al, 11
    jb .regular
    call addLife
    jmp .done
.regular:
    xor ah, ah
    dec ax
    shl ax, 1
    mov bx, ax
    push word [stompTable+bx]
    call addScore
    add sp, 2
.done:
    pop bx
    pop ax
    ret

; Side contact with enemy: Super->Small with 2-second immunity;
; Small->DYING. Pits/time bypass this procedure. Preserves registers.
hurtMario:
    cmp byte [state], ST_PLAY
    jne .done
    cmp byte [invuln], 0
    jne .done
    cmp byte [health], 2
    jne .die
    mov byte [health], 1
    add word [marioY], 16  ; feet stay at the same y position
    mov byte [invuln], 36
    jmp .done
.die:
    mov byte [pitDeath], 0
    call beginDeath
.done:
    ret

; HitBlock(worldX, worldY). Invoked when Mario's head rises into a solid tile.
; Changes working map, coin total or mushroom. Other registers preserved.
hitBlock:
    push bp
    mov bp, sp
    push ax
    push bx
    push dx
    push di
    mov ax, [bp+4]
    mov dx, [bp+6]
    cmp ax, 0
    jl .done
    cmp ax, 960
    jge .done
    cmp dx, 16
    jl .done
    cmp dx, 192
    jge .done
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr dx, 1
    shr dx, 1
    shr dx, 1
    shr dx, 1
    mov bx, dx
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl dx, 1
    shl dx, 1
    sub bx, dx
    add bx, ax
    mov di, bx
    mov al, [gameMap+di]
    cmp al, T_BRICK
    jne .questionCoin
    cmp byte [health], 2
    jne .done
    mov byte [gameMap+di], T_SKY
    mov ax, 50
    push ax
    call addScore
    add sp, 2
    jmp .done
.questionCoin:
    cmp al, T_QCOIN
    jne .questionMush
    mov byte [gameMap+di], T_EMPTY
    call addCoin
    mov byte [coinPopTimer], 12
    mov ax, [bp+4]
    and ax, 0FFF0h
    mov [coinPopX], ax
    mov ax, [bp+6]
    and ax, 0FFF0h
    sub ax, 16
    mov [coinPopY], ax
    jmp .done
.questionMush:
    cmp al, T_QMUSH
    jne .done
    mov byte [gameMap+di], T_EMPTY
    mov byte [mushActive], 1
    mov byte [mushDir], 1
    mov ax, [bp+4]
    and ax, 0FFF0h
    mov [mushX], ax
    mov ax, [bp+6]
    and ax, 0FFF0h
    sub ax, 16
    mov [mushY], ax
.done:
    pop di
    pop dx
    pop bx
    pop ax
    pop bp
    ret

; Collect map coins where the hero rectangle overlaps a coin tile.
; Inputs marioX/Y/health; output score, coin counter and map. Registers preserved.
collectTiles:
    push ax
    push bx
    push dx
    mov bx, [marioX]
    add bx, 8
    mov dx, [marioY]
    add dx, 4
    push dx
    push bx
    call takeCoinTile
    add sp, 4
    call marioHeight
    mov dx, [marioY]
    add dx, ax
    sub dx, 4
    push dx
    push bx
    call takeCoinTile
    add sp, 4
    pop dx
    pop bx
    pop ax
    ret

; takeCoinTile(x,y) removes one coin from working map if present.
; Returns no registers; only map and counters change.
takeCoinTile:
    push bp
    mov bp, sp
    push ax
    push bx
    push dx
    push di
    push word [bp+6]
    push word [bp+4]
    call getTile
    add sp, 4
    cmp al, T_COIN
    jne .done
    mov ax, [bp+4]
    mov dx, [bp+6]
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr dx, 1
    shr dx, 1
    shr dx, 1
    shr dx, 1
    mov bx, dx
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl dx, 1
    shl dx, 1
    sub bx, dx
    add bx, ax
    mov di, bx
    mov byte [gameMap+di], T_SKY
    call addCoin
.done:
    pop di
    pop dx
    pop bx
    pop ax
    pop bp
    ret

; Move the active mushroom, turn at walls, fall into pits, collect on touch.
; One active mushroom slot, documented limitation when both blocks hit fast.
updateMushroom:
    push ax
    push bx
    push dx
    push si
    cmp byte [mushActive], 0
    je .done
    mov ax, [mushX]
    cmp byte [mushDir], 0
    je .left
    inc ax
    jmp .checkWall
.left:
    dec ax
.checkWall:
    mov si, ax
    mov bx, ax
    cmp byte [mushDir], 0
    je .wallPoint
    add bx, 15
.wallPoint:
    mov dx, [mushY]
    add dx, 8
    push dx
    push bx
    call getTile
    add sp, 4
    cmp al, 1
    jb .move
    cmp al, 10
    ja .move
    xor byte [mushDir], 1
    jmp .checkFloor
.move:
    mov [mushX], si
.checkFloor:
    mov bx, [mushX]
    add bx, 8
    mov dx, [mushY]
    add dx, 16
    push dx
    push bx
    call getTile
    add sp, 4
    cmp al, 1
    jb .fall
    cmp al, 10
    jbe .collect
.fall:
    add word [mushY], 2
    cmp word [mushY], 192
    jl .collect
    mov byte [mushActive], 0
    jmp .done
.collect:
    mov ax, [marioX]
    add ax, 14
    cmp ax, [mushX]
    jle .done
    mov ax, [mushX]
    add ax, 14
    cmp ax, [marioX]
    jle .done
    call marioHeight
    add ax, [marioY]
    cmp ax, [mushY]
    jle .done
    mov ax, [mushY]
    add ax, 16
    cmp ax, [marioY]
    jle .done
    mov byte [mushActive], 0
    mov ax, 1000
    push ax
    call addScore
    add sp, 2
    cmp byte [health], 2
    je .done
    mov byte [health], 2
    sub word [marioY], 16 ; feet stay at their original y value
.done:
    pop si
    pop dx
    pop bx
    pop ax
    ret

; Draw an active mushroom from its own world coordinates.
drawMushroom:
    push ax
    push bx
    cmp byte [mushActive], 0
    je .done
    mov bx, [mushX]
    sub bx, [cameraX]
    mov ax, 0
    push ax
    mov ax, sprMushroom
    push ax
    push word [mushY]
    push bx
    call drawSprite
    add sp, 8
.done:
    pop bx
    pop ax
    ret

; Detect flag pole at x=57*16. Height of contact determines points.
; Changes state through beginWin. Preserves registers.
checkFlag:
    push ax
    push bx
    cmp word [marioX], 904
    jl .done
    cmp word [marioY], 160
    jge .done
    call marioHeight
    add ax, [marioY]
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    mov bx, 100
    cmp ax, 8
    jae .points
    mov bx, 400
    cmp ax, 6
    jae .points
    mov bx, 800
    cmp ax, 5
    jae .points
    mov bx, 2000
    cmp ax, 4
    jae .points
    mov bx, 5000
.points:
    push bx
    call addScore
    add sp, 2
    call beginWin
.done:
    pop bx
    pop ax
    ret

; A short visual pop for a coin from a question block.
; Called only during PLAYING. Preserves registers.
updateCoinPop:
    cmp byte [coinPopTimer], 0
    je .done
    dec byte [coinPopTimer]
    sub word [coinPopY], 2
.done:
    ret

; Draw the temporary coin pop animation; the score was already added.
drawCoinPop:
    push ax
    push bx
    cmp byte [coinPopTimer], 0
    je .done
    mov bx, [coinPopX]
    sub bx, [cameraX]
    mov ax, 0
    push ax
    mov ax, sprCoin
    push ax
    push word [coinPopY]
    push bx
    call drawSprite
    add sp, 8
.done:
    pop bx
    pop ax
    ret
