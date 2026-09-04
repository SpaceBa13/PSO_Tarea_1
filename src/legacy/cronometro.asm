; ======================== Modo cronometro ==================

; =========== Rutinas ============
revisar_ops_cronometro:
    cmp al, 'e'
    je .cambiar_estado

    cmp al, 'r'
    je .reiniciar_cronometro

    ret

.cambiar_estado:
    xor byte [cronometro_activo], 1

    cmp byte [cronometro_activo], 1
    jne .fin_estado

    ; acaba de iniciar/reanudar
    mov ah, 0x00
    int 0x1A

    mov [tick_anterior], dx

.fin_estado:
    ret

.reiniciar_cronometro:
    mov byte [cronometro_activo], 0 ; pausamos
    mov byte [minutos_c], 0 ; reiniciamos los minutos
    mov byte [segundos_c], 0 ; reiniciamos los segundos
    call mostrar_cronometro
    ret

actualizar_cronometro:
    ; Si esta pausado, no hacer nada
    cmp byte [cronometro_activo], 1
    jne .fin_actc

    ; Leer tick actual
    mov ah, 0x00
    int 0x1A

    mov ax, dx
    sub ax, [tick_anterior] ; ax = tick actual - tick anterior
    
    cmp ax, 18 ; Han pasado aproximadamente 18 ticks?
    jb .fin_actc ; si no dejar todo igual

    inc byte [segundos_c] ; si paso aproximadamente un segundo

    mov [tick_anterior], dx ; guardar nuevo punto de referencia


    ; paso un minuto?
    cmp byte [segundos_c], 60
    jne .mostrar

    inc byte [minutos_c]
    mov byte [segundos_c], 0

.mostrar:
    call mostrar_cronometro

.fin_actc:   
    ret

mostrar_cronometro:
    ; Posicion del cronometro
    mov dh, 5
    mov dl, 30
    call mover_cursor

    ; Minutos
    mov al, [minutos_c]
    call imprimir_numero

    mov si, dos_puntos
    call imprimir_cadena

    ; Segundos
    mov al, [segundos_c]
    call imprimir_numero

    ret


; ==============Variables del reloj================
minutos_c:
    db 0

segundos_c:
    db 0

cronometro_activo:
    db 0

tick_anterior:
    dw 0