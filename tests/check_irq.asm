; check_irq.asm - small test for the keyboard and timer handlers
; build from the repo root: nasm -f bin tests/check_irq.asm -o CHECK.COM

cpu 8086
[org 0x0100]

%include "codeFiles/constants.inc"

    jmp start

%include "codeFiles/gameData.inc"
%include "codeFiles/interrupts.asm"

promptMsg  db "Press Esc to finish the test...", 13, 10, "$"
passMsg    db "IRQ CHECK PASSED$"
failMsg    db "IRQ CHECK FAILED$"
startTicks dw 0

start:
    push cs
    pop ds
    cld

    mov dx, promptMsg
    mov ah, 09h
    int 21h

    mov ax, [timerTicks]
    mov [startTicks], ax ; remember the timer count before we start
    call installInterrupts

.wait:
    cmp byte [keysDown+K_ESC], 1
    jne .wait  ; wait until Esc is pressed (handler fills keysDown)

    call restoreInterrupts; put the old vectors back before using DOS again

    mov ax, [timerTicks]
    cmp ax, [startTicks]
    je failed ; timer never counted, so the timer handler did not run
    cmp byte [irqInstalled], 0
    jne failed ; vectors were not restored

    mov dx, passMsg
    jmp finish
failed:
    mov dx, failMsg

finish:
    mov ah, 09h
    int 21h
    mov ax, 4c00h
    int 21h