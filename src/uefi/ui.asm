[BITS 64]

default rel

; ==============================================================================
; EXPORTACIONES
; ==============================================================================

; Funciones de salida y visualización
global print_string
global clear_screen
global render_ui


; ==============================================================================
; VARIABLES Y FUNCIONES EXTERNAS
; ==============================================================================

; Interfaz de salida de UEFI
extern ConOut

; Estado de la interfaz
extern current_mode
extern alarm_is_set
extern alarm_flash_state

; Funciones del reloj
extern get_time

; Cadenas de texto
extern ClockString
extern ChronoString
extern AlarmString

; ==============================================================================
; SECCIÓN DE DATOS INICIALIZADOS
; ==============================================================================
section .data

    ; Encabezados de los modos
    msg_header_clock dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                        __utf16__(`|       SISTEMA DE TIEMPO REAL - MODO RELOJ             |\r\n`), \
                        __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_header_chrono dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                         __utf16__(`|    SISTEMA DE TIEMPO REAL - MODO CRONOMETRO           |\r\n`), \
                         __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_header_alarm dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                        __utf16__(`|       SISTEMA DE TIEMPO REAL - MODO ALARMA            |\r\n`), \
                        __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0


    ; Formato de visualización del reloj
    msg_display_top dw __utf16__(`              +---------------------------+\r\n`), \
                       __utf16__(`              |  HORA ACTUAL:  `), 0

    msg_display_bottom dw __utf16__(`   |\r\n`), \
                           __utf16__(`              +---------------------------+\r\n\r\n`), 0


    ; Formato de visualización del cronómetro
    msg_chrono_top dw __utf16__(`              +---------------------------+\r\n`), \
                      __utf16__(`              |  HORA ACTUAL:  `), 0

    msg_chrono_middle dw __utf16__(`\r\n              |  CRONOMETRO:    `), 0

    msg_chrono_bottom dw __utf16__(`\r\n              +---------------------------+\r\n\r\n`), 0

    ; Controles disponibles en el modo cronómetro
    msg_chrono_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                           __utf16__(`|         [I] Iniciar/Pausar |   [R] Reiniciar          |\r\n`), \
                           __utf16__(`|         [M] Cambiar Modo   |   [ESC/Q] Salir          |\r\n`), \
                           __utf16__(`+-------------------------------------------------------+\r\n`), 0


    ; Mensajes de estado de la alarma
    msg_alarm_off dw __utf16__(`  [ Alarma: DESACTIVADA ( `), 0

    msg_alarm_on dw __utf16__(`  [ Alarma: CONFIGURADA  ( `), 0

    msg_alarm_input dw __utf16__(`  [ Alarma: CONFIGURANDO ( `), 0

    msg_alarm_end dw __utf16__(` ) ]\r\n\r\n`), 0


    ; Mensajes mostrados mientras la alarma está sonando
    msg_alarm_ringing_top dw \
        __utf16__(`+-------------------------------------------------------+\r\n`), \
        __utf16__(`|                                                       |\r\n`), \
        __utf16__(`|                    !!! ALARMA !!!                     |\r\n`), \
        __utf16__(`|                                                       |\r\n`), \
        __utf16__(`|               LA ALARMA ESTA SONANDO                  |\r\n`), \
        __utf16__(`|                                                       |\r\n`), \
        __utf16__(`|                       `), 0

    msg_alarm_ringing_bottom dw \
        __utf16__(`                           |\r\n`), \
        __utf16__(`|                                                       |\r\n`), \
        __utf16__(`|                  [A] Apagar alarma                    |\r\n`), \
        __utf16__(`|                                                       |\r\n`), \
        __utf16__(`+-------------------------------------------------------+\r\n`), 0


    ; Controles generales de la aplicación
    msg_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                    __utf16__(`|          [M] Cambiar Modo   |   [R] Reiniciar         |\r\n`), \
                    __utf16__(`|          [C] Cancel Alarma  |   [ESC/Q] Salir         |\r\n`), \
                    __utf16__(`+-------------------------------------------------------+\r\n`), 0

    ; Controles disponibles en el modo alarma
    msg_alarm_controls dw   __utf16__(`+-------------------------------------------------------+\r\n`), \
                            __utf16__(`| [M] Cambiar Modo  | [S] Config. Alarma | [A] Apagar   |\r\n`), \
                            __utf16__(`| [C] Cancel Alarma | [ESC/Q] Salir                     |\r\n`), \
                            __utf16__(`+-------------------------------------------------------+\r\n`), 0

    ; Separador utilizado para mostrar horas y minutos
    msg_colon dw __utf16__(`:`), 0

; ==============================================================================
; SECCIÓN DE CÓDIGO
; ==============================================================================
section .text

; ------------------------------------------------------------------------------
; FUNCIÓN: print_string
;
; Imprime una cadena UTF-16 utilizando ConOut->OutputString.
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

    ; Restaurar la pila y retornar
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

    ; Restaurar la pila y retornar
    add rsp, 40
    ret
; ------------------------------------------------------------------------------
; FUNCIÓN: render_ui
;
; Dibuja la interfaz según el modo seleccionado.
;
; current_mode:
;     0 = RELOJ
;     1 = CRONÓMETRO
;     2 = ALARMA
; ------------------------------------------------------------------------------
render_ui:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Limpiar pantalla
    call clear_screen

    ; Comprobar si la alarma está sonando
    movzx ebx, byte [alarm_is_set]

    cmp ebx, 2
    je .alarm_ringing

    ; Seleccionar la interfaz según el modo actual
    mov al, [current_mode]

    cmp al, 0
    je .clock_mode

    cmp al, 1
    je .chrono_mode

    cmp al, 2
    je .alarm_mode

    jmp .done


; ------------------------------------------------------------------------------
; MODO RELOJ
;
; Muestra el encabezado, la hora actual y los controles.
; ------------------------------------------------------------------------------
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


; ------------------------------------------------------------------------------
; MODO CRONÓMETRO
;
; Muestra la hora actual, el cronómetro y sus controles.
; ------------------------------------------------------------------------------
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


; ------------------------------------------------------------------------------
; MODO ALARMA
;
; Muestra el estado y la hora configurada de la alarma.
; ------------------------------------------------------------------------------
.alarm_mode:
    ; Mostrar encabezado
    lea rcx, [msg_header_alarm]
    call print_string

    ; Guardar el estado actual de la alarma
    movzx ebx, byte [alarm_is_set]

    ; Mostrar el reloj si no se está configurando la alarma
    cmp ebx, 3
    je .skip_print_clock

    lea rcx, [msg_display_top]
    call print_string

    lea rcx, [ClockString]
    call print_string

    lea rcx, [msg_display_bottom]
    call print_string

    ; Seleccionar el mensaje según el estado de la alarma
    cmp ebx, 0
    je .alarm_off

    cmp ebx, 1
    je .alarm_configured

    cmp ebx, 2
    je .alarm_ringing


.skip_print_clock:

    ; Comprobar si la alarma está siendo configurada
    cmp ebx, 3
    je .alarm_input

    jmp .alarm_off


.alarm_off:
    ; Mostrar alarma desactivada
    lea rcx, [msg_alarm_off]
    call print_string

    jmp .show_alarm_time


.alarm_configured:
    ; Mostrar alarma configurada
    lea rcx, [msg_alarm_on]
    call print_string

    jmp .show_alarm_time


.alarm_input:
    ; Mostrar entrada de configuración
    lea rcx, [msg_alarm_input]
    call print_string

    jmp .show_alarm_time


.alarm_ringing:

    ; Seleccionar el color según el estado de parpadeo
    cmp byte [alarm_flash_state], 0
    je .alarm_color_1

    ; Establecer color rojo claro
    mov rcx, 0x0C
    call set_color

    jmp .print_alarm_ringing


.alarm_color_1:

    ; Establecer color amarillo
    mov rcx, 0x0E
    call set_color


.print_alarm_ringing:

    ; Mostrar mensaje de alarma sonando
    lea rcx, [msg_alarm_ringing_top]
    call print_string

    lea rcx, [AlarmString]
    call print_string

    lea rcx, [msg_alarm_ringing_bottom]
    call print_string

    ; Restaurar color normal
    mov rcx, 0x07
    call set_color

    jmp .done


.show_alarm_time:
    ; Mostrar hora configurada
    lea rcx, [AlarmString]
    call print_string

    ; Cerrar la línea
    lea rcx, [msg_alarm_end]
    call print_string

    ; Mostrar controles de la alarma
    lea rcx, [msg_alarm_controls]
    call print_string

    jmp .done

; ------------------------------------------------------------------------------
; FIN DE render_ui
; ------------------------------------------------------------------------------
.done:
    ; Restaurar la pila y retornar
    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: set_color
;
; Cambia el color de texto de la consola UEFI.
; ------------------------------------------------------------------------------
set_color:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Preparar parámetros para SetAttribute
    mov rdx, rcx
    mov rcx, [ConOut]

    ; Llamar a SetAttribute
    mov rax, [rcx + 0x28]
    call rax

    ; Restaurar la pila y retornar
    add rsp, 40
    ret