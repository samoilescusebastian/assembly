%include "includes/io.inc"
; %include "io.inc"
extern getAST
extern freeAST

section .bss
    ; La aceasta adresa, scheletul stocheaza radacina arborelui
    root: resd 1

section .text
global main
main:
    mov ebp, esp; for correct debugging
   ; for correct debugging
    ; NU MODIFICATI
    push ebp
    mov ebp, esp
    
    ; Se citeste arborele si se scrie la adresa indicata mai sus
    call getAST
    mov [root], eax
    
    push 0
    push eax
    call traversal_inorder
    
    pop eax
    pop eax
    PRINT_DEC 4, eax
    
    
    ; NU MODIFICATI
    ; Se elibereaza memoria alocata pentru arbore
    push dword [root]
    call freeAST
    
    xor eax, eax
    leave
    ret
traversal_inorder:
    push ebp
    mov ebp,esp
    mov eax, [ebp + 8]
    cmp dword [eax + 4], 0x00
    jne continue_traversal
    mov eax, [ebp + 8]
    cmp dword [eax + 8],0x00
    ; daca s-a ajuns aici => nod fruza, deci trebuie procesat numarul
    je process_number
    
continue_traversal:
    ; apelez recursiv parcugerea pentru subarborele stang si drept
    mov ecx, [eax]
    push dword[ecx]
    push 0
    push dword [eax + 4]
    call traversal_inorder
    pop eax
    mov eax, [ebp + 8]
    push 0
    push dword [eax + 8]
    call traversal_inorder
    ;retrag din stiva rezultatele arborelui stang si drept(eax si edx)
    pop eax
    pop edx
    pop eax
    ;retrag valoarea nodului curent(semn aritmetic)
    pop ecx
    cmp  ecx, '+'
    je add
    cmp  ecx, '-'
    je sub
    cmp ecx, '*'
    je mul
    cmp ecx, '/'
    je div
write:
    ;pun rezultatul operatiei pe stiva
    mov dword [ebp + 12], eax
leave_function:
    leave
    ret
process_number:
    mov ecx, [eax]
    call convert
    mov dword [ebp + 12], eax
    jmp leave_function
    
    
convert:
    push ebp
    mov ebp,esp
    mov edi, ecx
    xor eax, eax
    ;sar la al doilea caracter in cazul in care numarul e negativ
    cmp BYTE [edi], '-'
    jne start_loop
    inc edi
 start_loop:
    xor edx,edx
    mov ebx,10
    mul ebx
    xor ebx, ebx
    mov bl, [edi]
    sub ebx, '0'
    add eax,ebx
    inc edi
    cmp byte [edi], 0x00
    jne start_loop
    ; convertire negativa daca primul caracter din string e '-'
    cmp byte [ecx], '-'
    jne exit
    neg eax
    
exit:
    leave
    ret
    
add:
    add eax, edx
    jmp write
sub:
    sub eax, edx
    jmp write
mul:
    imul edx
    jmp write
div:
    mov ebx, edx
    xor edx,edx
    cmp eax,0
    jge perform_div
    not edx
perform_div:
    idiv ebx
    jmp write