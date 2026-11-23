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

