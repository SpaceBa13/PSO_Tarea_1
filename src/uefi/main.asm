[BITS 64]
default rel         ; Usar direccionamiento relativo a RIP

global efi_main

; ==============================================================================
; SECCIÓN DE DATOS INICIALIZADOS
; ==============================================================================
section .data
    msg_welcome dw __utf16__(`Bienvenido al Reloj/Cronometro UEFI\r\n`), 0
    msg_confirm dw __utf16__(`Presione cualquier tecla para iniciar...\r\n`), 0

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

efi_main:
    ; 1. Alineación de pila y Shadow Space (Convención Microsoft x64)
    sub rsp, 40

    ; 2. Guardar los parámetros de entrada
    mov [ImageHandle], rcx
    mov [SystemTable], rdx

    ; 3. Extraer punteros desde la EFI_SYSTEM_TABLE
    mov r8, [SystemTable]
    
    ; ConOut está en el offset 0x40
    mov r9, [r8 + 0x40]
    mov [ConOut], r9

    ; ConIn está en el offset 0x30
    mov r9, [r8 + 0x30]
    mov [ConIn], r9

    ; 4. Imprimir el mensaje de bienvenida usando ConOut->OutputString
    mov rcx, [ConOut]           
    lea rdx, [msg_welcome]      
    mov rax, [rcx + 0x08]       
    call rax                    

    ; 5. Imprimir el mensaje de confirmación
    mov rcx, [ConOut]
    lea rdx, [msg_confirm]
    mov rax, [rcx + 0x08]
    call rax

    ; 6. Bucle de espera de tecla (Polling de ConIn->ReadKeyStroke)
wait_key_loop:
    mov rcx, [ConIn]            ; Parámetro 1: Puntero a la interfaz ConIn
    lea rdx, [KeyBuffer]        ; Parámetro 2: Puntero donde se guardará la tecla
    mov rax, [rcx + 0x08]       ; ReadKeyStroke está en el offset 8 de ConIn
    call rax                    ; Ejecutar función de UEFI
    
    cmp rax, 0                  ; EFI_SUCCESS es 0 (indica que se leyó una tecla)
    jne wait_key_loop           ; Si no se ha presionado nada (EFI_NOT_READY), repetir

    ; 7. Finalización limpia (sale una vez presionada la tecla)
    add rsp, 40
    xor rax, rax                ; Retornar 0 (EFI_SUCCESS)
    ret