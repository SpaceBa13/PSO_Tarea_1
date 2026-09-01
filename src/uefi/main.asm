[BITS 64]
default rel

; Exportar funciones y variables
global main_app
global ImageHandle
global SystemTable
global ConOut
global ConIn
global print_string

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

    ; --- Marco y Estructura de la Pantalla Principal ---
    msg_header  dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                   __utf16__(`|       SISTEMA DE TIEMPO REAL - MODO RELOJ             |\r\n`), \
                   __utf16__(`+-------------------------------------------------------+\r\n\r\n`), 0

    msg_display dw __utf16__(`              +---------------------------+\r\n`), \
                   __utf16__(`              |  HORA ACTUAL:  12:00:00   |\r\n`), \
                   __utf16__(`              +---------------------------+\r\n\r\n`), 0

    msg_alarm   dw __utf16__(`  [ Alarma: DESACTIVADA ( --:-- ) ]\r\n\r\n`), 0

    msg_controls dw __utf16__(`+-------------------------------------------------------+\r\n`), \
                    __utf16__(`| [M] Cambiar Modo | [R] Reiniciar | [A] Config. Alarma |\r\n`), \
                    __utf16__(`| [C] Cancel Alarma| [ESC/Q] Salir                       |\r\n`), \
                    __utf16__(`+-------------------------------------------------------+\r\n`), 0

; ==============================================================================
; SECCIÓN DE VARIABLES NO INICIALIZADAS (BSS)
; ==============================================================================
section .bss
    ImageHandle resq 1
    SystemTable resq 1
    ConOut      resq 1
    ConIn       resq 1
    KeyBuffer   resb 4

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

    ; 4. Bucle principal de la interfaz (Esperando acciones futuras)
.main_loop:
    mov rcx, [ConIn]
    lea rdx, [KeyBuffer]
    mov rax, [rcx + 0x08]
    call rax

    ; Por ahora, si no hay tecla o al presionar cualquier tecla en la interfaz, mantiene la pantalla
    cmp rax, 0
    jne .main_loop

    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; DIBUJAR INTERFAZ GRAFICA DE TEXTO (render_ui)
; ------------------------------------------------------------------------------
render_ui:
    sub rsp, 40

    ; Limpiar pantalla antes de dibujar el panel
    call clear_screen

    ; Dibujar Encabezado
    lea rcx, [msg_header]
    call print_string

    ; Dibujar Despliegue de Tiempo
    lea rcx, [msg_display]
    call print_string

    ; Dibujar Estado de la Alarma
    lea rcx, [msg_alarm]
    call print_string

    ; Dibujar Barra de Controles/Teclas
    lea rcx, [msg_controls]
    call print_string

    add rsp, 40
    ret

; ------------------------------------------------------------------------------
; LIMPIAR PANTALLA (clear_screen)
; Utiliza ConOut->ClearScreen
; Offset de ClearScreen: 0x30
; ------------------------------------------------------------------------------
clear_screen:
    sub rsp, 40

    mov rcx, [ConOut]           ; RCX = EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL*
    mov rax, [rcx + 0x30]       ; RAX = ClearScreen()
    call rax                    ; ClearScreen(ConOut)

    add rsp, 40
    ret
; ------------------------------------------------------------------------------
; IMPRIMIR CADENA UTF-16 (print_string)
; ------------------------------------------------------------------------------
print_string:
    sub rsp, 40

    mov rdx, rcx                ; RDX = Puntero al texto
    mov rcx, [ConOut]           ; RCX = Puntero a ConOut
    mov rax, [rcx + 0x08]       ; Offset 0x08 de ConOut es OutputString
    call rax

    add rsp, 40
    ret