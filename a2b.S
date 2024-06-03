global _start

; pushes all registers in 64-bits
%macro pushaq 0
    push rax
    push rcx
    push rdx
    push rbx
    push rbp
    push rsi
    push rdi
%endmacro ; pushaq

; pops all registers in 64-bits
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
    mov     rbp, rsp                ; preserves stack frame with 32 bits
    sub     rsp, 32                 ; since there are 7 4-bits variables used

    mov     dword [rbp - 4], 0      ; declares variable srcIdx
    mov     dword [rbp - 8], 0      ; declares variable rulesIdx
    mov     dword [rbp - 12], 0     ; declares variable segmentLen
    mov     dword [rbp - 16], 0     ; declares variable srcLen
    mov     dword [rbp - 20], 0     ; declares variable rulesLen

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
    mov     ecx, [rbp - 4]
    mov     edx, [rbp - 16]
    cmp     ecx, edx
    jge     __pattern_match_loop_end
    mov     ecx, [rbp - 8]
    mov     edx, [rbp - 20]
    cmp     ecx, edx
    jge     __pattern_match_loop_end

    ; pattern matching rule
    mov     ecx, [rbp - 4]
    mov     cl, [src + ecx]
    mov     edx, [rbp - 8]
    mov     dl, [rul + edx]
    cmp     cl, dl
    jne     __mismatch_character
__match_character:
    inc     dword [rbp - 4]         ; srcIdx
    inc     dword [rbp - 8]         ; rulesIdx
    inc     dword [rbp - 12]        ; segmentLen

    ; if current character matches '=', it means
    ; the pattern matching is successful, thus
    ; starts the replcement process
    mov     edx, [rbp - 8]
    mov     dl, [rul + edx]
    cmp     dl, '='
    jne     __pattern_match_loop
__major_replacement:
    ; dword [rbp - 24] is now replaceStartIdx
    inc     dword [rbp - 8]
    mov     ecx, [rbp - 4]
    sub     ecx, [rbp - 12]
    mov     dword [rbp - 24], ecx   ; declares variable reaplceStartIdx
    mov     dword [rbp - 28], 0     ; declares variable replacementLen

    ; starts copy the replacement to a buffer string
    ; for later criterion checking, same as strcpy functionality
__copy_replacement:
    mov     edx, [rbp - 8]
    mov     dl, [rul + edx]
    cmp     dl, ';'
    je      __copy_replacement_end
    cmp     dl, 10
    je      __copy_replacement_end
    cmp     dl, 0
    je      __copy_replacement_end
    mov     ecx, [rbp - 8]
    mov     cl, [rul + ecx]
    mov     edx, [rbp - 28]
    mov     [replacement + edx], cl
    inc     dword [rbp - 28]
    inc     dword [rbp - 8]
    jmp     __copy_replacement
__copy_replacement_end:
    ; finalize copy process by putting null character after the 
    ; replacement string
    mov     edx, [rbp - 28]
    mov     [replacement + edx], byte 0

    mov     r9d, [rbp - 24]
    mov     r10d, [rbp - 12]
    mov     r11d, [rbp - 28]
    call    replace_segment         ; starts replacment
    mov     dword [rbp - 4], eax    ; update srcLen

    ; reset states
    mov     dword [rbp - 4], 0      ; reset srcIdx
    mov     dword [rbp - 8], 0      ; rulesIdx
    mov     dword [rbp - 12], 0     ; segmentLen
    jmp     __pattern_match_loop
__mismatch_character:

    ; rewinds srcIdx back to original position
    mov     ecx, dword [rbp - 12]
    sub     dword [rbp - 4], ecx
    mov     dword [rbp - 12], 0

    ; skips current rule (until matches character ';')
__skip_rule:
    mov     ecx, [rbp - 8]
    mov     edx, [rbp - 20]
    cmp     ecx, edx
    jge     __skip_rule_end
    mov     ecx, [rbp - 8]
    mov     dl, [rul + ecx]
    cmp     dl, ';'
    je      __skip_rule_end
    inc     dword [rbp - 8]
    jmp     __skip_rule
__skip_rule_end:
    ; increases ruleIdx
    inc     dword [rbp - 8]

    ; if ruleIdx is larger than ruleLen,
    ; then advance srcIdx for next pattern matching
    mov     ecx, [rbp - 8]
    mov     edx, [rbp - 20]
    cmp     ecx, edx
    jl      __pattern_match_loop
    inc     dword [rbp - 4]
    mov     dword [rbp - 8], 0
    jmp     __pattern_match_loop
__pattern_match_loop_end:

    ; if srcIdx is larger than srcLen,
    ; then no more pattern matching could be performed,
    ; thus jumps out of the major loop and prints result
    mov     ecx, [rbp - 4]
    mov     edx, [rbp - 16]
    cmp     ecx, edx
    jne     __major_main_loop
__major_main_loop_end:

    ; prints result message
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
; -> [eax] = srcLen
replace_segment:
    pushaq
    mov     rbp, rsp
    sub     rsp, 24

    mov     dword [rbp - 4], 0      ; declares variable for srcLen
    mov     dword [rbp - 8], 0      ; declares variable for i
    ; declares variable for storing either "segmentLen - replacementLen" 
    ; or "replacementLen - segmentLen"
    mov     dword [rbp - 12], 0

    ; initialize variable srcLen
    mov     rcx, src
    call    strlen
    mov     [rbp - 4], edx
    
    ; checks whether the length comparison is 
    ; greater, equal, or lesser
    cmp     r10d, r11d
    je      __replace_same_length
    cmp     r10d, r11d
    jg      __replace_less_length
    jmp     __replace_more_length
__replace_same_length:
    cmp     [rbp - 8], r11d
    jge     __replace_same_length_end
    mov     eax, [rbp - 8]
    mov     r8b, [replacement + eax]    ; replacement[i]
    add     eax, r9d
    mov     [src + eax], r8b
    inc     dword [rbp - 8]
    jmp     __replace_same_length
__replace_same_length_end:
    jmp     __replacement_end
__replace_less_length:
    ; replacement is shorter than segment
    cmp     [rbp - 8], r11d
    jge     __replace_less_length_end
    mov     eax, [rbp - 8]
    mov     r8b, [replacement + eax]    ; replacement[i]
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
    mov     eax, [rbp - 8]              ; calculate source idx
    add     eax, [rbp - 12]
    mov     r8b, [src + eax]
    mov     eax, [rbp - 8]
    mov     byte [src + eax], r8b
    inc     dword [rbp - 8]
    jmp     __shift_remaining_start
__shift_remaining_end:
    mov     eax, [rbp - 4]
    sub     eax, [rbp - 12]
    mov     [src + eax], byte 0
    jmp     __replacement_end
__replace_more_length:
    ; replacement is longer than segment
    ; i = srcLen
    mov     eax, [rbp - 4]
    mov     [rbp - 8], eax
    ; replacementLen - segmentLen
    mov     eax, r11d
    sub     eax, r10d
    mov     [rbp - 12], eax
__replace_more_length_start:
    mov     eax, r9d
    add     eax, r10d
    cmp     [rbp - 8], eax
    jl      __replace_more_length_end
    mov     eax, [rbp - 8]
    mov     r8b, [src + eax]
    add     eax, [rbp - 12]
    mov     [src + eax], r8b
    dec     dword [rbp - 8]
    jmp     __replace_more_length_start
__replace_more_length_end:
    ; i = 0
    mov     dword [rbp - 8], 0
__shift_more_start:
    cmp     [rbp - 8], r11d
    jge     __replacement_end
    mov     eax, [rbp - 8]
    mov     r8b, [replacement + eax]
    mov     eax, r9d
    add     eax, [rbp - 8]
    mov     [src + eax], r8b
    inc     dword [rbp - 8]
    jmp     __shift_more_start
__replacement_end:
    mov     eax, [rbp - 4]              ; moves srcLen to eax as return value
    add     rsp, 24                     ; resets stack pointer to original position
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
