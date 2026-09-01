[BITS 64]
default rel

global efi_main

; Símbolos definidos en main.asm
extern main_app
extern ImageHandle
extern SystemTable
extern ConOut
extern ConIn

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

    ; 4. Llamar a la lógica principal de la aplicación
    call main_app

    ; 5. Finalización limpia
    add rsp, 40
    xor rax, rax                ; Retornar 0 (EFI_SUCCESS)
    ret