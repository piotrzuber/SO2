global euron
extern get_value, put_value                         ;declare extern functions

section .bss

    align 8
    top     resb 8 * N                              ;declare enough memory to store array of
                                                    ;tops of every euron's memory stack
    align 8
    done    resb N                                  ;declare enough memory to store array of
                                                    ;flags storing information whether fixed euron finished
                                                    ;S operation or not
section .data

    align 8
    waiting times N dq -1                           ;declare enough memory to store array of euron ids
                                                    ;used for S operation and fill it with -1
                                                    ;waiting[i] == -1 -> euron i is not waiting in S
                                                    ;waiting[m] == n -> euron m is waiting for euron n
section .text

align 8
euron:
    push    r12                                     ;save r12 value
    push    r13                                     ;save r13 value
    mov     r12, rdi                                ;store the first argument of euron function call in r12
    mov     r13, rsi                                ;store the second argument of euron function call in r13
    push    rbp                                     ;save rbp value
    mov     rbp, rsp
    xor     r14, r14                                ;register holding reading offset, set it to 0
    call    exec_prog                               ;call execution function

exec_prog:
    mov     dl, byte [r13 + r14]                    ;read next operation to dl
    inc     r14                                     ;increment reading offset
    cmp     dl, 0                                   ;check if read character is the end of a null-terminated string
    je      clean_up                                ;if we've reached the end of input string, reinstate registers values
    ;decide which operation has been read and jump to proper label
    cmp     dl, '+'
    je      addition
    cmp     dl, '*'
    je      multiplication
    cmp     dl, '-'
    je      negation
    cmp     dl, 'n'
    je      euron_num
    cmp     dl, 'B'
    je      branch
    cmp     dl, 'C'
    je      clean
    cmp     dl, 'D'
    je      duplicate
    cmp     dl, 'E'
    je      exchange
    cmp     dl, 'G'
    je      get
    cmp     dl, 'P'
    je      put
    cmp     dl, 'S'
    je      synchronize
    jmp     digit

digit:
    sub     dl, '0'                                 ;convert dl char value to digit value
    movzx   rcx, dl
    push    rcx                                     ;push given digit on stack
    jmp     exec_prog                               ;end digit operation, back to const char* prog execution loop

addition:
    pop     rcx                                     ;get first operand
    pop     r8                                      ;get second operand
    add     rcx, r8                                 ;addition
    push    rcx                                     ;push result on stack
    jmp     exec_prog                               ;end addition ('+') operation, back to const char* prog execution loop

multiplication:
    pop     rcx                                     ;get first operand
    pop     r8                                      ;get second operand
    imul    rcx, r8                                 ;signed int multiplication
    push    rcx                                     ;push result on stack
    jmp     exec_prog                               ;end multiplication ('*') operation, back to const char* prog execution loop

negation:
    neg     qword [rsp]                             ;arithmetic negation of stack's top
    jmp     exec_prog                               ;end negation ('-') operation, back to const char* prog execution loop

euron_num:
    push    r12                                     ;push euron's id on stack
    jmp     exec_prog                               ;end 'n' operation, back to const char* prog execution loop

branch:
    pop     rcx                                     ;take an offset jump value out of stack
    cmp     qword [rsp], 0                          ;compare current stack top with 0
    je      exec_prog                               ;if current top is equal to 0, end operation
    add     r14, rcx                                ;change prog reading offset by popped value
    jmp     exec_prog                               ;end branch ('B') operation, back to const char* prog execution loop

clean:
    pop     rcx                                     ;pop value out of stack
    jmp     exec_prog                               ;end clean ('C") operation, back to const char* prog execution loop

duplicate:
    push    qword [rsp]                             ;push top value on stack
    jmp     exec_prog                               ;end duplicate ('D') operation, back to const char* prog execution loop

exchange:
    pop     rcx                                     ;get first operand
    pop     r8                                      ;get second operand
    push    rcx
    push    r8                                      ;swap 2 values on the top of stack
    jmp     exec_prog                               ;end exchange ('E') operation, back to const char* prog execution loop

get:
    mov     rbx, rdi                                ;save rdi value
    mov     rdi, r12                                ;make euron's id the first argument of get_value function
    call    get_value                               ;call get_value(euron_id)
    push    rax                                     ;push the result of above call on stack
    mov     rdi, rbx                                ;preserve initial rdi value
    jmp     exec_prog                               ;end get ('G') operation, back to const char* prog execution loop

put:
    mov     rbx, rsi                                ;save rsi value
    mov     r15, rdi                                ;save rdi value
    pop     rsi                                     ;store second argument of put_value
    mov     rdi, r12                                ;make euron's id the first argument of put_value function
    call    put_value                               ;call put_value(euron_id, value)
    mov     rsi, rbx                                ;preserve initial rsi value
    mov     rdi, r15                                ;preserve initial rdi value
    jmp     exec_prog                               ;end put ('P') operation, back to const char* prog execution loop

synchronize:
    mov     byte [done + r12], 0                    ;reset euron's done flag
    pop     rcx                                     ;get id of another euron
    pop     qword [top + r12 * 8]                   ;pop current stack's top into top[r12]
    mov     qword [waiting + r12 * 8], rcx          ;waiting[r12] = rcx
    wait_sync:
        cmp     qword [waiting + rcx * 8], r12      ;wait until the euron with id equal to rcx is ready to synchronize
        jne     wait_sync
    push    qword [top + rcx * 8]                   ;swap eurons' tops
    mov     byte [done + r12], 1                    ;set euron's done flag to 1 (synchronization is finished)
    wait_another:
        cmp     byte [done + rcx], 1                ;wait until another euron is done
        jne     wait_another
    mov     qword [waiting + r12 * 8], -1           ;reset waiting[r12] to -1
    wait_exit:
        cmp     qword [waiting + rcx * 8], -1       ;wait until another euron is ready to exit operation
        jne     wait_exit
    jmp     exec_prog                               ;end synchronize ('S') operation, back to const char* prog execution loop

clean_up:
    mov     rax, qword [rsp]                        ;we need to return top value so move it to rax
    mov     rsp, rbp                                ;preserve initial rsp value
    pop     rbp                                     ;preserve initial rbp value
    pop     r13                                     ;preserve initial r13 value
    pop     r12                                     ;preserve initial r12 value
    ret                                             ;end euron function execution