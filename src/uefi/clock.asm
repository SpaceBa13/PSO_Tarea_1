[BITS 64]
default rel

; ==============================================================================
; EXPORTACIONES
; ==============================================================================

global get_time
global update_clock_string
global ClockString
global current_second

; ==============================================================================
; VARIABLES EXTERNAS
; ==============================================================================

extern SystemTable

; ==============================================================================
; SECCIÓN BSS
; ==============================================================================

section .bss

    ; Buffer utilizado por EFI Runtime Services -> GetTime
    EfiTimeBuffer resb 16

    ; Hora actual obtenida desde UEFI
    current_hour   resb 1
    current_minute resb 1
    current_second resb 1

    ; Cadena UTF-16: "HH:MM:SS\0"
    ClockString resw 12

; ==============================================================================
; SECCIÓN DE CÓDIGO
; ==============================================================================

section .text

; ------------------------------------------------------------------------------
; FUNCIÓN: get_time
;
; Obtiene la hora actual mediante RuntimeServices->GetTime.
;
; Resultado:
;   current_hour
;   current_minute
;   current_second
; ------------------------------------------------------------------------------

get_time:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; Obtener RuntimeServices desde EFI_SYSTEM_TABLE
    ; ----------------------------------------------------------

    mov r8, [SystemTable]
    mov r8, [r8 + 0x58]

    ; ----------------------------------------------------------
    ; Llamar a RuntimeServices->GetTime
    ; ----------------------------------------------------------

    lea rcx, [EfiTimeBuffer]
    xor edx, edx

    mov rax, [r8 + 0x18]
    call rax

    ; ----------------------------------------------------------
    ; Guardar hora, minutos y segundos
    ; ----------------------------------------------------------

    mov al, [EfiTimeBuffer + 0x04]
    mov [current_hour], al

    mov al, [EfiTimeBuffer + 0x05]
    mov [current_minute], al

    mov al, [EfiTimeBuffer + 0x06]
    mov [current_second], al

    add rsp, 40
    ret


; ------------------------------------------------------------------------------
; FUNCIÓN: update_clock_string
;
; Convierte:
;
;   current_hour
;   current_minute
;   current_second
;
; en una cadena UTF-16:
;
;   "HH:MM:SS\0"
; ------------------------------------------------------------------------------

update_clock_string:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; HORAS
    ; ----------------------------------------------------------

    movzx eax, byte [current_hour]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decenas
    add al, '0'
    movzx eax, al
    mov [ClockString + 0], ax

    ; Unidades
    add dl, '0'
    movzx edx, dl
    mov [ClockString + 2], dx

    ; ----------------------------------------------------------
    ; :
    ; ----------------------------------------------------------

    mov word [ClockString + 4], ':'

    ; ----------------------------------------------------------
    ; MINUTOS
    ; ----------------------------------------------------------

    movzx eax, byte [current_minute]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decenas
    add al, '0'
    movzx eax, al
    mov [ClockString + 6], ax

    ; Unidades
    add dl, '0'
    movzx edx, dl
    mov [ClockString + 8], dx

    ; ----------------------------------------------------------
    ; :
    ; ----------------------------------------------------------

    mov word [ClockString + 10], ':'

    ; ----------------------------------------------------------
    ; SEGUNDOS
    ; ----------------------------------------------------------

    movzx eax, byte [current_second]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decenas
    add al, '0'
    movzx eax, al
    mov [ClockString + 12], ax

    ; Unidades
    add dl, '0'
    movzx edx, dl
    mov [ClockString + 14], dx

    ; ----------------------------------------------------------
    ; TERMINADOR UTF-16
    ; ----------------------------------------------------------

    mov word [ClockString + 16], 0

    add rsp, 40
    ret