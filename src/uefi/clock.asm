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



global alarm_hour
global alarm_minute
global alarm_is_set
global AlarmString

global configure_alarm_time
global update_alarm_string
global reset_alarm
global check_alarm
global stop_alarm





; ==============================================================================
; VARIABLES EXTERNAS
; ==============================================================================

extern SystemTable
extern ConIn 

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



    ; ----------------------------------------------------------
    ; TIEMPO DE LA ALARMA
    ; ----------------------------------------------------------

    alarm_hour   resb 1
    alarm_minute resb 1

    ; Estado:
    ; 0 = alarma desactivada
    ; 1 = alarma configurada
    ; 2 = alarma sonando
    alarm_is_set resb 1

    ; Cadena UTF-16 de la alarma: "HH:MM"
    AlarmString resw 6

    ; Buffer temporal para introducir HHMM
    AlarmInputBuffer resb 4
    AlarmInputIndex  resb 1
    AlarmKeyBuffer   resb 4

    

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

    ; ----  ------------------------------------------------------
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
; FUNCIÓN: pause_chronometer
;
; Guarda el tiempo actual del cronómetro para poder reanudar posteriormente.
; ------------------------------------------------------------------------------

pause_chronometer:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; Comprobar si está corriendo
    ; ----------------------------------------------------------

    cmp byte [chrono_running], 1
    jne .done

    ; ----------------------------------------------------------
    ; Actualizar una última vez antes de pausar
    ; ----------------------------------------------------------

    call update_chronometer

    ; ----------------------------------------------------------
    ; Guardar tiempo acumulado
    ; ----------------------------------------------------------

    mov al, [chrono_hour]
    mov [chrono_elapsed_hour], al

    mov al, [chrono_minute]
    mov [chrono_elapsed_minute], al

    mov al, [chrono_second]
    mov [chrono_elapsed_second], al

    ; ----------------------------------------------------------
    ; Detener cronómetro
    ; ----------------------------------------------------------

    mov byte [chrono_running], 0

.done:
    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: reset_chronometer
; ------------------------------------------------------------------------------

reset_chronometer:

    mov byte [chrono_running], 0
    mov byte [chrono_started], 0

    mov byte [chrono_hour], 0
    mov byte [chrono_minute], 0
    mov byte [chrono_second], 0

    mov byte [chrono_elapsed_hour], 0
    mov byte [chrono_elapsed_minute], 0
    mov byte [chrono_elapsed_second], 0

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

; ==============================================================================
; update_alarm_string
;
; Convierte:
;
;   alarm_hour
;   alarm_minute
;
; en una cadena UTF-16:
;
;   "HH:MM"
; ==============================================================================

update_alarm_string:
    sub rsp, 40

    ; ----------------------------------------------------------
    ; HORAS
    ; ----------------------------------------------------------

    movzx eax, byte [alarm_hour]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decena
    add al, '0'
    movzx eax, al
    mov [AlarmString + 0], ax

    ; Unidad
    add dl, '0'
    movzx edx, dl
    mov [AlarmString + 2], dx

    ; :
    mov word [AlarmString + 4], ':'

    ; ----------------------------------------------------------
    ; MINUTOS
    ; ----------------------------------------------------------

    movzx eax, byte [alarm_minute]

    xor edx, edx
    mov ecx, 10
    div ecx

    ; Decena
    add al, '0'
    movzx eax, al
    mov [AlarmString + 6], ax

    ; Unidad
    add dl, '0'
    movzx edx, dl
    mov [AlarmString + 8], dx

    ; Terminador UTF-16
    mov word [AlarmString + 10], 0

    add rsp, 40
    ret

; ==============================================================================
; reset_alarm
;
; Cancela completamente la alarma.
; ==============================================================================

reset_alarm:
    mov byte [alarm_hour], 0
    mov byte [alarm_minute], 0
    mov byte [alarm_is_set], 0

    call update_alarm_string

    ret

; ==============================================================================
; configure_alarm_time
;
; Recibe 4 dígitos:
;
;     HHMM
;
; Ejemplo:
;
;     0730
;
; Valida:
;
;     HH < 24
;     MM < 60
;
; Retorno:
;
;     RAX = 1 -> configuración válida
;     RAX = 0 -> configuración inválida / cancelada
; ==============================================================================

configure_alarm_time:
    sub rsp, 40
    
    ; La alarma está siendo configurada
    mov byte [alarm_is_set], 3

    ; ----------------------------------------------------------
    ; Inicializar buffer
    ; ----------------------------------------------------------

    mov byte [AlarmInputBuffer + 0], '_'
    mov byte [AlarmInputBuffer + 1], '_'
    mov byte [AlarmInputBuffer + 2], '_'
    mov byte [AlarmInputBuffer + 3], '_'

    mov byte [AlarmInputIndex], 0

.input_loop:

    ; ----------------------------------------------------------
    ; Esperar una tecla
    ; ----------------------------------------------------------

    mov rcx, [ConIn]
    lea rdx, [AlarmKeyBuffer]

    mov rax, [rcx + 0x08]
    call rax

    ; EFI_NOT_READY -> no hay tecla
    cmp rax, 0
    jne .input_loop

    ; ----------------------------------------------------------
    ; Revisar ESC
    ; ----------------------------------------------------------

    mov ax, [AlarmKeyBuffer]

    cmp ax, 0x0017
    je .cancel

    ; ----------------------------------------------------------
    ; Obtener UnicodeChar
    ; ----------------------------------------------------------

    mov ax, [AlarmKeyBuffer + 2]

    ; ----------------------------------------------------------
    ; ¿Es menor que '0'?
    ; ----------------------------------------------------------

    cmp ax, '0'
    jb .input_loop

    ; ----------------------------------------------------------
    ; ¿Es mayor que '9'?
    ; ----------------------------------------------------------

    cmp ax, '9'
    ja .input_loop

    ; ----------------------------------------------------------
    ; Guardar dígito
    ; ----------------------------------------------------------

    movzx ecx, byte [AlarmInputIndex]

    lea rdi, [AlarmInputBuffer]
    add rdi, rcx

    mov [rdi], al

    inc byte [AlarmInputIndex]

    ; ----------------------------------------------------------
    ; ¿Ya tenemos los 4 dígitos?
    ; ----------------------------------------------------------

    cmp byte [AlarmInputIndex], 4
    jb .input_loop

    ; ----------------------------------------------------------
    ; VALIDAR HORA
    ;
    ; HH = buffer[0] * 10 + buffer[1]
    ; ----------------------------------------------------------

    movzx eax, byte [AlarmInputBuffer + 0]
    sub eax, '0'

    imul eax, 10

    movzx edx, byte [AlarmInputBuffer + 1]
    sub edx, '0'

    add eax, edx

    ; HH >= 24 -> inválido
    cmp eax, 24
    jae .invalid

    ; ----------------------------------------------------------
    ; Guardar hora temporalmente
    ; ----------------------------------------------------------

    mov r8d, eax

    ; ----------------------------------------------------------
    ; VALIDAR MINUTO
    ;
    ; MM = buffer[2] * 10 + buffer[3]
    ; ----------------------------------------------------------

    movzx eax, byte [AlarmInputBuffer + 2]
    sub eax, '0'

    imul eax, 10

    movzx edx, byte [AlarmInputBuffer + 3]
    sub edx, '0'

    add eax, edx

    ; MM >= 60 -> inválido
    cmp eax, 60
    jae .invalid

    ; ----------------------------------------------------------
    ; Guardar configuración válida
    ; ----------------------------------------------------------

    mov [alarm_minute], al
    mov [alarm_hour], r8b

    mov byte [alarm_is_set], 1

    call update_alarm_string

    mov eax, 1

    add rsp, 40
    ret

.invalid:

    ; No modificamos la alarma anterior.
    ; Simplemente indicamos que la nueva configuración
    ; no era válida.

    xor eax, eax

    add rsp, 40
    ret

.cancel:

    xor eax, eax

    add rsp, 40
    ret


; ==============================================================================
; check_alarm
;
; Comprueba si la hora actual coincide con la alarma.
;
; Estados:
;
;   0 = desactivada
;   1 = configurada / armada
;   2 = sonando
;
; Retorno:
;
;   RAX = 1 -> la alarma acaba de activarse
;   RAX = 0 -> no ocurrió nada
; ==============================================================================

check_alarm:

    xor eax, eax

    ; ----------------------------------------------------------
    ; Si no está configurada, no hacer nada
    ; ----------------------------------------------------------

    cmp byte [alarm_is_set], 1
    jne .done

    ; ----------------------------------------------------------
    ; Comparar hora
    ; ----------------------------------------------------------

    mov al, [current_hour]
    cmp al, [alarm_hour]
    jne .done

    ; ----------------------------------------------------------
    ; Comparar minuto
    ; ----------------------------------------------------------

    mov al, [current_minute]
    cmp al, [alarm_minute]
    jne .done

    ; ----------------------------------------------------------
    ; HORA COINCIDE
    ; ----------------------------------------------------------

    mov byte [alarm_is_set], 2

    mov eax, 1

.done:
    ret


stop_alarm:
    mov byte [alarm_hour], 0
    mov byte [alarm_minute], 0
    mov byte [alarm_is_set], 0

    call update_alarm_string

    ret