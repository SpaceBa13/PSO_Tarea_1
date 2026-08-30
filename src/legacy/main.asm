; main.asm

bits 16
org 0x8000

jmp start_main

; ============= Mensajes =============
mensaje:
    db 13, 10
    db 'prueba xd', 13, 10
    db 0

; ============= Programa =============
start_main:

    mov si, mensaje
    call imprimir_cadena

fin:
    cli
    hlt

imprimir_cadena:
    lodsb
    cmp al, 0
    je .fin

    mov ah, 0x0E
    int 0x10

    jmp imprimir_cadena

.fin:
    ret

