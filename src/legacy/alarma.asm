; =========================== alarma ==================

; ================= Mensajes =================

msg_configurar_alarma:
    db '=== CONFIGURAR ALARMA ===', 13, 10
    db 13, 10
    db 'Ingrese la hora (HH:MM): ', 0

msg_error_alarma:
    db 13, 10
    db 'Hora invalida. Presione una tecla para intentar de nuevo.', 0

msg_alarma:
    db '!!! ALARMA !!!', 0

msg_cancelar_alarma:
    db '[C] Cancelar alarma', 0

; ================= Rutinas ==================
configurar_alarma:

    call limpiar_pant

    mov dh, 7
    mov dl, 20
    call mover_cursor

    mov si, msg_configurar_alarma
    call imprimir_cadena

    ; Leer HORAS: HH

    call leer_digito
    mov [digito_tmp], al

    call leer_digito

    ; Construir BCD HH
    mov ah, [digito_tmp]
    shl ah, 4
    or al, ah

    mov [hora_tmp], al

    ; Hora maxima valida = 23
    cmp al, 0x23
    ja .error


    ; Mostrar :
    mov si, dos_puntos
    call imprimir_cadena


    ; =====================
    ; Leer MINUTOS: MM
    ; =====================

    call leer_digito
    mov [digito_tmp], al

    call leer_digito

    ; Construir BCD MM
    mov ah, [digito_tmp]
    shl ah, 4
    or al, ah

    mov [minuto_tmp], al

    ; Minuto maximo = 59
    cmp al, 0x59
    ja .error


    ; =====================
    ; Guardar alarma
    ; =====================

    mov al, [hora_tmp]
    mov [alarma_hora], al

    mov al, [minuto_tmp]
    mov [alarma_minuto], al

    mov byte [alarma_activa], 1
    mov byte [alarma_disparada], 0

    ret


.error:
    mov si, msg_error_alarma
    call imprimir_cadena

    ; Esperar cualquier tecla
    xor ah, ah
    int 0x16

    jmp configurar_alarma


revisar_alarma:

    cmp byte [alarma_activa], 1 ; ver si ya hay alarma configurada
    jne .fin

    cmp byte [alarma_disparada], 1 ; ver si ya se activo
    je .fin

    ; Comparar hora
    mov al, [hora_actual]
    cmp al, [alarma_hora]
    jne .fin

    ; Comparar minutos
    mov al, [minuto_actual]
    cmp al, [alarma_minuto]
    jne .fin

    ; Coincidieron los dos
    mov byte [alarma_disparada], 1

    ; Inicializar el parpadeo
    mov ah, 0x00
    int 0x1A
    mov [tick_parpadeo], dx

    ; Empezamos en rojo
    mov byte [estado_parpadeo], 1

    call mostrar_aviso_alarma

.fin:
    ret

cancelar_alarma:
    mov byte [alarma_activa], 0
    mov byte [alarma_disparada], 0
    mov byte [estado_parpadeo], 0

    ret





; ========================= variables =================
alarma_hora:
    db 0

alarma_minuto:
    db 0

alarma_activa:
    db 0

alarma_disparada:
    db 0


; Variables temporales para configurar la alarma
digito_tmp:
    db 0

hora_tmp:
    db 0

minuto_tmp:
    db 0

estado_parpadeo:
    db 0

tick_parpadeo:
    dw 0