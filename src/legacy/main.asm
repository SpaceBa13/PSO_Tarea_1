[BITS 16]
[ORG 0x7C00]

start:
    ; Configuración de segmentos y pila
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Lógica principal del Reloj/Cronómetro usando INT 1Ah, INT 10h e INT 16h
    jmp $

times 510-($-$$) db 0
dw 0xAA55