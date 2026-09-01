[BITS 64]
default rel

; Exportar funciones y variables
global main_app
global ImageHandle
global SystemTable
global ConOut
global ConIn
global print_string

; ==============================================================================
; SECCIÓN DE DATOS INICIALIZADOS
; ==============================================================================
section .data
    ; --- Mensaje de Bienvenida Inicial ---
    msg_welcome dw __utf16__(`=================================\r\n`), \
                   __utf16__(`| RELOJ / CRONOMETRO / ALARMA   |\r\n`), \
                   __utf16__(`|             UEFI              |\r\n`), \
                   __utf16__(`=================================\r\n\r\n`), \
                   __utf16__(`> Presione cualquier tecla para iniciar...\r\n`), 0

    msg_header_clock dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                        __utf16__(`|       SISTEMA DE TIEMPO REAL - MODO RELOJ             |\r\n`), \
                        __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_header_chrono dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                         __utf16__(`|    SISTEMA DE TIEMPO REAL - MODO CRONOMETRO          |\r\n`), \
                         __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_header_alarm dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                        __utf16__(`|       SISTEMA DE TIEMPO REAL - MODO ALARMA            |\r\n`), \
                        __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_display_top dw __utf16__(`              +---------------------------+\r\n`), \
                   __utf16__(`              |  HORA ACTUAL:  `), 0

    msg_display_bottom dw __utf16__(`   |\r\n`), \
                        __utf16__(`              +---------------------------+\r\n\r\n`), 0

    msg_alarm   dw __utf16__(`  [ Alarma: DESACTIVADA ( --:-- ) ]\r\n\r\n`), 0

    msg_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                    __utf16__(`| [M] Cambiar Modo | [R] Reiniciar | [A] Config. Alarma |\r\n`), \
                    __utf16__(`| [C] Cancel Alarma| [ESC/Q] Salir                       |\r\n`), \
                    __utf16__(`+-------------------------------------------------------+\r\n`), 0
    msg_colon dw __utf16__(`:`), 0

; ==============================================================================
; SECCIÓN DE VARIABLES NO INICIALIZADAS (BSS)
; ==============================================================================
section .bss
    ImageHandle resq 1
    SystemTable resq 1
    ConOut      resq 1
    ConIn       resq 1
    KeyBuffer   resb 4
    NumberBuffer resw 3

    ClockString resw 12

    ; 0 = RELOJ
    ; 1 = CRONÓMETRO
    ; 2 = ALARMA
    current_mode resb 1
    


    ; Buffer interno de 16 bytes requerido por la función GetTime
    EfiTimeBuffer resb 16

    ; Variables donde se guardará la hora obtenida (1 byte cada una)
    current_hour   resb 1
    current_minute resb 1
    current_second resb 1

; ==============================================================================
; SECCIÓN DE CÓDIGO
; ==============================================================================
section .text

; ------------------------------------------------------------------------------
; LÓGICA PRINCIPAL
; ------------------------------------------------------------------------------
main_app:
    sub rsp, 40

    ; 1. Limpiar pantalla e imprimir Bienvenida
    call clear_screen
    lea rcx, [msg_welcome]
    call print_string

    mov byte [current_mode], 0

    ; 2. Esperar confirmación del usuario (Aceptar cualquier tecla)
.wait_confirm:
    mov rcx, [ConIn]
    lea rdx, [KeyBuffer]
    mov rax, [rcx + 0x08]       ; ConIn->ReadKeyStroke
    call rax
    
    cmp rax, 0                  ; 0 = EFI_SUCCESS
    jne .wait_confirm           ; Repetir hasta recibir una tecla

    ; 3. Renderizar la interfaz visual interactiva
    call render_ui
    
; ------------------------------------------------------------------------------
; BUCLE PRINCIPAL 
; ------------------------------------------------------------------------------
main_loop:
    mov rcx, [ConIn]
    lea rdx, [KeyBuffer]
    mov rax, [rcx + 0x08]       ; ReadKeyStroke
    call rax

    cmp rax, 0                  ; ¿Se presionó una tecla? (EFI_SUCCESS = 0)
    jne main_loop               ; Si no hay tecla, continuar el bucle


    ; --- DETECTAR SALIDA (ESC o 'Q' / 'q') ---
    
    ; 1. Comprobar si presionó la tecla ESC (ScanCode = 0x0017)
    mov ax, [KeyBuffer]         ; ScanCode (Bytes 0 y 1 de KeyBuffer)
    cmp ax, 0x0017              ; 0x0017 = ScanCode para ESC
    je exit_program

    ; 2. Comprobar si presionó 'Q' o 'q' (UnicodeChar = 0x0051 o 0x0071)
    mov ax, [KeyBuffer + 2]     ; UnicodeChar (Bytes 2 y 3 de KeyBuffer)
    cmp ax, 'Q'
    je exit_program
    cmp ax, 'q'
    je exit_program

    ; --- DETECTAR CAMBIO DE MODO (M / m) ---

    mov ax, [KeyBuffer + 2]

    cmp ax, 'M'
    je change_mode

    cmp ax, 'm'
    je change_mode




    jmp main_loop               ; Si fue otra tecla, continuar


; ------------------------------------------------------------------------------
; FUNCIÓN: render_ui
; Dibuja la interfaz dependiendo del modo seleccionado.
;
; current_mode:
;     0 = RELOJ
;     1 = CRONÓMETRO
;     2 = ALARMA
; ------------------------------------------------------------------------------
render_ui:
    sub rsp, 40

    call clear_screen

    ; ----------------------------------------------------------
    ; Mostrar encabezado según el modo
    ; ----------------------------------------------------------
    mov al, [current_mode]

    cmp al, 0
    je .clock_mode

    cmp al, 1
    je .chrono_mode

    cmp al, 2
    je .alarm_mode

.clock_mode:
    lea rcx, [msg_header_clock]
    call print_string
    jmp .display

.chrono_mode:
    lea rcx, [msg_header_chrono]
    call print_string
    jmp .display

.alarm_mode:
    lea rcx, [msg_header_alarm]
    call print_string

.display:

    ; ----------------------------------------------------------
    ; Mostrar reloj
    ; ----------------------------------------------------------
    lea rcx, [msg_display_top]
    call print_string

    call get_time
    call update_clock_string

    lea rcx, [ClockString]
    call print_string

    lea rcx, [msg_display_bottom]
    call print_string

    ; ----------------------------------------------------------
    ; Alarma
    ; ----------------------------------------------------------
    lea rcx, [msg_alarm]
    call print_string

    ; ----------------------------------------------------------
    ; Controles
    ; ----------------------------------------------------------
    lea rcx, [msg_controls]
    call print_string

    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; LIMPIAR PANTALLA (clear_screen)
; Utiliza ConOut->ClearScreen
; Offset de ClearScreen: 0x30
; ------------------------------------------------------------------------------
clear_screen:
    sub rsp, 40

    mov rcx, [ConOut]           ; RCX = EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL*
    mov rax, [rcx + 0x30]       ; RAX = ClearScreen()
    call rax                    ; ClearScreen(ConOut)

    add rsp, 40
    ret
; ------------------------------------------------------------------------------
; IMPRIMIR CADENA UTF-16 (print_string)
; ------------------------------------------------------------------------------
print_string:
    sub rsp, 40

    mov rdx, rcx                ; RDX = Puntero al texto
    mov rcx, [ConOut]           ; RCX = Puntero a ConOut
    mov rax, [rcx + 0x08]       ; Offset 0x08 de ConOut es OutputString
    call rax

    add rsp, 40
    ret



; ------------------------------------------------------------------------------
; FUNCIÓN: get_time
; Obtiene la hora actual mediante RuntimeServices->GetTime y guarda las horas,
; minutos y segundos en las variables correspondientes.
; ------------------------------------------------------------------------------
get_time:
    sub rsp, 40                 ; Reserva de Shadow Space y alineación de pila

    ; ----------------------------------------------------------
    ; 1. OBTENER RUNTIME SERVICES
    ; ----------------------------------------------------------
    mov r8, [SystemTable]        ; Cargar puntero a EFI_SYSTEM_TABLE
    mov r8, [r8 + 0x58]          ; Obtener puntero a RuntimeServices

    ; ----------------------------------------------------------
    ; 2. OBTENER HORA ACTUAL
    ; ----------------------------------------------------------
    lea rcx, [EfiTimeBuffer]     ; RCX = buffer donde se guardará EFI_TIME
    xor edx, edx                 ; RDX = NULL (sin capacidades de tiempo)
    mov rax, [r8 + 0x18]         ; Obtener dirección de GetTime
    call rax                     ; Ejecutar GetTime

    ; ----------------------------------------------------------
    ; 3. GUARDAR HORAS, MINUTOS Y SEGUNDOS
    ; ----------------------------------------------------------
    mov al, [EfiTimeBuffer + 0x04] ; Obtener horas
    mov [current_hour], al

    mov al, [EfiTimeBuffer + 0x05] ; Obtener minutos
    mov [current_minute], al

    mov al, [EfiTimeBuffer + 0x06] ; Obtener segundos
    mov [current_second], al

    add rsp, 40                  ; Restaurar el puntero de la pila
    ret                          ; Retornar a la función llamante



; ------------------------------------------------------------------------------
; FUNCIÓN: update_clock_string
; Convierte los valores numéricos de current_hour, current_minute y current_second
; a una cadena de texto codificada en UTF-16 con el formato: "HH:MM:SS\0"
; ------------------------------------------------------------------------------
update_clock_string:
    sub rsp, 40                 ; Reserva de Shadow Space (32 bytes) + Alineación de pila (8 bytes)

    ; ----------------------------------------------------------
    ; 1. PROCESAR HORAS (HH)
    ; ----------------------------------------------------------
    movzx eax, byte [current_hour] ; Cargar la hora actual (0-23) extendiendo con ceros

    xor edx, edx                ; Limpiar EDX (requerido para la división EDX:EAX / ECX)
    mov ecx, 10                 ; Divisor = 10 para obtener decenas y unidades
    div ecx                     ; EAX = Cociente (Decenas), EDX = Residuo (Unidades)

    ; Convertir decenas a carácter ASCII/UTF-16 y guardar en buffer
    add al, '0'                 ; Convertir valor numérico de decenas a carácter ASCII
    movzx eax, al               ; Extender a 16 bits para UTF-16
    mov [ClockString + 0], ax   ; Guardar carácter de decenas (Bytes 0-1)

    ; Convertir unidades a carácter ASCII/UTF-16 y guardar en buffer
    add dl, '0'                 ; Convertir valor numérico de unidades a carácter ASCII
    movzx edx, dl               ; Extender a 16 bits para UTF-16
    mov [ClockString + 2], dx   ; Guardar carácter de unidades (Bytes 2-3)

    ; ----------------------------------------------------------
    ; 2. AGREGAR PRIMER SEPARADOR (:)
    ; ----------------------------------------------------------
    mov word [ClockString + 4], ':' ; Guardar ':' en formato UTF-16 (Bytes 4-5)

    ; ----------------------------------------------------------
    ; 3. PROCESAR MINUTOS (MM)
    ; ----------------------------------------------------------
    movzx eax, byte [current_minute] ; Cargar los minutos actuales (0-59)

    xor edx, edx                ; Limpiar EDX
    mov ecx, 10                 ; Divisor = 10
    div ecx                     ; EAX = Decenas, EDX = Unidades

    ; Convertir decenas de minutos a UTF-16
    add al, '0'
    movzx eax, al
    mov [ClockString + 6], ax   ; Guardar carácter de decenas (Bytes 6-7)

    ; Convertir unidades de minutos a UTF-16
    add dl, '0'
    movzx edx, dl
    mov [ClockString + 8], dx   ; Guardar carácter de unidades (Bytes 8-9)

    ; ----------------------------------------------------------
    ; 4. AGREGAR SEGUNDO SEPARADOR (:)
    ; ----------------------------------------------------------
    mov word [ClockString + 10], ':' ; Guardar ':' en formato UTF-16 (Bytes 10-11)

    ; ----------------------------------------------------------
    ; 5. PROCESAR SEGUNDOS (SS)
    ; ----------------------------------------------------------
    movzx eax, byte [current_second] ; Cargar los segundos actuales (0-59)

    xor edx, edx                ; Limpiar EDX
    mov ecx, 10                 ; Divisor = 10
    div ecx                     ; EAX = Decenas, EDX = Unidades

    ; Convertir decenas de segundos a UTF-16
    add al, '0'
    movzx eax, al
    mov [ClockString + 12], ax  ; Guardar carácter de decenas (Bytes 12-13)

    ; Convertir unidades de segundos a UTF-16
    add dl, '0'
    movzx edx, dl
    mov [ClockString + 14], dx  ; Guardar carácter de unidades (Bytes 14-15)

    ; ----------------------------------------------------------
    ; 6. TERMINADOR NULO DE CADENA
    ; ----------------------------------------------------------
    mov word [ClockString + 16], 0 ; Agregar nulo UTF-16 (0x0000) para finalizar la cadena (Bytes 16-17)

    add rsp, 40                 ; Restaurar el puntero de la pila
    ret                         ; Retornar a la función llamante


; ------------------------------------------------------------------------------
; FUNCIÓN: change_mode
; Cambia entre los modos RELOJ, CRONÓMETRO y ALARMA.
; ------------------------------------------------------------------------------
change_mode:
    mov al, [current_mode]
    inc al

    cmp al, 3
    jne .save_mode

    xor al, al

.save_mode:
    mov [current_mode], al

    call render_ui

    jmp main_loop




; ------------------------------------------------------------------------------
; FUNCIÓN: exit_program
; Limpia la pantalla, restaura la pila y finaliza la ejecución retornando a UEFI
; ------------------------------------------------------------------------------
exit_program:
    ; 1. (Opcional) Limpiar la pantalla antes de salir
    call clear_screen
    add rsp, 40
    xor rax, rax
    ret
