[BITS 64]
default rel

; Exportar funciones y variables
global main_app
global ImageHandle
global SystemTable
global ConOut
global ConIn

extern get_time
extern update_clock_string
extern ClockString

global current_mode

extern print_string
extern clear_screen
extern render_ui


global msg_header_clock
global msg_header_chrono
global msg_header_alarm
global msg_display_top
global msg_display_bottom
global msg_alarm
global msg_controls

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


    ; 0 = RELOJ
    ; 1 = CRONÓMETRO
    ; 2 = ALARMA
    current_mode resb 1
    

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
