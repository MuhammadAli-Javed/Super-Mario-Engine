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
    mov ax, 0003h
    int 10h

mov ax, 4c00h
int 21h
