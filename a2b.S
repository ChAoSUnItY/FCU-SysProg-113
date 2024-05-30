global _start

%macro pushaq 0
    push rax
    push rcx
    push rdx
    push rbx
    push rbp
    push rsi
    push rdi
%endmacro ; pushaq

%macro popaq 0
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    pop rdx
    pop rcx
    pop rax
%endmacro ; popaq

section .text
_start:
    pushaq
    mov     rbp, rsp
    sub     rsp, 32

    mov     dword [rbp - 4], 0      ; srcIdx
    mov     dword [rbp - 8], 0      ; rulesIdx
    mov     dword [rbp - 12], 0     ; segmentLen
    mov     dword [rbp - 16], 0     ; srcLen
    mov     dword [rbp - 20], 0     ; rulesLen

    ; prompts source string
    mov     rcx, src_input_msg
    call    strlen
    call    puts

    mov     rcx, src
    mov     rdx, 100
    call    gets

    call    strlen
    mov     dword [rbp - 16], edx   ; srcLen = strlen(src)

    ; prompts rule string
    mov     rcx, rul_input_msg
    call    strlen
    call    puts

    mov     rcx, rul
    mov     rdx, 100
    call    gets

    call    strlen
    mov     dword [rbp - 20], edx   ; rulesLen = strlen(rules)

__major_main_loop:
    ; reset states
    mov     dword [rbp - 4], 0      ; srcIdx
    mov     dword [rbp - 8], 0      ; rulesIdx
    mov     dword [rbp - 12], 0     ; segmentLen
__pattern_match_loop:
    ; iteration condition
    mov     ecx, dword [rbp - 4]
    mov     edx, dword [rbp - 16]
    cmp     ecx, edx
    jge     __pattern_match_loop_end
    mov     ecx, dword [rbp - 8]
    mov     edx, dword [rbp - 20]
    cmp     ecx, edx
    jge     __pattern_match_loop_end

    ; pattern matching rule
    mov     ecx, dword [rbp - 4]
    mov     cl, [src + ecx]
    mov     edx, dword [rbp - 8]
    mov     dl, [rul + edx]
    cmp     cl, dl
    jne     __mismatch_character
__match_character:
    inc     dword [rbp - 4]         ; srcIdx
    inc     dword [rbp - 8]         ; rulesIdx
    inc     dword [rbp - 12]        ; segmentLen

    mov     edx, dword [rbp - 8]
    mov     dl, [rul + edx]
    cmp     dl, byte '='
    jne     __pattern_match_loop
__major_replacement:
    ; dword [rbp - 24] is now replaceStartIdx
    inc     dword [rbp - 8]
    mov     ecx, dword [rbp - 4]
    sub     ecx, dword [rbp - 12]
    mov     dword [rbp - 24], ecx   ; reaplceStartIdx
    mov     dword [rbp - 28], 0     ; replacementLen

__copy_replacement:
    mov     edx, dword [rbp - 8]
    mov     dl, [rul + edx]
    cmp     dl, byte ';'
    je      __copy_replacement_end
    cmp     dl, byte 10
    je      __copy_replacement_end
    cmp     dl, byte 0
    je      __copy_replacement_end
    mov     ecx, dword [rbp - 8]
    mov     cl, [rul + ecx]
    mov     edx, dword [rbp - 28]
    mov     [replacement + edx], cl
    inc     dword [rbp - 28]
    inc     dword [rbp - 8]
    jmp     __copy_replacement
__copy_replacement_end:
    mov     edx, dword [rbp - 28]
    mov     [replacement + edx], byte 0

    mov     r9d, dword [rbp - 24]
    mov     r10d, dword [rbp - 12]
    mov     r11d, dword [rbp - 28]
    call    replace_segment
    
    mov     rcx, src
    call    strlen
    mov     dword [rbp - 4], edx    ; update srcLen

    ; reset states
    mov     dword [rbp - 4], 0      ; srcIdx
    mov     dword [rbp - 8], 0      ; rulesIdx
    mov     dword [rbp - 12], 0     ; segmentLen
    jmp     __pattern_match_loop
__mismatch_character:
    mov     ecx, dword [rbp - 12]
    sub     dword [rbp - 4], ecx
    mov     dword [rbp - 12], 0
__skip_rule:
    mov     ecx, dword [rbp - 8]
    mov     edx, dword [rbp - 20]
    cmp     ecx, edx
    jge     __skip_rule_end
    mov     ecx, dword [rbp - 8]
    mov     dl, [rul + ecx]
    cmp     dl, byte ';'
    je      __skip_rule_end
    inc     dword [rbp - 8]
    jmp     __skip_rule
__skip_rule_end:
    inc     dword [rbp - 8]
    mov     ecx, dword [rbp - 8]
    mov     edx, dword [rbp - 20]
    cmp     ecx, edx
    jl      __pattern_match_loop
    inc     dword [rbp - 4]
    mov     dword [rbp - 8], 0
    jmp     __pattern_match_loop
__pattern_match_loop_end:

    mov     ecx, dword [rbp - 4]
    mov     edx, dword [rbp - 16]
    cmp     ecx, edx
    jne     __major_main_loop
__major_main_loop_end:

    mov     rcx, result_msg
    call    strlen
    call    puts

    mov     rcx, src
    call    strlen
    call    puts

    popaq

	call    exit

; replace certain segment in src
; <- [r9d] = startIdx
; <- [r10d] = segmentLen
; <- [r11d] = replacementLen
replace_segment:
    pushaq
    mov     rbp, rsp
    sub     rsp, 24

    mov     dword [rbp - 4], 0      ; srcLen
    mov     dword [rbp - 8], 0      ; i
    mov     dword [rbp - 12], 0     ; segmentLen - replacementLen / replacementLen - segmentLen

    ; initialize variables
    ; srcLen
    mov     rcx, src
    call    strlen
    mov     dword [rbp - 4], edx
    
    cmp     r10d, r11d
    je      __replace_same_length
    cmp     r10d, r11d
    jg      __replace_less_length
    jmp     __replace_more_length
__replace_same_length:
    cmp     dword [rbp - 8], r11d
    jge     __replace_same_length_end
    mov     eax, dword [rbp - 8]
    mov     r8b, byte [replacement + eax]   ; replacement[i]
    add     eax, r9d
    mov     [src + eax], r8b
    inc     dword [rbp - 8]
    jmp     __replace_same_length
__replace_same_length_end:
    jmp     __replacement_end
__replace_less_length:
    ; replacement is shorter than segment
    cmp     dword [rbp - 8], r11d
    jge     __replace_less_length_end
    mov     eax, dword [rbp - 8]
    mov     r8b, byte [replacement + eax]   ; replacement[i]
    add     eax, r9d
    mov     [src + eax], r8b
    inc     dword [rbp - 8]
    jmp     __replace_less_length
__replace_less_length_end:
    ; segmentLen - replacementLen
    mov     eax, r10d
    sub     eax, r11d
    mov     dword [rbp - 12], eax
    ; i = startIdx + replacementLen
    mov     dword [rbp - 8], r9d
    add     dword [rbp - 8], r11d
__shift_remaining_start:
    mov     eax, dword [rbp - 4]
    sub     eax, dword [rbp - 12]
    cmp     dword [rbp - 8], eax
    jge     __shift_remaining_end
    mov     eax, dword [rbp - 8]            ; calculate source idx
    add     eax, dword [rbp - 12]
    mov     r8b, byte [src + eax]
    mov     eax, dword [rbp - 8]
    mov     byte [src + eax], r8b
    inc     dword [rbp - 8]
    jmp     __shift_remaining_start
__shift_remaining_end:
    mov     eax, dword [rbp - 4]
    sub     eax, dword [rbp - 12]
    mov     [src + eax], byte 0
    jmp     __replacement_end
__replace_more_length:
    ; replacement is longer than segment
    ; i = srcLen
    mov     eax, dword [rbp - 4]
    mov     dword [rbp - 8], eax
    ; replacementLen - segmentLen
    mov     eax, r11d
    sub     eax, r10d
    mov     dword [rbp - 12], eax
__replace_more_length_start:
    mov     eax, r9d
    add     eax, r10d
    cmp     dword [rbp - 8], eax
    jl      __replace_more_length_end
    mov     eax, dword [rbp - 8]
    mov     r8b, [src + eax]
    add     eax, dword [rbp - 12]
    mov     [src + eax], r8b
    dec     dword [rbp - 8]
    jmp     __replace_more_length_start
__replace_more_length_end:
    ; i = 0
    mov     dword [rbp - 8], 0
__shift_more_start:
    cmp     dword [rbp - 8], r11d
    jge     __shift_more_end
    mov     eax, dword [rbp - 8]
    mov     r8b, [replacement + eax]
    mov     eax, r9d
    add     eax, dword [rbp - 8]
    mov     [src + eax], r8b
    inc     dword [rbp - 8]
    jmp     __shift_more_start
__shift_more_end:
__replacement_end:
    add     rsp, 24
    popaq
    ret

; prints string
; <- [rcx] = source
; <- [rdx] = length
puts:
    mov     rax, 4      ; write
    mov     rbx, 1      ; stdout
    int     0x80        ; write(stdout, source, strlen(source));
    ret

; reads string
; <- [rcx] = destination
; <- [rdx] = buffer size
gets:
    mov     rax, 3      ; read
    mov     rbx, 0      ; stdin
    int     0x80        ; read(stdin, source, buffer size);
    ret

; exits program
; -> [!]
exit:
    mov	rax, 1 ; exit
	mov	rbx, 0
	int	0x80   ; exit(0)
    ret


; get the length of string
; <- [rcx] = string address
; -> [rdx] = string length
strlen:
    push    rcx
    xor     rdx, rdx
_strlen_next:
    cmp     [rcx], byte 0       ; checks if current byte is null
    jz      _strlen_end
    inc     rcx
    inc     rdx
    jmp     _strlen_next
_strlen_end:
    pop     rcx
    ret


section .data
src_input_msg:  db "Enter src: ", 10, 13, 0
rul_input_msg:  db "Enter replacement rules:", 10, 13, 0
result_msg:     db "Result: ", 10, 13, 0
dbg_msg:        db "DEBUG", 10, 13, 0

section .bss
src:            resb 100
rul:            resb 100
replacement:    resb 100
