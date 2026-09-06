;============================== manejo de video =======================
; aqui va a estar todo lo que tenga que ver con mostar cosas en pantalla
; esto ya que diferentes archivos lo tendran que usar 


; ============================ Mensajes ============================
titulo:
    db '=== RELOJ / CRONOMETRO ===', 13, 10
    db 0

opciones:
    db '[Q] Salir ', 13, 10
    db '[M] Cambiar de modo ', 13, 10
    db '[A] Alarma ', 13, 10
    db 0

titulo_reloj:
    db '=== MODO RELOJ ===', 13, 10
    db 0

titulo_cronometro:
    db '=== MODO CRONOMETRO ===', 13, 10
    db 0

opciones_cronometro:
    db '[Q] Salir ', 13, 10
    db '[E] Empezar/Pausar cronometro ', 13, 10
    db '[R] Reiniciar cronometro ', 13, 10
    db '[M] Cambiar de modo ', 13, 10
    db '[A] Alarma ', 13, 10
    db 0

corazones:
    db '+++++++++++++++++++', 13,10
    db 0

dos_puntos:
    db ':', 0

cero:
    db '0', 0

msg_fin:
    db 'Programa finalizado. Puede apagar o reiniciar el equipo.', 0


;============================= Rutinas ===============================
    
imprimir_cadena:
    lodsb
    cmp al, 0
    je .fin

    mov ah, 0x0E
    int 0x10

    jmp imprimir_cadena

.fin:
    ret

limpiar_pant:
    mov ah, 0x06    ; servicio lde limpiar region
    mov al, 0x00    ; 0 = limpiar toda la region

    mov bh, 0x07    ; atributo de color
    mov cx, 0x0000  ; esquina superior izquierda
    mov dx, 0x184F  ; esquina inferior derecha

    int 0x10

    ret

mover_cursor:
    mov ah, 0x02
    mov bh, 0x00
    
    int 0x10

    ret

imprimir_bcd:
    mov dl, al

    ; Primer digito
    shr al, 4
    add al, '0'

    mov ah, 0x0E
    int 0x10

    ; Segundo digito
    mov al, dl
    and al, 00001111b
    add al, '0'

    mov ah, 0x0E
    int 0x10

    ret

mostrar_interfaz_reloj:
    call limpiar_pant

    ;---- mostrar titulo ----
    mov dh, 0x00    ; fila
    mov dl, 0x17    ; columna
    call mover_cursor

    mov si, titulo   ; copiar a si la cadena de texto a imprimir
    call imprimir_cadena

    ;---- mostrar titulo de modo----
    mov dh, 0x03    ; fila
    mov dl, 0x19    ; columna
    call mover_cursor

    mov si, titulo_reloj   ; copiar a si la cadena de texto a imprimir
    call imprimir_cadena

    ;----- mostrar opciones ----
    mov dh, 0x0F    ; fila
    mov dl, 0x00    ; columna
    call mover_cursor

    mov si, opciones
    call imprimir_cadena

    call mostrar_hora
    ret

imprimir_numero:
    push bx

    xor ah, ah ; AX contiene el numero
    mov bl, 10
    div bl   ; AL = cociente, AH = residuo

    
    push ax ; Guardamos ambos resultados temporalmente

    ; ---- imprimir decenas ----
    add al, '0'

    mov ah, 0x0E
    mov bh, 0x00
    int 0x10

    ; Recuperamos cociente y residuo
    pop ax

    ; ---- imprimir unidades ----
    mov al, ah
    add al, '0'

    mov ah, 0x0E
    mov bh, 0x00
    int 0x10

    pop bx
    ret

mostrar_interfaz_cronometro:
    call limpiar_pant

    ;---- mostrar titulo ----
    mov dh, 0x00    ; fila
    mov dl, 0x17    ; columna
    call mover_cursor

    mov si, titulo   ; copiar a si la cadena de texto a imprimir
    call imprimir_cadena

    ;---- mostrar titulo de modo----
    mov dh, 0x03    ; fila
    mov dl, 0x17    ; columna
    call mover_cursor

    mov si, titulo_cronometro   ; copiar a si la cadena de texto a imprimir
    call imprimir_cadena

    ;----- mostrar opciones ----
    mov dh, 0x0F    ; fila
    mov dl, 0x00    ; columna
    call mover_cursor

    mov si, opciones_cronometro
    call imprimir_cadena

    call mostrar_cronometro

    ret

leer_digito:
.esperar:
    ; Esperar tecla
    xor ah, ah
    int 0x16

    ; Validar que sea entre '0' y '9'
    cmp al, '0'
    jb .esperar

    cmp al, '9'
    ja .esperar

    ; Guardar temporalmente el caracter
    push bx
    mov bl, al

    ; Mostrar el digito en pantalla
    mov ah, 0x0E
    xor bh, bh
    int 0x10

    ; Convertir ASCII -> numero
    mov al, bl
    sub al, '0'

    pop bx

    ret

mostrar_aviso_alarma:
    ; Pintar toda la pantalla con fondo rojo
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x4F        ; fondo rojo, texto blanco brillante
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Mostrar mensaje principal
    mov dh, 10
    mov dl, 32
    call mover_cursor

    mov si, msg_alarma
    call imprimir_cadena

    ; Mostrar opcion para cancelar
    mov dh, 12
    mov dl, 29
    call mover_cursor

    mov si, msg_cancelar_alarma
    call imprimir_cadena

    ret


mostrar_mensaje_alarma:
    mov dh, 10
    mov dl, 32
    call mover_cursor

    mov si, msg_alarma
    call imprimir_cadena

    mov dh, 12
    mov dl, 29
    call mover_cursor

    mov si, msg_cancelar_alarma
    call imprimir_cadena

    ret


actualizar_parpadeo_alarma:
    ; Solo hacer algo si la alarma esta sonando
    cmp byte [alarma_disparada], 1
    jne .fin

    ; Leer ticks actuales
    mov ah, 0x00
    int 0x1A

    ; Ver cuantos ticks han pasado
    mov ax, dx
    sub ax, [tick_parpadeo]

    ; Aproximadamente medio segundo
    cmp ax, 9
    jb .fin

    ; Guardar nueva referencia
    mov [tick_parpadeo], dx

    ; Alternar:
    ; 0 -> 1
    ; 1 -> 0
    xor byte [estado_parpadeo], 1

    cmp byte [estado_parpadeo], 1
    je .rojo


.negro:
    mov bh, 0x0F
    jmp .dibujar


.rojo:
    mov bh, 0x4F


.dibujar:
    ; Limpiar/rellenar toda la pantalla con ese atributo
    mov ah, 0x06
    mov al, 0x00
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Como acabamos de limpiar la pantalla,
    ; volvemos a dibujar el mensaje
    call mostrar_mensaje_alarma

.fin:
    ret

redibujar_interfaz_actual:

    cmp byte [modo_actual], 0
    je .reloj

    call mostrar_interfaz_cronometro
    ret

.reloj:
    call mostrar_interfaz_reloj
    ret


