; Super Mario Engine
; starting COM program cpu 8086

[org 0x0100]

%include "codeFiles/constants.inc"

jmp start

%include "codeFiles/gameData.inc"

%include "assets/level.inc"
%include "assets/sprites.inc"
%include "codeFiles/graphics.asm"
%include "codeFiles/world.asm"
%include "codeFiles/interrupts.asm"
%include "codeFiles/player.asm"
%include "codeFiles/enemies.asm"
%include "codeFiles/events.asm"
%include "codeFiles/hud.asm"
%include "codeFiles/states.asm"

start:
    cli
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov sp, stackTop
    sti
    cld

    mov ax, cs
    mov es, ax
    mov bx, (programEnd - $$ + 100h + 15) / 16
    mov ah, 4Ah             ; DOS: shrink our memory block to actual program size
    int 21h
    jc memoryError
    mov bx, 4000           ; 4000 paragraphs = 64000 bytes
    mov ah, 48h
    int 21h
    jc memoryError
    mov [bufferSeg], ax

    call installInterrupts
    mov ax, 0013h
    int 10h
    call newGame
    mov byte [state], ST_TITLE
    mov ax, [timerTicks]
    mov [lastTick], ax

mainLoop:
    call waitFrame
    call updateState
    cmp byte [state], ST_EXIT
    je quitGame
    call renderFrame
    call copyKeyHistory
    jmp mainLoop

quitGame:
    call restoreInterrupts
    mov ax, 0003h
    int 10h
    mov ax, [bufferSeg]
    or ax, ax
    jz quitNoFree
    mov es, ax
    mov ah, 49h
    int 21h
quitNoFree:
    mov ax, 4C00h
    int 21h
memoryError:
    mov ax, 0003h
    int 10h
    mov dx, memoryErrorMsg
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h

memoryErrorMsg db 'Not enough DOS memory for the frame buffer.$'

; Copy this frame's key states, for edge-triggered menu keys next frame.
; Inputs: none. Output: keysPrev updated. Changes: FLAGS only.
copyKeyHistory:
    push ax
    push cx
    push si
    push di
    push es
    push ds
    pop es
    mov si, keysDown
    mov di, keysPrev
    mov cx, 128
    cld
    rep movsb
    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret

; Wait for a timer interrupt to increment timerTicks (no calibrated delay).
; Inputs: none. Output: lastTick updated. Changes: FLAGS only.
waitFrame:
    push ax
.wf:
    sti
    hlt
    mov ax, [timerTicks]
    cmp ax, [lastTick]
    je .wf
    mov [lastTick], ax
    pop ax
    ret

; Reserve a small stack inside the resident COM allocation.
programStack: times 2048 db 0
stackTop:
programEnd:
