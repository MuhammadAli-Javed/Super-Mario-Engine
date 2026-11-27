; Moiz: main state machine, restart, win and death flow
stateTable dw stateTitle, statePlay, statePause, stateDying, stateLife
           dw stateWin, stateDone, stateOver, stateExit

titleLabel     db 'SUPER MARIO ENGINE',0
titleStart     db 'START GAME',0
titleExit      db 'EXIT',0
titleHelp      db 'ARROWS SPACE SHIFT P ESC',0
titleMembers   db 'SUBHAN ALI MOIZ',0
pauseLabel     db 'PAUSED',0
pauseHelp      db 'P TO RESUME   ESC TITLE',0
lifeLabel      db 'WORLD 1-1',0
lifeDesc       db 'LIVES LEFT',0
completeLabel  db 'LEVEL COMPLETE',0
overLabel      db 'GAME OVER',0
continueLabel  db 'ENTER TO TITLE',0
finalScoreTxt  db 'SCORE',0
finalCoinTxt   db 'COINS',0
finalTimeTxt   db 'TIME BONUS',0
testInfoTxt    db 'T TIME 5   C COINS 99',0
timeBonus      dw 0

; Reset a lost life: retain score and coins but reset all level elements.
; Inputs none; output hero, enemy, clock, camera and working map. Preserves regs.
resetLevel:
    call resetMap
    call resetEnemies
    mov word [marioX], 32
    mov byte [marioXFrac], 0
    mov word [marioY], 144
    mov byte [marioYFrac], 0
    mov word [oldMarioY], 144
    mov word [marioVX], 0
    mov word [marioVY], 0
    mov byte [onGround], 1
    mov byte [jumpReady], 1
    mov byte [marioFace], 0
    mov byte [marioPose], 0
    mov byte [health], 1
    mov byte [invuln], 0
    mov byte [stompCount], 0
    mov byte [mushActive], 0
    mov byte [coinPopTimer], 0
    mov byte [pitDeath], 0
    mov word [levelTime], 300
    mov word [tickPart], 0
    mov word [cameraX], 0
    ret

; New game: all counters reset, including lives, score and coins.
; Inputs none. Changes game state variables; preserves registers.
newGame:
    mov byte [lives], 3
    mov byte [coins], 0
    mov word [scoreLow], 0
    mov word [scoreHigh], 0
    mov word [timeBonus], 0
    call resetLevel
    ret

; Begin death sequence once. Called on damage, time-out or pit.
; Changes state and animation timer; preserves registers.
beginDeath:
    cmp byte [state], ST_PLAY
    jne .done
    mov byte [state], ST_DYING
    mov word [stateTimer], 0
    mov word [marioVX], 0
.done:
    ret

; Begin win sequence after flag points were already added.
; Inputs none, output state=WIN, timer zero. Preserves registers.
beginWin:
    cmp byte [state], ST_PLAY
    jne .done
    mov byte [state], ST_WIN
    mov word [stateTimer], 0
    mov word [marioVX], 0
.done:
    ret

; Execute state-specific logic through the required indexed jump table.
; Inputs state, keyboard table; returns updated state. Registers preserved.
updateState:
    push ax
    push bx
    xor bx, bx
    mov bl, [state]
    cmp bl, ST_EXIT
    ja .done
    shl bx, 1
    call word [stateTable+bx]
.done:
    pop bx
    pop ax
    ret

; TITLE state: Up/Down change option, Enter selects, Esc exits.
stateTitle:
    push ax
    mov ax, K_UP
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    je .toggle
    mov ax, K_DOWN
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .enter
.toggle:
    xor byte [menuChoice], 1
.enter:
    mov ax, K_ENTER
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .escape
    cmp byte [menuChoice], 0
    jne .quit
    call newGame
    mov byte [state], ST_PLAY
    jmp .done
.escape:
    mov ax, K_ESC
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .done
.quit:
    mov byte [state], ST_EXIT
.done:
    pop ax
    ret

; PLAYING state: obey the specified per-frame update order.
statePlay:
    push ax
    mov ax, K_ESC
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .checkPause
    mov byte [state], ST_TITLE
    jmp .done
.checkPause:
    mov ax, K_P
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .debug
    mov byte [state], ST_PAUSE
    jmp .done
.debug:
    ; Documented, optional test shortcuts for the live demo.
    mov ax, K_T
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .debugCoins
    mov word [levelTime], 5
.debugCoins:
    mov ax, K_C
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .move
    mov byte [coins], 99
.move:
    call moveMario
    cmp byte [state], ST_PLAY
    jne .done
    call updateEnemies
    call updateMushroom
    call updateCoinPop
    call collectTiles
    call checkEnemyCollisions
    cmp byte [state], ST_PLAY
    jne .done
    cmp byte [invuln], 0
    je .clock
    dec byte [invuln]
.clock:
    add word [tickPart], 10    ; 18.2 BIOS ticks per real second
    cmp word [tickPart], 182
    jb .flag
    sub word [tickPart], 182
    cmp word [levelTime], 0
    je .timeUp
    dec word [levelTime]
    jnz .flag
.timeUp:
    mov byte [pitDeath], 0
    call beginDeath
    jmp .done
.flag:
    call checkFlag
    cmp byte [state], ST_PLAY
    jne .done
    call updateCamera
.done:
    pop ax
    ret

; PAUSED state: no physics/enemies/clock updates.
statePause:
    push ax
    mov ax, K_P
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .escape
    mov byte [state], ST_PLAY
    jmp .done
.escape:
    mov ax, K_ESC
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .done
    mov byte [state], ST_TITLE
.done:
    pop ax
    ret

; DYING state: short hop then fall, or fall immediately for pit death.
; At about 27 timer frames, consume one life and change screen.
stateDying:
    inc word [stateTimer]
    cmp byte [pitDeath], 0
    jne .down
    cmp word [stateTimer], 12
    ja .down
    sub word [marioY], 4
    jmp .finishCheck
.down:
    add word [marioY], 8
.finishCheck:
    cmp word [stateTimer], 27
    jb .done
    dec byte [lives]
    mov word [stateTimer], 0
    cmp byte [lives], 0
    jne .oneLeft
    mov byte [state], ST_OVER
    jmp .done
.oneLeft:
    mov byte [state], ST_LIFE
.done:
    ret

; LIFE LOST state: freeze, wait ~2 seconds, restore map and re-enter PLAY.
stateLife:
    inc word [stateTimer]
    cmp word [stateTimer], 36
    jb .done
    call resetLevel
    mov byte [state], ST_PLAY
.done:
    ret

; WIN sequence: brief flag slide, then walk; award time bonus once.
stateWin:
    push ax
    push bx
    push dx
    inc word [stateTimer]
    cmp word [stateTimer], 18
    ja .walk
    mov ax, 144
    cmp byte [health], 2
    jne .small
    sub ax, 16
.small:
    cmp word [marioY], ax
    jge .endMotion
    add word [marioY], 2
    jmp .endMotion
.walk:
    add word [marioX], 2
.endMotion:
    cmp word [stateTimer], 36
    jb .done
    mov ax, [levelTime]
    mov bx, 50
    mul bx
    mov [timeBonus], ax
    push ax
    call addScore
    add sp, 2
    mov byte [state], ST_DONE
.done:
    pop dx
    pop bx
    pop ax
    ret

; LEVEL COMPLETE / GAME OVER -> TITLE on Enter.
stateDone:
    push ax
    mov ax, K_ENTER
    push ax
    call newPress
    add sp, 2
    cmp al, 1
    jne .done
    mov byte [state], ST_TITLE
.done:
    pop ax
    ret
stateOver:
    jmp stateDone
stateExit:
    ret

; Render exactly one new frame, including menus and overlays.
; Changes the off-screen buffer, then presents once via REP MOVSW.
renderFrame:
    push ax
    push bx
    call clearFrame
    ; The bottom eight pixels are outside the tile grid and stay black.
    mov ax, 0
    push ax
    mov ax, 8
    push ax
    mov ax, 320
    push ax
    mov ax, 192
    push ax
    mov ax, 0
    push ax
    call fillRect
    add sp, 10
    mov al, [state]
    cmp al, ST_TITLE
    je .title
    cmp al, ST_LIFE
    je .life
    cmp al, ST_DONE
    je .completed
    cmp al, ST_OVER
    je .over
    call drawMap
    call drawEnemies
    call drawMushroom
    call drawCoinPop
    call drawMario
    call drawHUD
    cmp byte [state], ST_PAUSE
    jne .present
    mov ax, 14
    push ax
    mov ax, pauseLabel
    push ax
    mov ax, 82
    push ax
    mov ax, 138
    push ax
    call drawText
    add sp, 8
    mov ax, 15
    push ax
    mov ax, pauseHelp
    push ax
    mov ax, 98
    push ax
    mov ax, 90
    push ax
    call drawText
    add sp, 8
    jmp .present
.title:
    call drawPanel
    mov ax, 14
    push ax
    mov ax, titleLabel
    push ax
    mov ax, 43
    push ax
    mov ax, 106
    push ax
    call drawText
    add sp, 8
    mov ax, 15
    push ax
    mov ax, titleMembers
    push ax
    mov ax, 167
    push ax
    mov ax, 113
    push ax
    call drawText
    add sp, 8
    mov ax, 15
    push ax
    mov ax, titleHelp
    push ax
    mov ax, 181
    push ax
    mov ax, 89
    push ax
    call drawText
    add sp, 8
    mov ax, 15
    cmp byte [menuChoice], 0
    jne .notStart
    mov ax, 14
.notStart:
    push ax
    mov ax, titleStart
    push ax
    mov ax, 88
    push ax
    mov ax, 124
    push ax
    call drawText
    add sp, 8
    mov ax, 15
    cmp byte [menuChoice], 1
    jne .notExit
    mov ax, 14
.notExit:
    push ax
    mov ax, titleExit
    push ax
    mov ax, 111
    push ax
    mov ax, 142
    push ax
    call drawText
    add sp, 8
    jmp .present
.life:
    call drawPanel
    mov ax, 14
    push ax
    mov ax, lifeLabel
    push ax
    mov ax, 64
    push ax
    mov ax, 133
    push ax
    call drawText
    add sp, 8
    mov ax, 15
    push ax
    mov ax, lifeDesc
    push ax
    mov ax, 91
    push ax
    mov ax, 111
    push ax
    call drawText
    add sp, 8
    xor bx, bx
    mov bl, [lives]
    mov ax, 14
    push ax
    mov ax, 2
    push ax
    mov ax, 0
    push ax
    push bx
    mov ax, 105
    push ax
    mov ax, 183
    push ax
    call drawNumber
    add sp, 12
    jmp .present
.completed:
    call drawPanel
    mov ax, 14
    push ax
    mov ax, completeLabel
    push ax
    mov ax, 42
    push ax
    mov ax, 115
    push ax
    call drawText
    add sp, 8
    mov ax, 15
    push ax
    mov ax, finalTimeTxt
    push ax
    mov ax, 75
    push ax
    mov ax, 90
    push ax
    call drawText
    add sp, 8
    mov ax, 14
    push ax
    mov ax, 5
    push ax
    mov ax, 0
    push ax
    push word [timeBonus]
    mov ax, 75
    push ax
    mov ax, 171
    push ax
    call drawNumber
    add sp, 12
    call drawFinalScore
    jmp .present
.over:
    call drawPanel
    mov ax, 4
    push ax
    mov ax, overLabel
    push ax
    mov ax, 52
    push ax
    mov ax, 131
    push ax
    call drawText
    add sp, 8
    call drawFinalScore
.present:
    call showFrame
    pop bx
    pop ax
    ret

; Draw the title/end-screen simple coloured border. Registers preserved.
drawPanel:
    push ax
    mov ax, 4
    push ax
    mov ax, 124
    push ax
    mov ax, 260
    push ax
    mov ax, 35
    push ax
    mov ax, 30
    push ax
    call fillRect
    add sp, 10
    mov ax, 1
    push ax
    mov ax, 116
    push ax
    mov ax, 252
    push ax
    mov ax, 39
    push ax
    mov ax, 34
    push ax
    call fillRect
    add sp, 10
    pop ax
    ret

; Draw final SCORE and ENTER hint (used by win and game-over screens).
drawFinalScore:
    push ax
    mov ax, 15
    push ax
    mov ax, finalScoreTxt
    push ax
    mov ax, 96
    push ax
    mov ax, 102
    push ax
    call drawText
    add sp, 8
    mov ax, 14
    push ax
    mov ax, 6
    push ax
    push word [scoreHigh]
    push word [scoreLow]
    mov ax, 96
    push ax
    mov ax, 163
    push ax
    call drawNumber
    add sp, 12
    mov ax, 15
    push ax
    mov ax, continueLabel
    push ax
    mov ax, 139
    push ax
    mov ax, 106
    push ax
    call drawText
    add sp, 8
    pop ax
    ret
