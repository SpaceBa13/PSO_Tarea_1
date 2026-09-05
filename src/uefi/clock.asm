[BITS 64]

default rel

; ==============================================================================
; EXPORTACIONES
; ==============================================================================

; Funciones relacionadas con el reloj
global get_time
global update_clock_string
global update_chrono_string

; Cadenas de texto
global ClockString
global ChronoString

; Variable del reloj
global current_second

; Variables del cronómetro
global chrono_running
global chrono_started
global chrono_hour
global chrono_minute
global chrono_second

; Funciones del cronómetro
global start_chronometer
global pause_chronometer
global reset_chronometer
global update_chronometer

; Variables de la alarma
global alarm_hour
global alarm_minute
global alarm_is_set

; Cadena de texto de la alarma
global AlarmString

; Funciones de la alarma
global configure_alarm_time
global update_alarm_string
global reset_alarm
global check_alarm
global stop_alarm


; ==============================================================================
; VARIABLES EXTERNAS
; ==============================================================================

; Interfaces de entrada y sistema UEFI
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

    ; Variables del tiempo del cronómetro
    chrono_hour   resb 1
    chrono_minute resb 1
    chrono_second resb 1

    ; Cadenas de texto del reloj y cronómetro
    ClockString  resw 12
    ChronoString resw 12

    ; Estado del cronómetro
    chrono_running resb 1

    ; Hora en la que se inició o reanudó el cronómetro
    chrono_start_hour   resb 1
    chrono_start_minute resb 1
    chrono_start_second resb 1

    ; Tiempo acumulado del cronómetro
    chrono_elapsed_hour   resb 1
    chrono_elapsed_minute resb 1
    chrono_elapsed_second resb 1

    ; Indica si el cronómetro ya fue iniciado alguna vez
    ; 0 = nunca iniciado
    ; 1 = ya iniciado
    chrono_started resb 1

    ; Variables del tiempo de la alarma
    alarm_hour   resb 1
    alarm_minute resb 1

    ; Estado de la alarma
    ; 0 = alarma desactivada
    ; 1 = alarma configurada
    ; 2 = alarma sonando
    alarm_is_set resb 1

    ; Cadena UTF-16 de la alarma: "HH:MM"
    AlarmString resw 6

    ; Buffer para introducir la hora de la alarma
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
; ------------------------------------------------------------------------------
get_time:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Obtener RuntimeServices desde EFI_SYSTEM_TABLE
    mov r8, [SystemTable]
    mov r8, [r8 + 0x58]

    ; Preparar parámetros para GetTime
    lea rcx, [EfiTimeBuffer]
    xor edx, edx

    ; Llamar a RuntimeServices->GetTime
    mov rax, [r8 + 0x18]
    call rax

    ; Guardar hora, minutos y segundos
    mov al, [EfiTimeBuffer + 0x04]
    mov [current_hour], al

    mov al, [EfiTimeBuffer + 0x05]
    mov [current_minute], al

    mov al, [EfiTimeBuffer + 0x06]
    mov [current_second], al

    ; Restaurar la pila y retornar
    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: update_clock_string
;
; Convierte la hora actual en una cadena UTF-16 con formato "HH:MM:SS".
; ------------------------------------------------------------------------------
update_clock_string:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; HORAS
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

    ; Separador
    mov word [ClockString + 4], ':'

    ; MINUTOS
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

    ; Separador
    mov word [ClockString + 10], ':'

    ; SEGUNDOS
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

    ; Terminador UTF-16
    mov word [ClockString + 16], 0

    ; Restaurar la pila y retornar
    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: update_chrono_string
;
; Convierte el tiempo del cronómetro en una cadena UTF-16 con formato "HH:MM:SS".
; ------------------------------------------------------------------------------
update_chrono_string:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; HORAS
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

    ; Separador
    mov word [ChronoString + 4], ':'

    ; MINUTOS
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

    ; Separador
    mov word [ChronoString + 10], ':'

    ; SEGUNDOS
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

    ; Terminador UTF-16
    mov word [ChronoString + 16], 0

    ; Restaurar la pila y retornar
    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: pause_chronometer
;
; Guarda el tiempo actual del cronómetro y lo pausa.
; ------------------------------------------------------------------------------
pause_chronometer:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Comprobar si está corriendo
    cmp byte [chrono_running], 1
    jne .done

    ; Actualizar el tiempo antes de pausar
    call update_chronometer

    ; Guardar el tiempo acumulado
    mov al, [chrono_hour]
    mov [chrono_elapsed_hour], al

    mov al, [chrono_minute]
    mov [chrono_elapsed_minute], al

    mov al, [chrono_second]
    mov [chrono_elapsed_second], al

    ; Detener el cronómetro
    mov byte [chrono_running], 0

.done:
    ; Restaurar la pila y retornar
    add rsp, 40
    ret


; ------------------------------------------------------------------------------
; FUNCIÓN: reset_chronometer
;
; Reinicia el cronómetro y borra el tiempo acumulado.
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
; ------------------------------------------------------------------------------
start_chronometer:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Comprobar si ya está corriendo
    cmp byte [chrono_running], 1
    je .done

    ; Comprobar si es la primera ejecución
    cmp byte [chrono_started], 1
    je .resume

    ; Inicializar el tiempo en el primer inicio
    mov byte [chrono_elapsed_hour], 0
    mov byte [chrono_elapsed_minute], 0
    mov byte [chrono_elapsed_second], 0

    mov byte [chrono_hour], 0
    mov byte [chrono_minute], 0
    mov byte [chrono_second], 0

    mov byte [chrono_started], 1

.resume:
    ; Obtener la hora actual
    call get_time

    ; Guardar la hora actual como punto de inicio
    mov al, [current_hour]
    mov [chrono_start_hour], al

    mov al, [current_minute]
    mov [chrono_start_minute], al

    mov al, [current_second]
    mov [chrono_start_second], al

    ; Marcar el cronómetro como corriendo
    mov byte [chrono_running], 1

.done:
    ; Restaurar la pila y retornar
    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: update_chronometer
;
; Calcula y actualiza el tiempo actual del cronómetro.
; ------------------------------------------------------------------------------
update_chronometer:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Obtener la hora actual
    call get_time

    ; Convertir la hora actual a segundos
    movzx rax, byte [current_hour]
    imul rax, 3600

    movzx rcx, byte [current_minute]
    imul rcx, 60
    add rax, rcx

    movzx rcx, byte [current_second]
    add rax, rcx

    ; Convertir la hora de inicio a segundos
    movzx rcx, byte [chrono_start_hour]
    imul rcx, 3600

    movzx rdx, byte [chrono_start_minute]
    imul rdx, 60
    add rcx, rdx

    movzx rdx, byte [chrono_start_second]
    add rcx, rdx

    ; Calcular el tiempo transcurrido
    sub rax, rcx

    ; Ajustar si el cronómetro pasó de medianoche
    cmp rax, 0
    jge .no_midnight

    add rax, 86400

.no_midnight:

    ; Convertir el tiempo acumulado a segundos
    movzx rcx, byte [chrono_elapsed_hour]
    imul rcx, 3600

    movzx rdx, byte [chrono_elapsed_minute]
    imul rdx, 60
    add rcx, rdx

    movzx rdx, byte [chrono_elapsed_second]
    add rcx, rdx

    ; Sumar el tiempo acumulado y el tiempo transcurrido
    add rax, rcx

    ; Convertir segundos totales a horas
    xor rdx, rdx
    mov rcx, 3600
    div rcx

    mov [chrono_hour], al

    ; Convertir segundos restantes a minutos
    mov rax, rdx

    xor rdx, rdx
    mov rcx, 60
    div rcx

    mov [chrono_minute], al

    ; Guardar los segundos restantes
    mov [chrono_second], dl

    ; Restaurar la pila y retornar
    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: update_alarm_string
;
; Convierte la hora de la alarma en una cadena UTF-16 con formato "HH:MM".
; ------------------------------------------------------------------------------
update_alarm_string:
    ; Reservar espacio en la pila
    sub rsp, 40

    ; Convertir las horas a caracteres
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

    ; Separador
    mov word [AlarmString + 4], ':'

    ; Convertir los minutos a caracteres
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

    ; Restaurar la pila y retornar
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

; ------------------------------------------------------------------------------
; FUNCIÓN: configure_alarm_time
;
; Recibe cuatro dígitos, valida la hora y configura la alarma.
; ------------------------------------------------------------------------------
configure_alarm_time:
    ; Reservar espacio en la pila
    sub rsp, 40
    
    ; Indicar que la alarma está siendo configurada
    mov byte [alarm_is_set], 3

    ; Inicializar buffer de entrada
    mov byte [AlarmInputBuffer + 0], '_'
    mov byte [AlarmInputBuffer + 1], '_'
    mov byte [AlarmInputBuffer + 2], '_'
    mov byte [AlarmInputBuffer + 3], '_'

    mov byte [AlarmInputIndex], 0

.input_loop:
    ; Esperar una tecla
    mov rcx, [ConIn]
    lea rdx, [AlarmKeyBuffer]

    mov rax, [rcx + 0x08]
    call rax

    ; EFI_NOT_READY -> no hay tecla
    cmp rax, 0
    jne .input_loop

    ; Comprobar si se presionó ESC
    mov ax, [AlarmKeyBuffer]

    cmp ax, 0x0017
    je .cancel

    ; Obtener UnicodeChar
    mov ax, [AlarmKeyBuffer + 2]

    ; Comprobar si es un dígito
    cmp ax, '0'
    jb .input_loop

    cmp ax, '9'
    ja .input_loop

    ; Guardar dígito en el buffer
    movzx ecx, byte [AlarmInputIndex]

    lea rdi, [AlarmInputBuffer]
    add rdi, rcx

    mov [rdi], al

    inc byte [AlarmInputIndex]

    ; Comprobar si ya se recibieron los cuatro dígitos
    cmp byte [AlarmInputIndex], 4
    jb .input_loop

    ; Validar las horas
    ; HH = buffer[0] * 10 + buffer[1]
    movzx eax, byte [AlarmInputBuffer + 0]
    sub eax, '0'

    imul eax, 10

    movzx edx, byte [AlarmInputBuffer + 1]
    sub edx, '0'

    add eax, edx

    ; HH >= 24 -> inválido
    cmp eax, 24
    jae .invalid

    ; Guardar hora temporalmente
    mov r8d, eax

    ; Validar los minutos
    ; MM = buffer[2] * 10 + buffer[3]
    movzx eax, byte [AlarmInputBuffer + 2]
    sub eax, '0'

    imul eax, 10

    movzx edx, byte [AlarmInputBuffer + 3]
    sub edx, '0'

    add eax, edx

    ; MM >= 60 -> inválido
    cmp eax, 60
    jae .invalid

    ; Guardar configuración válida
    mov [alarm_minute], al
    mov [alarm_hour], r8b

    mov byte [alarm_is_set], 1

    ; Actualizar la cadena de la alarma
    call update_alarm_string

    ; Indicar configuración válida
    mov eax, 1

    add rsp, 40
    ret

.invalid:
    ; Indicar configuración inválida
    xor eax, eax

    add rsp, 40
    ret

.cancel:
    ; Indicar configuración cancelada
    xor eax, eax

    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: stop_alarm
;
; Detiene la alarma y restablece su configuración.
; ------------------------------------------------------------------------------
stop_alarm:
    mov byte [alarm_hour], 0
    mov byte [alarm_minute], 0
    mov byte [alarm_is_set], 0

    ; Actualizar la cadena de la alarma
    call update_alarm_string

    ret

; ------------------------------------------------------------------------------
; FUNCIÓN: check_alarm
;
; Comprueba si la hora actual coincide con la hora configurada de la alarma.
; ------------------------------------------------------------------------------
check_alarm:
    xor eax, eax

    ; Comprobar si la alarma está configurada
    cmp byte [alarm_is_set], 1
    jne .done

    ; Comparar hora
    mov al, [current_hour]
    cmp al, [alarm_hour]
    jne .done

    ; Comparar minuto
    mov al, [current_minute]
    cmp al, [alarm_minute]
    jne .done

    ; Activar la alarma
    mov byte [alarm_is_set], 2

    mov eax, 1

.done:
    ret

