;============================== manejo de video =======================
; aqui va a estar todo lo que tenga que ver con mostar cosas en pantalla
; esto ya que diferentes archivos lo tendran que usar 

    
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