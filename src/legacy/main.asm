; main.asm

bits 16
org 0x8000

jmp start_main

; ============= Mensajes =============
titulo:
    db '=== RELOJ / CRONOMETRO ===', 13, 10
    db 0

opciones:
    db '[Q] Salir ', 13, 10
    db 0

dos_puntos:
    db ':', 0

; ============= Programa =============
start_main:
    call limpiar_pant

    ;---- mostrar titulo ----
    mov dh, 0x00    ; fila
    mov dl, 0x17    ; columna
    call mover_cursor

    mov si, titulo   ; copiar a si la cadena de texto a imprimir
    call imprimir_cadena

    ;----- mostrar opciones ----
    mov dh, 0x0F    ; fila
    mov dl, 0x14    ; columna
    call mover_cursor

    mov si, opciones
    call imprimir_cadena

    loop_programa:
        call actualizar_reloj

        hlt

        jmp loop_programa

fin:
    cli
    hlt

;================== rutinas externas =================

%include "video.asm"
%include "reloj.asm"

