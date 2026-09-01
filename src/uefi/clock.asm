[BITS 64]
default rel

; ==============================================================================
; EXPORTACIONES
; ==============================================================================

global get_time
global update_clock_string
global update_chrono_string
global ClockString
global ChronoString

global current_second
global chrono_running
global chrono_started

global chrono_hour
global chrono_minute
global chrono_second


global start_chronometer
global pause_chronometer
global reset_chronometer
global update_chronometer

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

    
    ; ----------------------------------------------------------
    ; TIEMPO DEL CRONÓMETRO
    ; ----------------------------------------------------------

    chrono_hour   resb 1
    chrono_minute resb 1
    chrono_second resb 1

    ; Cadenas
    ClockString  resw 12
    ChronoString resw 12

    ; Estado
    chrono_running resb 1

    ; Momento en que se inició/reanudó
    chrono_start_hour   resb 1
    chrono_start_minute resb 1
    chrono_start_second resb 1

    ; Tiempo acumulado
    chrono_elapsed_hour   resb 1
    chrono_elapsed_minute resb 1
    chrono_elapsed_second resb 1

    ; Indica si el cronómetro ya fue iniciado alguna vez
    ; 0 = nunca iniciado
    ; 1 = ya iniciado
    chrono_started resb 1

    

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

; ------------------------------------------------------------------------------
; FUNCIÓN: update_chrono_string
;
; Convierte:
;
;   chrono_hour
;   chrono_minute
;   chrono_second
;
; en una cadena UTF-16:
;
;   "HH:MM:SS\0"
; ------------------------------------------------------------------------------

update_chrono_string:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; HORAS
    ; ----------------------------------------------------------

    movzx eax, byte [chrono_hour]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decenas
    add al, '0'
    movzx eax, al
    mov [ChronoString + 0], ax

    ; Unidades
    add dl, '0'
    movzx edx, dl
    mov [ChronoString + 2], dx

    ; ----------------------------------------------------------
    ; :
    ; ----------------------------------------------------------

    mov word [ChronoString + 4], ':'

    ; ----------------------------------------------------------
    ; MINUTOS
    ; ----------------------------------------------------------

    movzx eax, byte [chrono_minute]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decenas
    add al, '0'
    movzx eax, al
    mov [ChronoString + 6], ax

    ; Unidades
    add dl, '0'
    movzx edx, dl
    mov [ChronoString + 8], dx

    ; ----------------------------------------------------------
    ; :
    ; ----------------------------------------------------------

    mov word [ChronoString + 10], ':'

    ; ----------------------------------------------------------
    ; SEGUNDOS
    ; ----------------------------------------------------------

    movzx eax, byte [chrono_second]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decenas
    add al, '0'
    movzx eax, al
    mov [ChronoString + 12], ax

    ; Unidades
    add dl, '0'
    movzx edx, dl
    mov [ChronoString + 14], dx

    ; ----------------------------------------------------------
    ; TERMINADOR UTF-16
    ; ----------------------------------------------------------

    mov word [ChronoString + 16], 0

    add rsp, 40
    ret


; ------------------------------------------------------------------------------
; FUNCIÓN: start_chronometer
;
; Inicia o reanuda el cronómetro.
;
; Si es la primera ejecución:
;     - Inicializa el tiempo acumulado en 00:00:00
;     - Guarda la hora actual como punto de inicio
;
; Si estaba pausado:
;     - Conserva el tiempo acumulado
;     - Guarda la hora actual como nuevo punto de inicio
;
; chrono_running:
;     0 = detenido
;     1 = corriendo
; ------------------------------------------------------------------------------

start_chronometer:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; Comprobar si ya estaba corriendo
    ; ----------------------------------------------------------

    cmp byte [chrono_running], 1
    je .done

    ; ----------------------------------------------------------
    ; Comprobar si es la primera ejecución
    ; ----------------------------------------------------------

    cmp byte [chrono_started], 1
    je .resume

    ; ----------------------------------------------------------
    ; PRIMER INICIO
    ; ----------------------------------------------------------

    mov byte [chrono_elapsed_hour], 0
    mov byte [chrono_elapsed_minute], 0
    mov byte [chrono_elapsed_second], 0

    mov byte [chrono_hour], 0
    mov byte [chrono_minute], 0
    mov byte [chrono_second], 0

    mov byte [chrono_started], 1

.resume:

    ; ----------------------------------------------------------
    ; Obtener la hora actual
    ; ----------------------------------------------------------

    call get_time

    ; ----------------------------------------------------------
    ; Guardar hora actual como punto de inicio
    ; ----------------------------------------------------------

    mov al, [current_hour]
    mov [chrono_start_hour], al

    mov al, [current_minute]
    mov [chrono_start_minute], al

    mov al, [current_second]
    mov [chrono_start_second], al

    ; ----------------------------------------------------------
    ; Marcar cronómetro como corriendo
    ; ----------------------------------------------------------

    mov byte [chrono_running], 1

.done:

    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: update_chronometer
;
; Calcula el tiempo actual del cronómetro.
;
; Tiempo del cronómetro =
;
;   tiempo acumulado
;   +
;   (hora actual - hora de inicio)
;
; Resultado:
;
;   chrono_hour
;   chrono_minute
;   chrono_second
; ------------------------------------------------------------------------------

update_chronometer:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; Obtener hora actual
    ; ----------------------------------------------------------

    call get_time

    ; ----------------------------------------------------------
    ; Convertir HORA ACTUAL a segundos
    ;
    ; segundos = hora * 3600
    ;           + minuto * 60
    ;           + segundo
    ; ----------------------------------------------------------

    movzx rax, byte [current_hour]
    imul rax, 3600

    movzx rcx, byte [current_minute]
    imul rcx, 60
    add rax, rcx

    movzx rcx, byte [current_second]
    add rax, rcx

    ; RAX = segundos actuales del día

    ; ----------------------------------------------------------
    ; Convertir HORA DE INICIO a segundos
    ; ----------------------------------------------------------

    movzx rcx, byte [chrono_start_hour]
    imul rcx, 3600

    movzx rdx, byte [chrono_start_minute]
    imul rdx, 60
    add rcx, rdx

    movzx rdx, byte [chrono_start_second]
    add rcx, rdx

    ; RCX = segundos del día cuando inició

    ; ----------------------------------------------------------
    ; Calcular tiempo transcurrido
    ;
    ; RAX = actual - inicio
    ; ----------------------------------------------------------

    sub rax, rcx

    ; ----------------------------------------------------------
    ; Comprobar si pasamos de medianoche
    ; ----------------------------------------------------------

    cmp rax, 0
    jge .no_midnight

    add rax, 86400

.no_midnight:

    ; ----------------------------------------------------------
    ; Convertir tiempo acumulado a segundos
    ; ----------------------------------------------------------

    movzx rcx, byte [chrono_elapsed_hour]
    imul rcx, 3600

    movzx rdx, byte [chrono_elapsed_minute]
    imul rdx, 60
    add rcx, rdx

    movzx rdx, byte [chrono_elapsed_second]
    add rcx, rdx

    ; RCX = tiempo acumulado

    ; ----------------------------------------------------------
    ; Sumar tiempo acumulado + tiempo actual
    ; ----------------------------------------------------------

    add rax, rcx

    ; RAX = tiempo total del cronómetro en segundos

    ; ----------------------------------------------------------
    ; Convertir segundos totales a HORAS
    ; ----------------------------------------------------------

    xor rdx, rdx
    mov rcx, 3600
    div rcx

    mov [chrono_hour], al

    ; RDX = segundos restantes

    ; ----------------------------------------------------------
    ; Convertir segundos restantes a MINUTOS
    ; ----------------------------------------------------------

    mov rax, rdx

    xor rdx, rdx
    mov rcx, 60
    div rcx

    mov [chrono_minute], al

    ; RDX = segundos restantes

    ; ----------------------------------------------------------
    ; SEGUNDOS
    ; ----------------------------------------------------------

    mov [chrono_second], dl

    add rsp, 40
    ret