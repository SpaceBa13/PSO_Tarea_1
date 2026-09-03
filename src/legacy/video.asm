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
    db '[E] Empezar cronometro ', 13, 10
    db '[T] Terminar cronometro ', 13, 10
    db '[R] Reiniciar cronometro ', 13, 10
    db '[M] Cambiar de modo ', 13, 10
    db '[A] Alarma ', 13, 10
    db 0

corazones:
    db '+++++++++++++++++++', 13,10
    db 0


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
    mov dl, 0x17    ; columna
    call mover_cursor

    mov si, titulo_reloj   ; copiar a si la cadena de texto a imprimir
    call imprimir_cadena

    ;----- mostrar opciones ----
    mov dh, 0x0F    ; fila
    mov dl, 0x00    ; columna
    call mover_cursor

    mov si, opciones
    call imprimir_cadena



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

    ret