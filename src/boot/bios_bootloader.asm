
org 0x7c00
stackBase                   equ 0x7c00
loaderBase                  equ 0x1000
loaderOffset                equ 0x00
message                     db "Start Boot"
endPos                      db 0

; ========== Floppy Disk FAT12 FileSystem distribution
; sector
; 0   |--------------------------|                           ----|
;     |  Boot sector             |  ................................BPB_RsvdSecCnt: 1
; 1   |--------------------------|  --|                ---|      |
;     |                          |    |                   |      |
;     |  FAT1                    |    |....BPB_FATSz16: 9 |      |
;     |                          |    |                   |      |
; 9   |--------------------------|  --|                   |.........BPB_NumFATs: 2
; 10  |--------------------------|                        |      |
;     |                          |                        |      |
;     |  FAT2                    |                        |      |
;     |                          |                        |      |
; 18  |--------------------------|                     ---|      |
;     :                          :                               |..BPB_TotSec16: 2880
;     :                          :                               |
;     :  root dir                :                               |
;     :                          :                               |
;     :                          :                               |
;     :--------------------------;                               |
;     :                          :                               |
;     :                          :                               |
;     :  Data Region             :                               |
;     :                          :                               |
;     :                          :                               |
; 2879:--------------------------:                           ----|

RootDirSectors              equ 14      ; numbers of sectors which root dir used (BPB_RootEntCnt * 32 + BPB_BytesPerSec – 1) / BPB_Bytes PerSec = (224×32 + 512 – 1) / 512 = 14
SectorNumOfRootDirStart     equ 19      ; BPB_RsvdSecCnt + BPB_FATSz16 * BPB_NumFATs = 1 + 9 * 2 = 19
SectorNumOfFAT1Start        equ 1
SectorBalance               equ 17

jmp short Start
nop
BS_OEMName          db  'MINEboot'
BPB_BytesPerSec     dw  512
BPB_SecPerClus      db  1       ; the numbers of sector per clus
BPB_RsvdSecCnt      dw  1       ; the numbers of reserved sectors
BPB_NumFATs         db  2
BPB_RootEntCnt      dw  224
BPB_TotSec16        dw  2880
BPB_Media           db  0xf0
BPB_FATSz16         dw  9
BPB_SecPerTrk       dw  18
BPB_NumHeads        dw  2
BPB_hiddSec         dd  0
BPB_TotSec32        dd  0
BS_DrvNum           db  0
BS_Reserved1        db  0
BS_BootSig          db  29h
BS_VolID            dd  0
BS_VolLab           db  'boot loader'
BS_FileSysType      db  'FAT12'

Start:
;====== clear screen

mov ax, 0600h
mov bx, 0700h
mov cx, 0
mov dx, 0184fh
int 10h

;======= set focus

mov ax, 0200h
mov bx, 0000h
mov dx, 0000h
int 10h

;====== display message on screen
mov ax, 1301h
mov bx, 000fh
mov dx, 0000h
mov cx, endPos - message
push ax
mov ax, ds
mov es, ax
pop ax
mov bp, stackBase
int 10h

;====== reset floppy
xor ah, ah
xor dl, dl
int 13h

jmp $

;====== read one sector
; AX: the sector index read start 
; CL: Number of sectors read 
; ES:BX Destination buffer address
func_read_one_sec:
    push bp
    mov bp, sp
    sub esp, 2
    mov byte [bp - 2], cl
    push bx
    mov bl, [BPB_SecPerTrk]
    div bl
    inc ah
    mov cl, ah
    mov dh, al
    shr al, l
    mov ch, al
    and dh, 1
    pop bx
    mov dl, [BS_DrvNum]
Label_Go_On_Reading:
    mov ah, 2
    mov al, byte [bp-2]
    int 13h
    jc Label_Go_On_Reading
Label_func_end:
    add esp, 2
    pop bp
    ret

;====== fill the remainder of sector
times 510 - ($-$$) db 0
dw 0xaa55