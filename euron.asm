global euron
extern get_value, put_value

section .data

section .text

digit:
    sub dl, '0'
    movzx rcx, dl
    push rcx
    add dl, '0'
    jmp exec_prog

addition:
    pop rcx
    pop r8
    add rcx, r8
    push rcx
    jmp exec_prog

multiplication:
    pop rcx
    pop r8
    imul rcx, r8
    push rcx
    jmp exec_prog

negation:
    pop r8
    xor rcx, rcx
    sub rcx, r8
    push rcx
    jmp exec_prog

euron_num:
    push rdi
    jmp exec_prog

branch:
    pop rcx
    pop r8
    cmp r8, 0
    push r8
    je exec_prog
    inc rcx
    sub r15, rcx
    jmp exec_prog

clean:
    pop rcx
    jmp exec_prog

duplicate:
    pop rcx
    push rcx
    push rcx
    jmp exec_prog

exchange:
    pop rcx
    pop r8
    push rcx
    push r8
    jmp exec_prog

get:
    call get_value
    push rax
    jmp exec_prog

put:
    mov rcx, rsi
    pop rsi
    call put_value
    jmp exec_prog

synchronize:
    jmp exec_prog

exec_prog:
    mov dl, byte [rsi + r15]
    inc r15
    cmp dl, 0
    je clean_up
    cmp dl, '+'
    je addition
    cmp dl, '*'
    je multiplication
    cmp dl, '*'
    je negation
    cmp dl, 'n'
    je euron_num
    cmp dl, 'B'
    je branch
    cmp dl, 'C'
    je clean
    cmp dl, 'D'
    je duplicate
    cmp dl, 'E'
    je exchange
    cmp dl, 'G'
    je get
    cmp dl, 'P'
    je put
    cmp dl, 'S'
    je synchronize
    jmp digit


clean_up:
    mov rax, [rsp]
    mov rsp, rbp
    pop rbp
    ret

align 8
euron:
    push rbp
    mov rbp, rsp
    xor r15, r15 ;register holding reading offset
    call exec_prog