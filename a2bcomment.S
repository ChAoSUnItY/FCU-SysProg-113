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
    mov     rcx, src_input_msg      ; 將輸入字串提示訊息載到rcx
    call    strlen                  ; 呼叫strlen(計算題示訊息長度)
    call    puts                    ; 呼叫輸出

    mov     rcx, src                ; 設定存在sec
    mov     rdx, 100                ; 設定輸入大小
    call    gets                    ; 呼叫輸入

    call    strlen                  ; 計算輸入的字串長度
    mov     dword [rbp - 16], edx   ; srcLen = strlen(src)

    ; prompts rule string
    mov     rcx, rul_input_msg      ; 將輸入規則提示訊息載到rcx
    call    strlen                  ; 呼叫strlen(計算題示訊息長度)
    call    puts                    ; 呼叫輸出

    mov     rcx, rul                ; 設定存在rul
    mov     rdx, 100                ; 設定輸入大小
    call    gets                    ; 呼叫輸入

    call    strlen                  ; 計算輸入的字串長度
    mov     dword [rbp - 20], edx   ; rulesLen = strlen(rules)

__major_main_loop:
    ; reset states
    mov     dword [rbp - 4], 0      ; srcIdx歸零
    mov     dword [rbp - 8], 0      ; rulesIdx歸零
    mov     dword [rbp - 12], 0     ; segmentLen歸零
__pattern_match_loop:
    ; iteration condition
    mov     ecx, [rbp - 4]          ; ecx載入srcIdx
    mov     edx, [rbp - 16]         ; edx載入srcLen
    cmp     ecx, edx                ; 比較srcIdx、srcLen
    jge     __pattern_match_loop_end; 如果srcIdx>=srcLen，跳到end
    mov     ecx, [rbp - 8]          ; ecx載入rulesIdx
    mov     edx, [rbp - 20]         ; edx載入rulesLen
    cmp     ecx, edx                ; 比較srcIdx、srcLen
    jge     __pattern_match_loop_end; 如果rulesIdx>=rulesLen，跳到end

    ; pattern matching rule
    mov     ecx, [rbp - 4]          ; ecx載入srcIdx
    mov     cl, [src + ecx]         ; cl載入sec的srcIdx位置
    mov     edx, [rbp - 8]          ; edx載入rulesIdx
    mov     dl, [rul + edx]         ; dl載入rul的rulesIdx位置
    cmp     cl, dl                  ; 比較sec的srcIdx位置和rul的rulesIdx位置
    jne     __mismatch_character    ; 如果不相等，跳到mismatch
__match_character:
    inc     dword [rbp - 4]         ; srcIdx加1
    inc     dword [rbp - 8]         ; rulesIdx加1
    inc     dword [rbp - 12]        ; segmentLen加1

    ; if current character matches '=', it means
    ; the pattern matching is successful, thus
    ; starts the replcement process
    mov     edx, [rbp - 8]          ; edx載入rulesIdx
    mov     dl, [rul + edx]         ; dl載入rul的rulesIdx位置
    cmp     dl, '='                 ; 檢查rul的rulesIdx位置是否為=(結束條件)
    jne     __pattern_match_loop    ; 如果不是=，繼續loop檢查
__major_replacement:
    ; dword [rbp - 24] is now replaceStartIdx
    inc     dword [rbp - 8]         ; ruleIdx加1
    mov     ecx, [rbp - 4]          ; ecx載入srcIdx
    sub     ecx, [rbp - 12]         ; srcIdx減去segmentLen
    mov     dword [rbp - 24], ecx   ; 宣告reaplceStartIdx
    mov     dword [rbp - 28], 0     ; 宣告replacementLen

    ; starts copy the replacement to a buffer string
    ; for later criterion checking, same as strcpy functionality
__copy_replacement:
    mov     edx, [rbp - 8]          ; edx載入rulesIdx
    mov     dl, [rul + edx]         ; d1載入rul的rulesIdx位置
    cmp     dl, ';'                 ; 比對rul的rulesIdx位置是否為;
    je      __copy_replacement_end  ; 如果是跳到end
    cmp     dl, 10                  ; 比對rul的rulesIdx位置是否為換行
    je      __copy_replacement_end  ; 如果是跳到end
    cmp     dl, 0                   ; 比對rul的rulesIdx位置是否為換行
    je      __copy_replacement_end  ; 如果是跳到end
    mov     ecx, [rbp - 8]          ; ecx載入rulesIdx
    mov     cl, [rul + ecx]         ; d1載入rul的rulesIdx位置
    mov     edx, [rbp - 28]         ; edx載入replacementLen
    mov     [replacement + edx], cl ; 將rul的rulesIdx位置放到replacement的replacementLen位置
    inc     dword [rbp - 28]        ; replacementLen加1
    inc     dword [rbp - 8]         ; rulesIdx加1
    jmp     __copy_replacement      ; 回到迴圈繼續執行
__copy_replacement_end:
    ; finalize copy process by putting null character after the 
    ; replacement string
    mov     edx, [rbp - 28]         ; edx載入replacementLen
    mov     [replacement + edx], byte 0;replacement的最後一個位置設定成0

    mov     r9d, [rbp - 24]         ; r9d載入replceStartIdx
    mov     r10d, [rbp - 12]        ; r10d載入segmentLen
    mov     r11d, [rbp - 28]        ; r11d載入replacementLen
    call    replace_segment         ; starts replacment(呼叫)
    mov     dword [rbp - 4], eax    ; 更新 srcLen

    ; reset states
    mov     dword [rbp - 4], 0      ; srcIdx重置
    mov     dword [rbp - 8], 0      ; rulesIdx重置
    mov     dword [rbp - 12], 0     ; segmentLen重置
    jmp     __pattern_match_loop    ; 跳到pattern_match_loop
__mismatch_character:

    ; rewinds srcIdx back to original position
    mov     ecx, dword [rbp - 12]   ; ecx載入segmentLen
    sub     dword [rbp - 4], ecx    ; srcId等於segmentLen
    mov     dword [rbp - 12], 0     ; segmentLen重置

    ; skips current rule (until matches character ';')
__skip_rule:
    mov     ecx, [rbp - 8]          ; ecx載入rulesIdx
    mov     edx, [rbp - 20]         ; edx載入rulesLen
    cmp     ecx, edx                ; 比較rulesIdx和rulesLen
    jge     __skip_rule_end         ; 當rulesIdx>rulesLen，跳到__skip_rule_end
    mov     ecx, [rbp - 8]          ; ecx載入rulesIdx
    mov     dl, [rul + ecx]         ; d1載入rul[rulesIdx]
    cmp     dl, ';'                 ; 比較rul[rulesIdx]是否等於';'
    je      __skip_rule_end         ; 如果等於，跳到__skip_rule_end
    inc     dword [rbp - 8]         ; rulesIdx加1
    jmp     __skip_rule             ; 重複執行
__skip_rule_end:
    ; increases ruleIdx
    inc     dword [rbp - 8]         ; rulesIdx加1

    ; if ruleIdx is larger than ruleLen,
    ; then advance srcIdx for next pattern matching
    mov     ecx, [rbp - 8]          ; ecx載入rulesIdx
    mov     edx, [rbp - 20]         ; edx載入rulesLen
    cmp     ecx, edx                ; 比較rulesIdx、rulesLen
    jl      __pattern_match_loop    ; 當rulesIdx < rulesLen，跳到__pattern_match_loop
    inc     dword [rbp - 4]         ; srcId加1
    mov     dword [rbp - 8], 0      ; rulesIdx載入0
    jmp     __pattern_match_loop    ; 跳到__pattern_match_loop
__pattern_match_loop_end:

    ; if srcIdx is larger than srcLen,
    ; then no more pattern matching could be performed,
    ; thus jumps out of the major loop and prints result
    mov     ecx, [rbp - 4]          ; ecx載入srcIdx
    mov     edx, [rbp - 16]         ; edx載入srcLen
    cmp     ecx, edx                ; 比較srcIdx、srcLen
    jne     __major_main_loop       ; 當兩者不相等，跳到__major_main_loop
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

    mov     dword [rbp - 4], 0      ; 宣告srcLen
    mov     dword [rbp - 8], 0      ; 宣告i，等於0
    ; declares variable for storing either "segmentLen - replacementLen" 
    ; or "replacementLen - segmentLen"
    mov     dword [rbp - 12], 0     ; 宣告一個變數儲存segmentLen - replacementLen或replacementLen - segmentLen

    ; initialize variable srcLen
    mov     rcx, src                ; 將rcx載入src 
    call    strlen                  ; 計算src的長度
    mov     [rbp - 4], edx          ; srcLen載入計算後的長度
    
    ; checks whether the length comparison is 
    ; greater, equal, or lesser
    cmp     r10d, r11d              ; 比較segmentLen和replacementLen
    je      __replace_same_length   ; 當兩者相等，跳到same_length
    cmp     r10d, r11d              ; 比較segmentLen和replacementLen
    jg      __replace_less_length   ; 當segmentLen小，跳到less_length
    jmp     __replace_more_length   ; 跳到more_length
__replace_same_length:
    cmp     [rbp - 8], r11d         ; 比較i與replacementLen
    jge     __replace_same_length_end; 當兩者相等，跳到same_length_end
    mov     eax, [rbp - 8]          ; eax載入i
    mov     r8b, [replacement + eax]; r8b載入replacement[i]
    add     eax, r9d                ; eax等於 i+reaplceStartIdx
    mov     [src + eax], r8b        ; 將replacement[i]放到src[i+reaplceStartIdx]
    inc     dword [rbp - 8]         ; i加1
    jmp     __replace_same_length   ; 重複執行
__replace_same_length_end:
    jmp     __replacement_end       ; 跳到replace end
__replace_less_length:
    ; replacement is shorter than segment
    cmp     [rbp - 8], r11d         ; 比較i與replacementLen
    jge     __replace_less_length_end; 當兩者相等，跳到less_length_end
    mov     eax, [rbp - 8]          ; eax載入i
    mov     r8b, [replacement + eax]; r8b載入replacement[i]
    add     eax, r9d                ; eax等於 i+reaplceStartIdx
    mov     [src + eax], r8b        ; 將replacement[i]放到src[i+reaplceStartIdx]
    inc     dword [rbp - 8]         ; i加1
    jmp     __replace_less_length   ; 重複執行
__replace_less_length_end:
    ; segmentLen - replacementLen
    mov     eax, r10d               ; eax載入segmentLen
    sub     eax, r11d               ; eax減去replacementLen
    mov     dword [rbp - 12], eax   ; segmentLen - replacementLen
    ; i = startIdx + replacementLen
    mov     dword [rbp - 8], r9d    ; i = reaplceStartIdx
    add     dword [rbp - 8], r11d   ; i = i+replacementLen
__shift_remaining_start:
    mov     eax, dword [rbp - 4]    ; eax載入srcLen
    sub     eax, dword [rbp - 12]   ; eax減segmentLen - replacementLen
    cmp     dword [rbp - 8], eax    ; 比較i和srcLen - segmentLen + replacementLen
    jge     __shift_remaining_end   ; 如果超過，跳到end
    mov     eax, [rbp - 8]          ; eax載入i
    add     eax, [rbp - 12]         ; eax加上(segmentLen - replacementLen)
    mov     r8b, [src + eax]        ; r8b載入src[i+(segmentLen - replacementLen)]
    mov     eax, [rbp - 8]          ; eax載入i
    mov     byte [src + eax], r8b   ; src[i] = src[i+(segmentLen - replacementLen)]
    inc     dword [rbp - 8]         ; i加1
    jmp     __shift_remaining_start ; 重複執行
__shift_remaining_end:
    mov     eax, [rbp - 4]          ; eax載入srcLen
    sub     eax, [rbp - 12]         ; eax減segmentLen - replacementLen
    mov     [src + eax], byte 0     ; src[srcLen -(segmentLen - replacementLen)]放置 0
    jmp     __replacement_end       ; 跳到end
__replace_more_length:
    ; replacement is longer than segment
    ; i = srcLen
    mov     eax, [rbp - 4]          ; eax載入srcLen
    mov     [rbp - 8], eax          ; i 等於srcLen
    ; replacementLen - segmentLen
    mov     eax, r11d               ; eax載入replacementLen
    sub     eax, r10d               ; eax減 segmentLen
    mov     [rbp - 12], eax         ; replacementLen - segmentLen
__replace_more_length_start:
    mov     eax, r9d                ; eax 載入startIdx
    add     eax, r10d               ; eax 加上segmentLen
    cmp     [rbp - 8], eax          ; 比較i和startIdx + segmentLen的大小
    jl      __replace_more_length_end;如果小於，跳到end
    mov     eax, [rbp - 8]          ; eax載入i
    mov     r8b, [src + eax]        ; r8b載入src[i]
    add     eax, [rbp - 12]         ; eax加上replacementLen - segmentLen
    mov     [src + eax], r8b        ; src[i + (replacementLen - segmentLen)] = src[i];
    dec     dword [rbp - 8]         ; i減1
    jmp     __replace_more_length_start ;重複執行
__replace_more_length_end:
    ; i = 0
    mov     dword [rbp - 8], 0      ; i歸零
__shift_more_start:
    cmp     [rbp - 8], r11d         ; 比較i和replacementLen
    jge     __replacement_end       ; 如果大於，跳到end
    mov     eax, [rbp - 8]          ; eax載入i
    mov     r8b, [replacement + eax]; r8b載入replacement[i]
    mov     eax, r9d                ; eax載入startIdx
    add     eax, [rbp - 8]          ; eax加上startIdx
    mov     [src + eax], r8b        ; src[startIdx + i] = replacement[i];
    inc     dword [rbp - 8]         ; i加1
    jmp     __shift_more_start      ; 重複執行
__replacement_end:
    mov     eax, [rbp - 4]          ; eax載入srcIdx
    add     rsp, 24                 ; resets stack pointer to original position
    popaq
    ret

; prints string
; <- [rcx] = source
; <- [rdx] = length
puts:
    mov     rax, 4      ; write模式
    mov     rbx, 1      ; stdout
    int     0x80        ; write(stdout, source, strlen(source));
    ret

; reads string
; <- [rcx] = destination
; <- [rdx] = buffer size
gets:
    mov     rax, 3      ; read模式
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
    xor     rdx, rdx            ;將rdx歸零
_strlen_next:
    cmp     [rcx], byte 0       ;檢查目前位置是否為NULL
    jz      _strlen_end         ;如果為NULL，結束
    inc     rcx                 ;rcx加1
    inc     rdx                 ;rdx加1
    jmp     _strlen_next        ;跳回_strlen_next
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
