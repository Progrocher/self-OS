use32 
org 0x7E00

_main:
    mov ax, 0x10
    mov fs, ax
    mov ds, ax 
    mov es, ax 
    mov gs, ax 
    push ax
    pop ss
    mov sp, 0x7Bff

.white_screen:
    mov eax, 40 
    mov ecx, 25
    mul ecx 
    mov ecx, 2
    mul ecx
    mov bx, 0x7700
    mov ecx, eax 
    .cycle:
        mov eax, [VideoTextAddr]
        add eax, ecx 
        mov [eax], bx
        cmp ecx, 0 
        je .end
        sub ecx, 2
        jmp .cycle
    .end:

    push Hi_MSG
    mov eax, 13
    push eax 
    mov eax, 11
    push eax
    call print_str

    jmp $
; args: strAddr (4bytes) | xPos(4bytes) | yPos(4bytes)
print_str: 
    push ebp
    mov ebp, esp 
    push ecx
    push edx

    ; calc the CONSOLE_MAX_SIZE
    sub esp, 4 ; ebp-4 = CONSOLE_SIZE = var1
    mov eax, 40 ; columns (X)
    mov ecx, 25 ; rows (Y)
    mul ecx ; 40 * 25
    mov ecx, 2 ; bytes per symbol in console
    mul ecx ; eax = CONSOLE_SIZE
    add eax, [VideoTextAddr] ; 
    mov [ebp-4], eax ; var1 = CONSOLE_SIZE

    ; calc the cursor position in 40x25 console
    mov ecx, [ebp+8]
    mov eax, 40
    mul ecx 
    add eax, dword [ebp+12]
    mov ecx, 2 
    mul ecx  
    add eax, [VideoTextAddr] ; done

    mov ecx, [ebp+16] ; strAddr
    ; output string while cycle not meet 0-terminator
    .while:
        mov edx, [ebp-4] ; edx = MAX_CONSOLE_SIZE
        cmp eax, edx  ; eax = CURRENT_POSITION | edx = MAX_CONSOLE_SIZE
        jnb .err1_print_exit ; if eax >= edx
        push eax ; save current position
        mov al, byte [ecx] ; al = string symbol
        cmp al, 0 ; 
        je .print_exit ; if al == 0
        mov ah, 0xf0 ; ah = symbol color ( ax = color+symbol)
        inc ecx ; *strAddr++; 
        pop edx ; edx = current position 
        mov word [edx], ax
        mov eax, edx 
        add eax, 2
        jmp .while
    
    .err1_print_exit:
        mov eax, 0xffffffff
    .print_exit:
        xor eax, eax
        add esp, 4
        pop edx
        pop ecx
        mov esp, ebp
        pop ebp
    ret

VideoTextAddr dd 0x000B8000
Hi_MSG db "HELLO WORLD!!!",0