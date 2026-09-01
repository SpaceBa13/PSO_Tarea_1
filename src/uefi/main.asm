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
extern current_second

global current_mode

extern print_string
extern clear_screen
extern render_ui
extern chrono_started
extern chrono_running
extern last_second


extern update_chronometer
extern update_chrono_string

extern chrono_hour
extern chrono_minute
extern chrono_second

extern start_chronometer
extern pause_chronometer
extern reset_chronometer

extern chrono_running

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

    previous_second resb 1


    

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

    mov byte [previous_second], 255

    mov byte [chrono_running], 0
    mov byte [chrono_started], 0

    mov byte [chrono_hour], 0
    mov byte [chrono_minute], 0
    mov byte [chrono_second], 0

    call update_chrono_string


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

    ; ==========================================================
    ; OBTENER HORA ACTUAL
    ; ==========================================================

    call get_time

    ; ==========================================================
    ; COMPROBAR SI CAMBIÓ EL SEGUNDO
    ; ==========================================================

    mov al, [current_second]

    cmp al, [previous_second]
    je .check_keyboard

    ; ----------------------------------------------------------
    ; Guardar nuevo segundo
    ; ----------------------------------------------------------

    mov [previous_second], al

    ; ----------------------------------------------------------
    ; Actualizar reloj
    ; ----------------------------------------------------------

    call update_clock_string

    ; ----------------------------------------------------------
    ; Actualizar cronómetro si está corriendo
    ; ----------------------------------------------------------

    cmp byte [chrono_running], 1
    jne .no_chronometer

    call update_chronometer
    call update_chrono_string

.no_chronometer:

    ; ----------------------------------------------------------
    ; Actualizar interfaz
    ; ----------------------------------------------------------

    call render_ui



.check_keyboard:

    ; ==========================================================
    ; 2. COMPROBAR TECLADO
    ; ==========================================================

    mov rcx, [ConIn]
    lea rdx, [KeyBuffer]

    mov rax, [rcx + 0x08]       ; ReadKeyStroke
    call rax

    cmp rax, 0
    jne main_loop              ; No hay tecla


    ; ==========================================================
    ; 3. DETECTAR SALIDA
    ; ==========================================================

    ; ESC
    mov ax, [KeyBuffer]
    cmp ax, 0x0017
    je exit_program

    ; Q
    mov ax, [KeyBuffer + 2]
    cmp ax, 'Q'
    je exit_program

    ; q
    cmp ax, 'q'
    je exit_program


    ; ==========================================================
    ; 4. DETECTAR CAMBIO DE MODO
    ; ==========================================================

    cmp ax, 'M'
    je change_mode

    cmp ax, 'm'
    je change_mode


    jmp main_loop

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