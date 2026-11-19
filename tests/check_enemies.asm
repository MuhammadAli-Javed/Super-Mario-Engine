cpu 8086
[org 0x0100]
%include "codeFiles/constants.inc"
jmp start
%include "codeFiles/gameData.inc"
%include "codeFiles/enemies.asm"
passMsg db "CHECK PASSED$"
failMsg db "CHECK FAILED$"
start:
    push cs
    pop ds
    cld
    call resetEnemies
    cmp byte [enemyList], E_GOOMBA
    jne failed
    cmp word [enemyList+2], 160
    jne failed
    mov byte [enemyList], 0
    call resetEnemies
    cmp byte [enemyList], E_GOOMBA
    jne failed
    mov dx, passMsg
    jmp finish
failed:
    mov dx, failMsg
finish:
    mov ah, 09h
    int 21h
    mov ax, 4c00h
    int 21h
