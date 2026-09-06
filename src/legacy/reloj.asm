; ===================== Manejo de Reloj :D ==================



mostrar_hora:
    mov dh, [segundo_actual]
    mov [segundo_anterior], dh

    ; Posicion donde se muestra la hora
    mov dh, 5
    mov dl, 30
    call mover_cursor

    ; Horas
    mov al, [hora_actual]
    call imprimir_bcd

    mov si, dos_puntos
    call imprimir_cadena

    ; Minutos
    mov al, [minuto_actual]
    call imprimir_bcd

    mov si, dos_puntos
    call imprimir_cadena

    ; Segundos
    mov al, [segundo_actual]
    call imprimir_bcd

    ret

leer_hora_sistema:
    mov ah, 0x02 ; servicio de la interrupcion
    int 0x1a ; interrupcion para obtener la hora

    ; Guardar valores
    mov [hora_actual], ch
    mov [minuto_actual], cl
    mov [segundo_actual], dh
    ret


actualizar_reloj:
    mov al, [segundo_actual]

    cmp al, [segundo_anterior]
    je .fin

    mov [segundo_anterior], al

    call mostrar_hora

.fin:
    ret

; ==============Variables del reloj================

hora_actual:
    db 0

minuto_actual:
    db 0

segundo_actual:
    db 0

segundo_anterior:
    db 0xFF
