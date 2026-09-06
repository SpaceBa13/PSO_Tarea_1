bits 16
org 0x7C00 ; direccion donde se carga el sector de arranque

jmp start

;==================== Mensajes =============
bienvenida:
    db 13, 10 ; esto es un salto de linea jiji
    db '============================', 13, 10
    db ' Reloj/Cronometro con Alarma', 13, 10
    db ' Tarea 1 Sistemas operativos', 13, 10
    db ' Boot Loader con Legacy', 13, 10
    db '============================', 13, 10
    db 13, 10
    db 'Presione ENTER para continuar...', 13, 10
    db 0

entrando:
    db 13, 10
    db 'Entrando al programa...', 13, 10
    db 0

error_disco:
    db 13, 10
    db 'Error leyendo MAIN', 13, 10
    db 0

; =============== Programa ====================
start:
    ; Configuracion de segmentos y pila
    cli                     ; pone en pausa las interrupciones
    xor ax, ax              ; esto hace que ax sea 0
    mov ds, ax              ; ds -> 0
    mov es, ax              ; es -> 0
    mov ss, ax              ; ss -> 0
    mov sp, 0x7C00          ; mueve al stack pointer esa direccion
    sti                     ; habilita las interrupciones

    mov [boot_drive], dl

    mov si, bienvenida      ; cargamos el mensaje a si
    call imprimir_cadena    ; vamos a la rutina

esperar_enter:
    xor ah, ah              ; servicio de la interrupcion
    int 0x16                ; interrupcion de teclado 

    cmp al, 13              ; comparar si llego el enter
    jne esperar_enter       ; si no seguir en loop

    mov si, entrando        
    call imprimir_cadena    ; print de la cadena entrando

    ; inentar pasar al programa principal
    xor ax, ax
    mov es, ax

    mov bx, 0x8000      ; donde se encuentra el programa principal

    mov ah, 0x02        ; funcion BIOS: leer sectores
    mov al, 0x04        ; cantidad: 4 sectores

    mov ch, 0x00        ; cilindro 0
    mov dh, 0x00        ; cabeza 0
    mov cl, 0x02        ; sector 2

    mov dl, [boot_drive] ; paamos otra vez a dl la info del inicio

    int 0x13            ; interrupcion de disco

    jc fallo_disco

    ; main ya esta en 0000:8000
    jmp 0x0000:0x8000


fallo_disco:
    mov si, error_disco
    call imprimir_cadena

fin:
    cli                         ; detener interrupciones
    hlt                         ; detener programa 

; ============== Rutinas ====================

imprimir_cadena:
    lodsb

    cmp al, 0
    je .fin

    mov ah, 0x0E
    int 0x10

    jmp imprimir_cadena

.fin:
    ret

boot_drive:
    db 0

times 510 - ($ - $$) db 0
dw 0xAA55 ;firma de arranque