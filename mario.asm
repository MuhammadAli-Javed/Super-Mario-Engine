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


mov ax, 4c00h
int 21h
