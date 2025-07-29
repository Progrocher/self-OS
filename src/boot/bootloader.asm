use16 
org 0x7C00

start:
jmp  boot_entry
nop

; !!!! BPB BLOCK START !!!!
OEM_NAME                db "ASOS2024"
BYTES_PER_SECTOR        dw 0x200
SECTORS_PER_CLUSTER     db 1
RSVD_SECTORS            dw 1
FATS_CNT                db 2
ROOT_DIR_ENTRIES        dw 224
LOW_SECTORS_COUNT       dw 2880
MEDIA_TYPE              db 0xF0
SECTORS_PER_FAT         dw 9
SECTORS_PER_TRACK       dw 18
HEADS_COUNT             db 2
HEADEN_SECTORS          dd 0
HIGHT_SECTOR_COUNT      dd 0
; !!!! BPB BLOCK END !!!!

; !!!! EXTENDED BPB START !!!!
DRIVE_NUMBER            db 0
WIN_RTFLAGS             db 0
BOOT_SIG                db 0x29
VOLUME_ID               dd 0
VOLUME_LABEL            db "AS OS start"
SYS_LABEL               db "FAT12   "
; !!!! EXTENDED BPB END !!!!


; On entry
boot_entry:
    cli ; off interraps
        xor ax, ax ; ax = 0
        mov ds, ax ; ds = ax
        mov es, ax ; es = ax
        mov ss, ax ; ss = ax
        mov sp, 0x7Bff ; sp = 0x7Bff 
    sti ; on interraps
    mov [DRIVE_NUMBER], dl ; dl have the hard-drive index from bios
    jmp 0x0000:main ; jmp main | cs = 0, ip = main
main:
    .clear_screan:
        xor ax, ax ; ax = 0 
        int 10h ; video interrap
    .on_start:
        mov dl, [DRIVE_NUMBER]
    .loadRoot:
        xor ax, ax 
        mov al, [FATS_CNT]
        mov cx, [SECTORS_PER_FAT]
        mul cx    ; dx:ax = FATS_CNT*SECTORS_PER_FAT = size of fat in sectors
        add ax, [RSVD_SECTORS] ; ax =rootDirPos-hideSectors
        add ax, word [HEADEN_SECTORS] ; ax = rootDirPos
        push ax ; save ax
        
        mov ax, [ROOT_DIR_ENTRIES]
        mov cx, 32 
        mul cx ; dx:ax = 32*ROOT_DIR_ENTRIES
        mov cx, [BYTES_PER_SECTOR] ; 512b
        div cx ; ax = (32*ROOT_DIR_ENTRIES):BYTES_PER_SECTOR
        pop cx 
        xchg ax, cx 
        mov bx, 0x0500 ; es:bx = 0x0000:0x0500 | ax = rootDirPos | cx = rootDirSize
        call read_sectors ; read root dir
        
    .find_file:
        mov ax, bx ; mov ax - rootDir max addr in the memory
        mov bx, 0x0500 ; bx = rootDir min addr in the memory
        .check_name:
            mov cx, 10 ; kernel name length
            mov si, sys  ; kernel name pos
            .lp1:
                push bx ; save last position of bx
                add si, cx ; si - symbol position in sys
                add bx, cx ; bx - symbol position in rootDirAddr (bx)
                mov dl, [si] ; dl - symbol from si
                mov dh, [bx] ; dh - symbol from bx
                cmp dl, dh ; check symbols (strcmp)
                pop bx ; recive last position of bx
                jne .next_fn
                mov si, sys ; kernel name pos
                loop .lp1 ; loop while cx > 0
            mov dl, [si] ; check last symbol
            mov dh, [bx] ; check last symbol
            cmp dh, dl ; check last symbol
            jne .next_fn ; if not equal

            mov ax, [bx + 26] ; ax = firstFileClusterAddr
            push ax ; save cluster addr
            .load_fat: ; load fat addr table
                mov ax, [SECTORS_PER_FAT] 
                mov cl, [FATS_CNT]
                mul cl ; ax = FATs size
                mov cx, ax 
                mov ax, [RSVD_SECTORS] 
                mov bx, 0x0500
                call read_sectors ; load FAT table to 0x0000:0x0500 | cx - fats size; ax - fats LBA; bx - load addr
                mov bx, 0x7E00
                .next_Clust:
                    pop si ; si = firstFileClusterAddr or fileNextClusterAddr
                    add si, 0x0500 ; si = file cluster position in FAT table + 1
                    inc si ; si = = file cluster position in FAT table
                    mov ax, [si] ; ax = FAT[fileClusterAddr]
                    sub si, 0x0500
                    test si, 1 ; check odd or even
                    jz .even
                    and ax, 0x0fff ; if odd: to null higth 4 bits
                    jmp .load ; load cluster from disc
                    .even: 
                    and ax, 0xfff0 ; if even: to null low 4 bits
                    shr ax, 4 ; ax >> 4
                .load: ; load file sector
                    push ax ; save next cluster addr
                    sub si, 3 ; cluster addr -> LBA
                    mov ax, [ROOT_DIR_ENTRIES] ; ax = ROOT_DIR_ENTRIES * 32 / 512
                    mov cx, 32 ; /
                    mul cx  ; /
                    mov cx, [BYTES_PER_SECTOR] ; 
                    div cx ; ax = count of sectors for ROOT_DIR
                    push ax ; save ROOT_DIR_SECTORS_CNT
                    mov ax, [SECTORS_PER_FAT] ; ax = FATS_CNT * SECTORS_PER_FAT
                    mov cl, [FATS_CNT]
                    mul cl ; ax = FAT_SIZE
                    add ax, [RSVD_SECTORS] ; ax = FATS + RSVDS
                    add ax, si ; ax = LBA + ax
                    pop cx ; pop ROOT_DIR_SECTORS_CNT
                    add ax, cx ; ax = ax + ROOT_DIR_SECTORS_CNT | READ CLUSER NUM
                    mov cx, 1 ; sectors to read
                    call read_sectors ; read file sector
                    pop ax ; pop NextFileClustAddr
                    cmp ax, 0x0ff7 ; cmp to last cluster
                    mov si, ax ; si = NextFileClustAddr
                    jc .next_Clust ; if not endClust 
            .start_kernel: ; startup kernel 
                cli  ; off interraps
                xor eax, eax ; eax = 0
                mov ax, ds ; ax = ds (0)
                shl eax, 4 ; ax << 4
                add eax, START_gdt ; ax = ds << 4 + START_gdt
                mov [GDTR_+2], eax ; save gdt linear addr
                mov eax, END_gdt 
                sub eax, START_gdt ; eax = gdt_end - gdt_start /|\ gdt_start
                mov [GDTR_], ax ; save gdt_size
                lgdt [GDTR_] ; load gdt

                mov eax, cr0 ; go to 32bit mode
                or al, 1 ; cr0 last byte on
                mov cr0, eax ; 32 bit mode - turn on

                jmp 08h:0x7E00
            .next_fn: 
                cmp ax, bx 
                jb _err
                add bx, 32 
                jmp .check_name
_end:
    jmp $

;ax = lba
;es:bx = read data start addr (in)
;cx = count of sectors to read
read_sectors:

    .read_loop:
        push cx 
        call read_sector
        inc ax 
        add bx, [BYTES_PER_SECTOR]
        pop cx 
        loop .read_loop
    ret

; ax = lba
; es:bx = read data start addr (in)
read_sector:
    .LBA_to_CHS: ; linear sector address to  address of cylinder, head and sector
    ; s = (LBA % SECTORS_PER_TRACK) + 1
    ; h = ((LBA - (s-1)) / SECTORS_PER_TRACK) % HEADS_COUNT
    ; c = ( (LBA - (s-1) - h*S) / (HEADS_COUNT*SECTORS_PER_TRACK) )
        push ax ; save ax
        push ax ; save ax
        xor dx, dx  ; find 's'
        mov cx, [SECTORS_PER_TRACK]
        div cx 
        pop ax ; ret ax value
        inc dx
        mov [sector], dx ; sector = (s-1)
        dec dx 
        
        sub ax, dx ; ax = LBA - (s-1)
        push ax ; save ax 
        xor dx, dx
        mov cx, [SECTORS_PER_TRACK]
        div cx ; ax = ((LBA - (s-1)) / SECTORS_PER_TRACK) 
        mov cl, [HEADS_COUNT]
        div cl 
        mov [head], ah ; head = h

        xor ah, ah ; cylinder = c
        mov cx, [SECTORS_PER_TRACK]
        mul cx ; ax = h * SECTORS_PER_TRACK
        pop cx ; ax value to cx = ( LBA - (s-1))
        sub cx, ax ; cx = (LBA - (s-1) - h*SECTORS_PER_TRACK)
        push cx ; save cx
        mov ax, [SECTORS_PER_TRACK]
        mov cl, [HEADS_COUNT]
        mul cl ; ax = SECTORS_PER_TRACK * HEADS_COUNT
        
        mov cx, ax 
        pop ax 
        xor dx, dx 
        div cx  ; c = cylinder
    .read: 
        mov dl, [DRIVE_NUMBER]
        mov dh, [head]
        mov cx, ax 
        shl cx, 6
        or cx, [sector]
        mov ax, 0x0201
        int 13h
        jb _err
        pop ax
    ret

_err:
    push ax 
    push bx 
    mov ax, 0x0E45
    mov bx, 0x0007
    int 10h
    pop bx
    pop ax
    jmp _end
sector dw 0
head db 0
sys db "SYSTEM16BIN"

START_gdt:
    .null   dq 0
    .Kcode  dq 0x00CF9A000000ffff
    .Kdata  dq 0x00CF92000000ffff
END_gdt:

GDTR_:
    dw 0
    dd 0 
finish:
    times 0x200-finish+start-2 db 0
    db 0x55, 0xAA