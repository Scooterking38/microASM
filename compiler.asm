; compiler_engine.asm - Corrected Extensible Compiler Engine
bits 64
default rel

section .text
global _start
global DllMain

_start:
DllMain:
    sub rsp, 40                 ; Shadow space + stack alignment

    lea rsi, [mock_source]      ; Source code cursor
    lea rdi, [out_buffer]       ; Machine code output destination

.parse_loop:
    mov al, [rsi]
    test al, al
    jz .compilation_done        ; Standard null terminator check
    
    cmp al, 20h                 ; Space
    je .skip_char
    cmp al, 0Ah                 ; Newline
    je .skip_char
    cmp al, 0Dh                 ; Carriage return
    je .skip_char

    ; Match token against the Command Table
    lea rbx, [command_table]

.table_lookup:
    mov rdx, [rbx]              ; Keyword pointer
    test rdx, rdx
    jz .unknown_command         ; Unknown instruction encountered

    call .compare_strings
    test rax, rax
    jnz .match_found

    add rbx, 16                 ; Move to next entry (8 bytes str ptr + 8 bytes fn ptr)
    jmp .table_lookup

.match_found:
    add rsi, rax                ; Advance rsi by the length returned in rax
    mov rcx, [rbx + 8]          ; Load handler function address
    call rcx                    ; Dispatch handler (writes to rdi)
    jmp .parse_loop

.skip_char:
    inc rsi
    jmp .parse_loop

.unknown_command:
    mov al, 0x90                ; Emit NOP on unexpected token
    stosb
    inc rsi                     ; Consume unknown byte to break loop
    jmp .parse_loop

.compilation_done:
    mov al, 0xC3                ; Emit 'ret'
    stosb

    mov eax, 1                  ; Return success
    add rsp, 40
    ret

; --- Helper: Compare string at rsi with rdx ---
; Returns matched string length in rax on match, or 0 on mismatch
.compare_strings:
    push rsi
    push rdx
    xor rcx, rcx                ; Counter for match length

.comp_loop:
    mov al, [rdx]
    test al, al
    jz .match_success           ; Reached end of pattern keyword

    mov byte bl, [rsi]
    cmp al, bl
    jne .match_fail

    inc rsi
    inc rdx
    inc rcx
    jmp .comp_loop

.match_fail:
    pop rdx
    pop rsi
    xor rax, rax
    ret

.match_success:
    pop rdx
    pop rsi
    mov rax, rcx                ; Return length matched
    ret

; =========================================================================
; INSTRUCTION HANDLERS
; =========================================================================

EmitSet:
    ; "set" -> mov rax, 5
    mov ax, 0xB848              ; REX.W + MOV RAX opcode
    stosw
    mov rax, 5                  ; Immediate 64-bit value
    stosq
    ret

EmitAdd:
    ; "add" -> add rax, rbx
    mov al, 0x48                ; REX.W
    stosb
    mov al, 0x01                ; ADD r/m64, r64
    stosb
    mov al, 0xD8                ; ModR/M for rax, rbx
    stosb
    ret

EmitSub:
    ; "sub" -> sub rax, rbx
    mov al, 0x48                ; REX.W
    stosb
    mov al, 0x29                ; SUB r/m64, r64
    stosb
    mov al, 0xD8                ; ModR/M for rax, rbx
    stosb
    ret

; =========================================================================
; DATA SECTIONS
; =========================================================================
section .data
align 8
command_table:
    dq cmd_set, EmitSet
    dq cmd_add, EmitAdd
    dq cmd_sub, EmitSub
    dq 0, 0

cmd_set     db "set", 0
cmd_add     db "add", 0
cmd_sub     db "sub", 0
mock_source db "set add sub", 0

section .bss
align 8
out_buffer  resb 512
