; main.asm

bits 16
org 0x8000

jmp start_main


; ============= Programa =============
start_main:
    call mostrar_interfaz_reloj

    loop_programa:

    call revisar_opciones ; Revisar teclado

    call leer_hora_sistema  ; Mantener actualizada la hora real

    call actualizar_cronometro

    ; Siempre comprobar la alarma
    call revisar_alarma
    call actualizar_parpadeo_alarma


    ; Si la alarma esta mostrandose no redibujar encima
    cmp byte [alarma_disparada], 1
    je .esperar
    

    ; Mostrar reloj solamente si estamos en modo reloj
    cmp byte [modo_actual], 0
    jne .esperar

    call actualizar_reloj

    .esperar:
        hlt
        jmp loop_programa

fin:
    ; Limpiar pantalla
    call limpiar_pant

    ; Mostrar mensaje
    mov dh, 12
    mov dl, 14
    call mover_cursor

    mov si, msg_fin
    call imprimir_cadena

    ; Ya no queremos interrupciones
    cli

.detener:
    hlt
    jmp .detener

;================== rutinas =================

revisar_opciones:
    mov ah, 0x01
    int 0x16

    jz .fin

    xor ah, ah
    int 0x16

    cmp al, 'q'
    je fin

    cmp al, 'c'
    je .cancelar

    cmp byte [alarma_disparada], 1
    je .fin

    cmp al, 'a'
    je .configurar

    cmp byte [modo_actual], 1
    jne .comp_modo

    call revisar_ops_cronometro

.comp_modo:
    cmp al, 'm'
    jne .fin

    call cambiar_modo

    jmp .fin

.configurar:
    call configurar_alarma
    call redibujar_interfaz_actual
    ret


.cancelar:
    call cancelar_alarma
    call redibujar_interfaz_actual
    ret

.fin:
    ret

cambiar_modo:
    xor byte [modo_actual], 1 ;cambiamos el modo 

    cmp byte [modo_actual], 0
    je .interfaz_reloj

    call mostrar_interfaz_cronometro
    ret

.interfaz_reloj:
    call mostrar_interfaz_reloj
    ret

; ================= variables ===================
modo_actual:
    db 0

;================== rutinas externas =================

%include "video.asm"
%include "reloj.asm"
%include "cronometro.asm"
%include "alarma.asm"

times 2048 - ($ - $$) db 0
