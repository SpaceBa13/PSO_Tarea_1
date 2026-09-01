[BITS 64]
default rel

; ==============================================================================
; EXPORTACIONES
; ==============================================================================

global print_string
global clear_screen
global render_ui



; ==============================================================================
; VARIABLES Y FUNCIONES EXTERNAS
; ==============================================================================

extern ConOut
extern current_mode

extern get_time



extern ClockString
extern ChronoString

; ==============================================================================
; SECCIÓN DE DATOS INICIALIZADOS
; ==============================================================================
section .data

    msg_header_clock dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                        __utf16__(`|       SISTEMA DE TIEMPO REAL - MODO RELOJ             |\r\n`), \
                        __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_header_chrono dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                         __utf16__(`|    SISTEMA DE TIEMPO REAL - MODO CRONOMETRO          |\r\n`), \
                         __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_header_alarm dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                        __utf16__(`|       SISTEMA DE TIEMPO REAL - MODO ALARMA            |\r\n`), \
                        __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0


    ; ==========================================================
    ; RELOJ
    ; ==========================================================

    msg_display_top dw __utf16__(`              +---------------------------+\r\n`), \
                       __utf16__(`              |  HORA ACTUAL:  `), 0

    msg_display_bottom dw __utf16__(`   |\r\n`), \
                           __utf16__(`              +---------------------------+\r\n\r\n`), 0


    ; ==========================================================
    ; CRONÓMETRO
    ; ==========================================================

    msg_chrono_top dw __utf16__(`              +---------------------------+\r\n`), \
                      __utf16__(`              |  HORA ACTUAL:  `), 0

    msg_chrono_middle dw __utf16__(`\r\n              |  CRONOMETRO:    `), 0

    msg_chrono_bottom dw __utf16__(`\r\n              +---------------------------+\r\n\r\n`), 0

    msg_chrono_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                           __utf16__(`| [I] Iniciar/Pausar | [C] Reiniciar | [M] Cambiar Modo |\r\n`), \
                           __utf16__(`| [ESC/Q] Salir                                         |\r\n`), \
                           __utf16__(`+-------------------------------------------------------+\r\n`), 0


    ; ==========================================================
    ; ALARMA
    ; ==========================================================

    msg_alarm dw __utf16__(`  [ Alarma: DESACTIVADA ( --:-- ) ]\r\n\r\n`), 0


    ; ==========================================================
    ; CONTROLES GENERALES
    ; ==========================================================

    msg_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                    __utf16__(`| [M] Cambiar Modo | [R] Reiniciar | [A] Config. Alarma |\r\n`), \
                    __utf16__(`| [C] Cancel Alarma| [ESC/Q] Salir                       |\r\n`), \
                    __utf16__(`+-------------------------------------------------------+\r\n`), 0

    msg_alarm_controls dw   __utf16__(`+-------------------------------------------------------+\r\n`), \
                            __utf16__(`| [M] Cambiar Modo  | [S] Config. Alarma | [A] Apagar   |\r\n`), \
                            __utf16__(`| [C] Cancel Alarma | [ESC/Q] Salir                     |\r\n`), \
                            __utf16__(`+-------------------------------------------------------+\r\n`), 0


    msg_colon dw __utf16__(`:`), 0

    COLOR_NORMAL   equ 0x07
    COLOR_SELECTED equ 0x0E


; ==============================================================================
; SECCIÓN DE CÓDIGO
; ==============================================================================

section .text

; ------------------------------------------------------------------------------
; FUNCIÓN: print_string
;
; Imprime una cadena UTF-16 utilizando:
;
;     ConOut->OutputString
;
; Entrada:
;     RCX = dirección de la cadena
; ------------------------------------------------------------------------------

print_string:
    sub rsp, 40

    mov rdx, rcx
    mov rcx, [ConOut]

    mov rax, [rcx + 0x08]
    call rax

    add rsp, 40
    ret


; ------------------------------------------------------------------------------
; FUNCIÓN: clear_screen
;
; Limpia la pantalla utilizando:
;
;     ConOut->ClearScreen
; ------------------------------------------------------------------------------

clear_screen:
    sub rsp, 40

    mov rcx, [ConOut]

    mov rax, [rcx + 0x30]
    call rax

    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: render_ui
;
; Dibuja la interfaz dependiendo del modo seleccionado.
;
; current_mode:
;
;     0 = RELOJ
;     1 = CRONÓMETRO
;     2 = ALARMA
; ------------------------------------------------------------------------------

render_ui:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; Limpiar pantalla
    ; ----------------------------------------------------------

    call clear_screen

    ; ----------------------------------------------------------
    ; Seleccionar modo
    ; ----------------------------------------------------------

    mov al, [current_mode]

    cmp al, 0
    je .clock_mode

    cmp al, 1
    je .chrono_mode

    cmp al, 2
    je .alarm_mode

    jmp .done


; ==============================================================
; MODO RELOJ
; ==============================================================

.clock_mode:

    lea rcx, [msg_header_clock]
    call print_string

    ; ----------------------------------------------------------
    ; Hora actual
    ; ----------------------------------------------------------

    lea rcx, [msg_display_top]
    call print_string

    lea rcx, [ClockString]
    call print_string

    lea rcx, [msg_display_bottom]
    call print_string

    ; ----------------------------------------------------------
    ; Controles
    ; ----------------------------------------------------------

    lea rcx, [msg_controls]
    call print_string

    jmp .done


; ==============================================================
; MODO CRONÓMETRO
; ==============================================================

.chrono_mode:

    lea rcx, [msg_header_chrono]
    call print_string

    ; ----------------------------------------------------------
    ; Hora actual
    ; ----------------------------------------------------------

    lea rcx, [msg_chrono_top]
    call print_string

    lea rcx, [ClockString]
    call print_string

    ; ----------------------------------------------------------
    ; Cronómetro
    ; ----------------------------------------------------------

    lea rcx, [msg_chrono_middle]
    call print_string

    lea rcx, [ChronoString]
    call print_string

    lea rcx, [msg_chrono_bottom]
    call print_string

    ; ----------------------------------------------------------
    ; Controles del cronómetro
    ; ----------------------------------------------------------

    lea rcx, [msg_chrono_controls]
    call print_string

    jmp .done


; ==============================================================
; MODO ALARMA
; ==============================================================

.alarm_mode:

    lea rcx, [msg_header_alarm]
    call print_string

    ; Aquí agregaremos posteriormente
    ; la interfaz de la alarma.

    lea rcx, [msg_alarm]
    call print_string

    lea rcx, [msg_alarm_controls]
    call print_string

    jmp .done


; ==============================================================
; FIN
; ==============================================================

.done:

    add rsp, 40
    ret


; ------------------------------------------------------------------------------
; FUNCIÓN: set_color
;
; RCX = atributo de color
;
; Utiliza:
;     ConOut->SetAttribute
; ------------------------------------------------------------------------------

set_color:
    sub rsp, 40

    mov rdx, rcx
    mov rcx, [ConOut]

    mov rax, [rcx + 0x20]       ; SetAttribute
    call rax

    add rsp, 40
    ret