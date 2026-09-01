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

extern msg_header_clock
extern msg_header_chrono
extern msg_header_alarm

extern msg_display_top
extern msg_display_bottom
extern msg_alarm
extern msg_controls

extern get_time
extern update_clock_string
extern ClockString

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
    ; Mostrar hora actual
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
    ; Mostrar alarma
    ; ----------------------------------------------------------

    lea rcx, [msg_alarm]
    call print_string

    ; ----------------------------------------------------------
    ; Mostrar controles
    ; ----------------------------------------------------------

    lea rcx, [msg_controls]
    call print_string

    add rsp, 40
    ret