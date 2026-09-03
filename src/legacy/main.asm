; main.asm

bits 16
org 0x8000

jmp start_main

; ============= Mensajes =============

dos_puntos:
    db ':', 0

; ============= Programa =============
start_main:
    call mostrar_interfaz_reloj

    loop_programa:
        call revisar_opciones

        cmp byte [modo_actual], 1
        je modo_cronometro

        call actualizar_reloj
        jmp seguir
        
        modo_cronometro:
            call actualizar_cronometro

        
        seguir:
        hlt

        jmp loop_programa

fin:
    cli
    hlt

;================== rutinas =================

revisar_opciones:
    mov ah, 0x01
    int 0x16

    jz .fin

    xor ah, ah
    int 0x16

    cmp al, 'q'
    je fin              ; cambiarlo para que salga 

    ;cmp al, 'a'
    ;je configurar_alarma

    cmp al, 'm'
    jne .fin

    call cambiar_modo

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

times 1024 - ($ - $$) db 0
