[BITS 64]

default rel

; ==============================================================================
; EXPORTACIONES
; ==============================================================================
global main_app
global ImageHandle
global SystemTable
global ConOut
global ConIn
global current_mode
global alarm_flash_state

; ==============================================================================
; IMPORTACIONES
; ==============================================================================

; Funciones del reloj
extern get_time
extern update_clock_string

; Variables y cadenas del reloj
extern ClockString
extern current_second

; Funciones de interfaz
extern print_string
extern clear_screen
extern render_ui

; Variables del cronómetro
extern chrono_started
extern chrono_running
extern last_second
extern chrono_hour
extern chrono_minute
extern chrono_second

; Funciones del cronómetro
extern update_chronometer
extern update_chrono_string
extern start_chronometer
extern pause_chronometer
extern reset_chronometer

; Variables de la alarma
extern alarm_is_set
extern alarm_hour
extern alarm_minute
extern AlarmString

; Funciones de la alarma
extern configure_alarm_time
extern update_alarm_string
extern reset_alarm
extern stop_alarm
extern check_alarm

; ==============================================================================
; SECCIÓN DE DATOS INICIALIZADOS
; ==============================================================================
section .data

    ; Mensaje de bienvenida inicial
    msg_welcome dw __utf16__(`=================================\r\n`), \
                   __utf16__(`| RELOJ / CRONOMETRO / ALARMA   |\r\n`), \
                   __utf16__(`|             UEFI              |\r\n`), \
                   __utf16__(`=================================\r\n\r\n`), \
                   __utf16__(`> Presione cualquier tecla para iniciar...\r\n`), 0


; ==============================================================================
; SECCIÓN DE VARIABLES NO INICIALIZADAS (BSS)
; ==============================================================================
section .bss

    ; Identificadores y estructuras principales de UEFI
    ImageHandle resq 1
    SystemTable resq 1
    ConOut      resq 1
    ConIn       resq 1

    ; Buffers de entrada
    KeyBuffer    resb 4
    NumberBuffer resw 3

    ; Modo actual de la aplicación
    ; 0 = RELOJ
    ; 1 = CRONÓMETRO
    ; 2 = ALARMA
    current_mode resb 1

    ; Segundo anterior utilizado para controlar las actualizaciones
    previous_second resb 1

    ; Estado visual de la alarma
    alarm_flash_state resb 1


; ==============================================================================
; SECCIÓN DE CÓDIGO
; ==============================================================================
section .text

; ------------------------------------------------------------------------------
; FUNCIÓN: main_app
;
; Inicializa la aplicación y establece los valores iniciales del reloj,
; cronómetro y alarma.
; ------------------------------------------------------------------------------
main_app:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Limpiar pantalla e imprimir mensaje de bienvenida
    call clear_screen
    lea rcx, [msg_welcome]
    call print_string

    ; Inicializar el modo de la aplicación
    mov byte [current_mode], 0

    ; Forzar la primera actualización del reloj
    mov byte [previous_second], 255

    ; Inicializar el estado del cronómetro
    mov byte [chrono_running], 0
    mov byte [chrono_started], 0

    ; Inicializar el tiempo del cronómetro
    mov byte [chrono_hour], 0
    mov byte [chrono_minute], 0
    mov byte [chrono_second], 0

    ; Inicializar la alarma
    mov byte [alarm_hour], 0
    mov byte [alarm_minute], 0
    mov byte [alarm_is_set], 0

    ; Inicializar las cadenas de la alarma y el cronómetro
    call update_alarm_string
    call update_chrono_string


; Esperar confirmación del usuario
.wait_confirm:
    ; Leer una tecla desde la entrada de UEFI
    mov rcx, [ConIn]
    lea rdx, [KeyBuffer]
    mov rax, [rcx + 0x08]       ; ConIn->ReadKeyStroke
    call rax

    ; Repetir hasta recibir una tecla
    cmp rax, 0                  ; 0 = EFI_SUCCESS
    jne .wait_confirm

    ; Renderizar la interfaz visual interactiva
    call render_ui


; ------------------------------------------------------------------------------
; BUCLE PRINCIPAL
; ------------------------------------------------------------------------------
main_loop:

    ; Obtener la hora actual
    call get_time

    ; Comprobar si la alarma debe activarse
    call check_alarm

    ; RAX = 1 → la alarma acaba de activarse
    ; RAX = 0 → no pasó nada
    cmp eax, 1
    jne .check_second

    ; La alarma acaba de empezar a sonar.
    ; Por ahora no hacemos nada.

.check_second:

    ; Comprobar si cambió el segundo
    mov al, [current_second]

    cmp al, [previous_second]
    je .check_keyboard

    ; Guardar el nuevo segundo
    mov [previous_second], al

    ; Actualizar el estado del parpadeo de la alarma
    cmp byte [alarm_is_set], 2
    jne .no_alarm_flash

    xor byte [alarm_flash_state], 1

.no_alarm_flash:

    ; Actualizar la cadena del reloj
    call update_clock_string

    ; Actualizar el cronómetro si está corriendo
    cmp byte [chrono_running], 1
    jne .no_chronometer

    call update_chronometer
    call update_chrono_string

.no_chronometer:

    ; Actualizar la interfaz
    call render_ui

.check_keyboard:

    ; Comprobar si se presionó una tecla
    mov rcx, [ConIn]
    lea rdx, [KeyBuffer]

    mov rax, [rcx + 0x08]       ; ReadKeyStroke
    call rax

    ; Si no hay tecla, volver al bucle principal
    cmp rax, 0
    jne main_loop


    ; Detectar salida mediante ESC o Q
    mov ax, [KeyBuffer]

    ; ESC
    cmp ax, 0x0017
    je exit_program

    ; Obtener el carácter ingresado
    mov ax, [KeyBuffer + 2]

    ; Q
    cmp ax, 'Q'
    je exit_program

    ; q
    cmp ax, 'q'
    je exit_program


    ; Detectar cambio de modo
    cmp ax, 'M'
    je change_mode

    cmp ax, 'm'
    je change_mode


    ; Comprobar controles del cronómetro
    ; Solo están disponibles en modo CRONÓMETRO
    cmp byte [current_mode], 1
    jne .skip_chrono_controls

    ; Iniciar o pausar el cronómetro
    cmp ax, 'I'
    je chrono_start_pause

    cmp ax, 'i'
    je chrono_start_pause

    ; Reiniciar el cronómetro
    cmp ax, 'R'
    je chrono_reset

    cmp ax, 'r'
    je chrono_reset

.skip_chrono_controls:

    ; Comprobar si la alarma está sonando
    cmp byte [alarm_is_set], 2
    jne alarm_is_not_ringing

    ; Apagar la alarma
    cmp ax, 'A'
    je turn_off_alarm

    cmp ax, 'a'
    je turn_off_alarm

alarm_is_not_ringing:

    ; Comprobar controles de la alarma
    ; Solo están disponibles en modo ALARMA
    cmp byte [current_mode], 2
    jne .skip_alarm_controls

    ; Configurar la alarma
    cmp ax, 'S'
    je alarm_set

    cmp ax, 's'
    je alarm_set

    ; Cancelar la alarma
    cmp ax, 'C'
    je alarm_cancel

    cmp ax, 'c'
    je alarm_cancel

.skip_alarm_controls:

    ; Volver al bucle principal
    jmp main_loop

; ------------------------------------------------------------------------------
; FUNCIÓN: change_mode
;
; Cambia entre los modos RELOJ, CRONÓMETRO y ALARMA.
; ------------------------------------------------------------------------------
change_mode:
    ; Obtener el modo actual y avanzar al siguiente
    mov al, [current_mode]
    inc al

    ; Volver al modo RELOJ después de ALARMA
    cmp al, 3
    jne .save_mode

    xor al, al

.save_mode:
    ; Guardar el nuevo modo
    mov [current_mode], al

    ; Actualizar la interfaz
    call render_ui

    ; Volver al bucle principal
    jmp main_loop

; ------------------------------------------------------------------------------
; FUNCIÓN: chrono_start_pause
;
; Inicia o pausa el cronómetro según su estado actual.
; ------------------------------------------------------------------------------
chrono_start_pause:

    ; Comprobar si el cronómetro está corriendo
    cmp byte [chrono_running], 1
    je .pause

    ; Iniciar o reanudar el cronómetro
    call start_chronometer

    jmp main_loop

.pause:

    ; Pausar el cronómetro
    call pause_chronometer

    jmp main_loop


; ------------------------------------------------------------------------------
; FUNCIÓN: chrono_reset
;
; Reinicia el cronómetro y actualiza su visualización.
; ------------------------------------------------------------------------------
chrono_reset:

    ; Reiniciar el cronómetro
    call reset_chronometer
    call update_chrono_string

    ; Actualizar la interfaz
    call render_ui

    jmp main_loop


; ------------------------------------------------------------------------------
; FUNCIÓN: alarm_set
;
; Configura la hora de la alarma y actualiza su visualización.
; ------------------------------------------------------------------------------
alarm_set:
    ; Indicar que la alarma está siendo configurada
    mov byte [alarm_is_set], 3
    call render_ui

    ; Solicitar y configurar la hora de la alarma
    call configure_alarm_time
    call update_alarm_string

    ; Actualizar la interfaz
    call render_ui

    jmp main_loop

; ------------------------------------------------------------------------------
; FUNCIÓN: alarm_cancel
;
; Cancela la alarma y actualiza su visualización.
; ------------------------------------------------------------------------------
alarm_cancel:
    ; Desactivar la alarma y borrar la hora configurada
    call reset_alarm

    ; Actualizar la cadena de la alarma
    call update_alarm_string

    ; Actualizar la interfaz
    call render_ui

    jmp main_loop

; ------------------------------------------------------------------------------
; FUNCIÓN: turn_off_alarm
;
; Apaga la alarma cuando se encuentra sonando.
; ------------------------------------------------------------------------------
turn_off_alarm:
    ; Comprobar si la alarma está sonando
    cmp byte [alarm_is_set], 2
    jne main_loop

    ; Detener la alarma
    call stop_alarm

    ; Actualizar la interfaz
    call render_ui

    jmp main_loop

; ------------------------------------------------------------------------------
; FUNCIÓN: exit_program
;
; Limpia la pantalla y finaliza la ejecución retornando a UEFI.
; ------------------------------------------------------------------------------
exit_program:
    ; Limpiar la pantalla antes de salir
    call clear_screen

    ; Restaurar la pila
    add rsp, 40

    ; Indicar finalización exitosa
    xor rax, rax

    ret