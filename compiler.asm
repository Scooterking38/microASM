; compiler_engine.asm - Extensible, Headerless Compiler Engine (Intel Syntax)
bits 64
section .text
global _start
global DllMain

; Dual-purpose entry point for EXE or rundll32.exe
_start:
DllMain:
    sub rsp, 40                 ; Align stack and create shadow space
    
    lea rsi, [rel mock_source]  ; rsi = pointer to source code to compile
    lea rdi, [rel out_buffer]   ; rdi = pointer to output buffer for machine bytes

.parse_loop:
    ; Skip leading spaces or newlines
    mov al, [rsi]
    test al, al
    jz .compilation_done        ; Null terminator means we are finished
    cmp al, 20h                 ; Space
    je .skip_char
    cmp al, 0Ah                 ; Newline
    je .skip_char
    
    ; Match token against the Command Table
    lea rbx, [rel command_table]

.table_lookup:
    mov rdx, [rbx]              ; Load string pointer from table
    test rdx, rdx
    jz .unknown_command         ; End of table reached without a match
    
    ; Call string comparison helper
    mov r8, rsi                 ; Keep rsi safe during comparison
    call .compare_strings
    test rax, rax
    jnz .match_found
    
    add rbx, 16                 ; Move to next entry in the table (String ptr + Func ptr = 16 bytes)
    jmp .table_lookup

.match_found:
    ; Advance rsi past the length of the matched keyword
    mov rcx, [rbx + 8]          ; Get the function pointer
    call rcx                    ; Execute the command handler
    jmp .parse_loop

.skip_char:
    inc rsi
    jmp .parse_loop

.unknown_command:
    ; If a command fails, emit a safe NOP and break out
    mov al, 0x90
    stosb
    jmp .compilation_done

.compilation_done:
    ; Ensure the code always terminates cleanly with a ret instruction
    mov al, 0xC3                ; 'ret' opcode
    stosb

    ; Return success (1) to the Windows loader
    mov eax, 1
    add rsp, 40
    ret

; --- STRING COMPARISON HELPER ---
.compare_strings:
    ; Compares the string at rsi with string at rdx
    push rsi
    push rdx
.comp_loop:
    mov al, [rdx]
    test al, al
    jz .strings_match           ; Reached end of table keyword safely
    mov cl, [rsi]
    cmp al, cl
    jne .strings_mismatch
    inc rsi
    inc rdx
    jmp .comp_loop
.strings_mismatch:
    pop rdx
    pop rsi
    xor rax, rax
    ret
.strings_match:
    pop rdx
    pop rsi
    ; Calculate length to advance rsi in the main loop
    push rdx
.len_loop:
    mov al, [rdx]
    test al, al
    jz .len_done
    inc rsi                     ; Permanently advance the main source pointer past keyword
    inc rdx
    jmp .len_loop
.len_done:
    pop rdx
    mov rax, 1
    ret

; =========================================================================
; 🚀 LINKING NEW COMMANDS: ADDING HANDLERS IS STEP-BY-STEP HERE
; =========================================================================

EmitSet:
    ; Command: "set rax 5" -> Emits: mov rax, 5 (\x48\xB8\x05\x00\x00\x00\x00\x00\x00\x00)
    ; In a production version, parse rsi to extract the value dynamically.
    mov ax, 0B848h              ; 'mov rax' prefix
    stosw
    mov rax, 5                  ; Extracted immediate value
    stosq
    ret

EmitAdd:
    ; Command: "add rax rbx" -> Emits: add rax, rbx (\x48\x01\xD8)
    mov eax, 0xD80148           ; Little-endian for 48 01 D8
    stosb                       ; Write 48
    shr eax, 8
    stosb                       ; Write 01
    shr eax, 8
    stosb                       ; Write D8
    ret

EmitSub:
    ; Command: "sub rax rbx" -> Emits: sub rax, rbx (\x48\x29\xD8)
    mov eax, 0xD82948           ; Little-endian for 48 29 D8
    stosb
    shr eax, 8
    stosb
    shr eax, 8
    stosb
    ret

; =========================================================================
; 📋 THE CENTRAL COMMAND TABLE
; =========================================================================
section .data
align 8
command_table:
    dq cmd_set, EmitSet
    dq cmd_add, EmitAdd
    dq cmd_sub, EmitSub
    dq 0, 0                     ; Null terminator signals the end of the table

    ; Keyword String Literals
    cmd_set db "set", 0
    cmd_add db "add", 0
    cmd_sub db "sub", 0

    ; Mock inline file data for testing execution flow
    mock_source db "set add sub", 0

section .bss
align 8
    out_buffer resb 512         ; Dest buffer where generated machine code is kept
