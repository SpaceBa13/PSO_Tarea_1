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

    ; ==========================================================
    ; ENCABEZADOS DE LOS MODOS
    ; ==========================================================

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

    ; Formato para mostrar la hora actual.
    msg_display_top dw __utf16__(`              +---------------------------+\r\n`), \
                       __utf16__(`              |  HORA ACTUAL:  `), 0

    msg_display_bottom dw __utf16__(`   |\r\n`), \
                           __utf16__(`              +---------------------------+\r\n\r\n`), 0


    ; ==========================================================
    ; CRONÓMETRO
    ; ==========================================================

    ; Formato para mostrar la hora y el tiempo del cronómetro.
    msg_chrono_top dw __utf16__(`              +---------------------------+\r\n`), \
                      __utf16__(`              |  HORA ACTUAL:  `), 0

    msg_chrono_middle dw __utf16__(`\r\n              |  CRONOMETRO:    `), 0

    msg_chrono_bottom dw __utf16__(`\r\n              +---------------------------+\r\n\r\n`), 0

    ; Controles disponibles en el modo cronómetro.
    msg_chrono_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                           __utf16__(`| [I] Iniciar/Pausar | [R] Reiniciar | [M] Cambiar Modo |\r\n`), \
                           __utf16__(`| [ESC/Q] Salir                                         |\r\n`), \
                           __utf16__(`+-------------------------------------------------------+\r\n`), 0


    ; ==========================================================
    ; ALARMA
    ; ==========================================================

    ; Mensaje utilizado para mostrar el estado de la alarma.
    msg_alarm dw __utf16__(`  [ Alarma: DESACTIVADA ( --:-- ) ]\r\n\r\n`), 0


    ; ==========================================================
    ; CONTROLES GENERALES
    ; ==========================================================

    ; Controles disponibles en el modo reloj.
    msg_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                    __utf16__(`| [M] Cambiar Modo | [R] Reiniciar | [A] Config. Alarma |\r\n`), \
                    __utf16__(`| [C] Cancel Alarma| [ESC/Q] Salir                       |\r\n`), \
                    __utf16__(`+-------------------------------------------------------+\r\n`), 0

    ; Controles disponibles en el modo alarma.
    msg_alarm_controls dw   __utf16__(`+-------------------------------------------------------+\r\n`), \
                            __utf16__(`| [M] Cambiar Modo  | [S] Config. Alarma | [A] Apagar   |\r\n`), \
                            __utf16__(`| [C] Cancel Alarma | [ESC/Q] Salir                     |\r\n`), \
                            __utf16__(`+-------------------------------------------------------+\r\n`), 0


    ; Separador utilizado para mostrar horas y minutos.
    msg_colon dw __utf16__(`:`), 0


; ==============================================================================
; SECCIÓN DE CÓDIGO
; ==============================================================================

section .text

; ------------------------------------------------------------------------------
; FUNCIÓN: print_string
;
; Imprime una cadena UTF-16 utilizando ConOut->OutputString.
;
; Entrada:
;     RCX = dirección de la cadena
; ------------------------------------------------------------------------------
print_string:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Preparar parámetros para OutputString
    mov rdx, rcx
    mov rcx, [ConOut]

    ; Llamar a OutputString
    mov rax, [rcx + 0x08]
    call rax

    ; Restaurar la pila
    add rsp, 40
    ret


; ------------------------------------------------------------------------------
; FUNCIÓN: clear_screen
;
; Limpia la pantalla utilizando la función ClearScreen de ConOut.
; ------------------------------------------------------------------------------
clear_screen:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Cargar la interfaz de salida
    mov rcx, [ConOut]

    ; Llamar a ClearScreen
    mov rax, [rcx + 0x30]
    call rax

    ; Restaurar la pila
    add rsp, 40
    ret


; ------------------------------------------------------------------------------
; FUNCIÓN: render_ui
;
; Dibuja la interfaz según el modo seleccionado.
;
; current_mode:
;
;     0 = RELOJ
;     1 = CRONÓMETRO
;     2 = ALARMA
; ------------------------------------------------------------------------------
render_ui:
    sub rsp, 40

    ; Limpiar pantalla
    call clear_screen

    ; Seleccionar modo
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
;
; Muestra el encabezado, la hora actual y los controles.
; ==============================================================
.clock_mode:
    ; Mostrar encabezado
    lea rcx, [msg_header_clock]
    call print_string

    ; Mostrar hora actual
    lea rcx, [msg_display_top]
    call print_string

    lea rcx, [ClockString]
    call print_string

    lea rcx, [msg_display_bottom]
    call print_string

    ; Mostrar controles
    lea rcx, [msg_controls]
    call print_string

    jmp .done

; ==============================================================
; MODO CRONÓMETRO
;
; Muestra la hora actual, el cronómetro y sus controles.
; ==============================================================
.chrono_mode:
    ; Mostrar encabezado
    lea rcx, [msg_header_chrono]
    call print_string

    ; Mostrar hora actual
    lea rcx, [msg_chrono_top]
    call print_string

    lea rcx, [ClockString]
    call print_string

    ; Mostrar cronómetro
    lea rcx, [msg_chrono_middle]
    call print_string

    lea rcx, [ChronoString]
    call print_string

    lea rcx, [msg_chrono_bottom]
    call print_string

    ; Mostrar controles del cronómetro
    lea rcx, [msg_chrono_controls]
    call print_string

    jmp .done


; ==============================================================
; MODO ALARMA
;
; Muestra el encabezado, el estado de la alarma y sus controles.
; ==============================================================
.alarm_mode:
    ; Mostrar encabezado
    lea rcx, [msg_header_alarm]
    call print_string

    ; Mostrar estado de la alarma
    lea rcx, [msg_alarm]
    call print_string

    ; Mostrar controles de la alarma
    lea rcx, [msg_alarm_controls]
    call print_string

    jmp .done


; ==============================================================
; FIN
; ==============================================================

.done:
    ; Restaurar la pila y retornar
    add rsp, 40
    ret