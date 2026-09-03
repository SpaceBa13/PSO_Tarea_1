; ======================== Modo cronometro ==================

; ============= Mensajes =============
titulo2:
    db '=== CRONOMETRO0000 ===', 13, 10
    db 0


actualizar_cronometro:

    ;---- mostrar titulo ----
    mov dh, 0x10    ; fila
    mov dl, 0x17    ; columna
    call mover_cursor

    mov si, titulo2   ; copiar a si la cadena de texto a imprimir
    call imprimir_cadena

    ret


; ==============Variables del reloj================
minutos_c:
    db 0

segundos_c:
    db 0