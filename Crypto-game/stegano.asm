%include "include/io.inc"
;%include "io.inc"
extern atoi
extern printf
extern exit

; Functions to read/free/print the image.
; The image is passed in argv[1].
extern read_image
extern free_image
; void print_image(int* image, int width, int height);
extern print_image

; Get image's width and height.
; Store them in img_[width, height] variables.
extern get_image_width
extern get_image_height

section .data
	use_str db "Use with ./tema2 <task_num> [opt_arg1] [opt_arg2]", 10, 0

section .bss
    task:       resd 1
    img:        resd 1
    img_width:  resd 1
    img_height: resd 1

section .text
global main
main:
    mov ebp, esp; for correct debugging
    ; Prologue
    ; Do not modify!
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]
    cmp eax, 1
    jne not_zero_param

    push use_str
    call printf
    add esp, 4

    push -1
    call exit

not_zero_param:
    ; We read the image. You can thank us later! :)
    ; You have it stored at img variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 4]
    call read_image
    add esp, 4
    mov [img], eax

    ; We saved the image's dimensions in the variables below.
    call get_image_width
    mov [img_width], eax

    call get_image_height
    mov [img_height], eax

    ; Let's get the task number. It will be stored at task variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 8]
    mov esi, esp
    call atoi
    add esp, 4
    mov [task], eax

    ; There you go! Have fun! :D
    mov eax, [task]
    cmp eax, 1
    je solve_task1
    cmp eax, 2
    je solve_task2
    cmp eax, 3
    je solve_task3
    cmp eax, 4
    je solve_task4
    cmp eax, 5
    je solve_task5
    cmp eax, 6
    je solve_task6

solve_task1:
    push 1
    call bruteforce_singlebyte_xor
    jmp done
solve_task2:
    call bruteforce_singlebyte_xor
    ; obtinerea cheii si liniei pe care se afla mesajul criptat
    mov bx, ax
    shr eax, 16
    mov edx, eax
    push ebx
    push edx
    call crypt_matrix
    mov ebx, [esp + 4]
    ; punerea pe stiva a mesajului ce va fi criptat
    ; adaugarea urmareste logica stivei
    push byte 0x00
    push "is."
    push "anca"
    push "e fr"
    push "verb"
    push " pro"
    push "t un"
    push "C'es"
    push esp
    mov eax, [esp]
    call get_length
    push eax
    call compute_position
    push ebx
    ; inserarea mesajului pe linia imediat urmatoare mesajului existent
    call insert_message
    add esp, 44
    pop edx
    pop ebx
    call create_new_key
    ; criptarea pozei cu ajutorul noii chei
    call crypt_matrix
    push dword [img_height]
    push dword[img_width]
    push dword [img]
    call print_image
    add esp, 12
    jmp done
solve_task3:
    mov eax, [ebp + 12]
    mov edi, [eax + 12]
    push DWORD[eax + 16]
    mov esi, esp
    call atoi
    add esp, 4
    push eax
    push edi
    push dword[img]
    call morse_encrypt
    push dword [img_height]
    push dword[img_width]
    push dword [img]
    call print_image
    jmp done
solve_task4:
    mov eax, [ebp + 12]
    mov edi, [eax + 12]
    push DWORD[eax + 16]
    mov esi, esp
    call atoi
    add esp, 4
    push eax
    push edi
    push dword[img]
    call lsb_encode
    push dword [img_height]
    push dword[img_width]
    push dword [img]
    call print_image
    jmp done
solve_task5:
    mov eax, [ebp + 12]
    push DWORD[eax + 12]
    mov esi, esp
    call atoi
    add esp, 4
    push eax
    push dword[img]
    call lsb_decode
    jmp done
solve_task6:
    push dword[img]
    call blur
    push dword [img_height]
    push dword[img_width]
    push dword [img]
    call print_image
    jmp done

    ; Free the memory allocated for the image.
done:
    push DWORD[img]
    call free_image
    add esp, 4

    ; Epilogue
    ; Do not modify!
    xor eax, eax
    leave
    ret
bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp 
    mov dh, 0
; parcurgerea cheilor de la 0 la 255
loop_0:
    xor ebx, ebx
    mov eax, [img]
; parcurgerea liniilor matricei
loop_1:
    xor ecx, ecx
    sub esp,[img_width]
    push eax
; parcurgerea coloaneleor matricei
loop_2:
    mov dl, byte [eax]
    xor dl, dh
    mov [esp + ecx + 4], dl 
    cmp dl, 0x00; sfarsitul unui mesaj
    jne continue
    push 0
    call verify_message; mesajul este sau nu cel cautat
    pop esi
    cmp esi, byte 1
    je print; oprirea functiei daca s-a gasit mesajul
    
continue:
    add eax, 4
    inc ecx
    cmp ecx, [img_width]
    jl loop_2
    add esp, 4
    add esp, [img_width]
    inc ebx
    cmp ebx, [img_height]
    jl loop_1
    inc dh
    cmp dh, byte 255
    jb loop_0
    leave
    ret
print:
    cmp byte [ebp + 8], 1
    jne save; pentru task- ul 2 se salveaza linia si cheia
    PRINT_STRING [ESP + 4]; pentru primul task se face scrierea informatiilor
    NEWLINE
    PRINT_UDEC 1, dh
    NEWLINE
    PRINT_UDEC 2, bx
    NEWLINE
save:
    xor eax, eax
    mov al, dh
    shl eax, 16
    mov ax, bx
    mov ebx, esp
  
    leave
    ret 4

verify_message:
    push ebp
    mov ebp, esp
    push byte 0x00
    push "ent"
    push "revi"; adaugarea cuvantului magic pe stiva
    mov edi, ebp
    add edi, 16
    push eax
    push ecx
    mov al, 'r'
    cld
search_sub:; cautarea caracterului primului caracter din substring in mesaj
    repne scasb
    cmp ecx, byte 0
    je finish
    push edi
    dec edi
    mov esi, esp; de la pozitia aparitiei primului caracter din substring
    add esi, 12;   ; se verifica daca se afla intreg substringul in mesaj
    repe cmpsb
    cmp [esi], byte 0x00
    pop edi
    je mark
    jmp search_sub
finish:    
    pop ecx
    pop eax
    leave
    ret
mark:; validarea mesajului ca fiind cel cautat
    mov [ebp + 8], byte 1
    jmp finish
 

crypt_matrix:; se face xor cu o anumita cheie pe toata matricea
   mov eax, [img]; cheia este salvata in dl
   xor ebx, ebx
loop_crypt_1:
    xor ecx, ecx
loop_crypt_2:
    mov dh, byte [eax]
    xor dh, dl
    mov [eax], dh
    add eax, 4
    inc ecx
    cmp ecx, [img_width]
    jl loop_crypt_2
    inc ebx
    cmp ebx, [img_height]
    jl loop_crypt_1
    ret
insert_message:
    push ebp
    mov ebp, esp
    xor eax, eax
    mov eax, [img]    
    mov ebx, [ebp + 8]; pozitia din matrice in care va fi inserat mesajul
    add eax, ebx
    mov esi, [ebp + 16]; salvarea adresa mesajului
    mov ecx, [ebp + 12]; salvarea lungime mesaj
start_copy:; copierea byte cu byte a mesajului
    xor edx, edx
    mov dl, byte [esi]
    mov dword [eax], edx
    add eax, 4
    add esi, 1
    loop start_copy
    leave
    ret
create_new_key:
    xor ecx, ecx
    mov cx, 2
    xor eax, eax
    mov ax, dx
    mul cx
    add ax, 3
    mov cl, 5
    div cl
    sub al, 4
    mov dl, al
    ret
compute_position:
    mov dx, word [img_width]
    mov ax, bx
    inc ax
    mul dx
    mov bx, ax
    mov ax, dx
    shl eax, 16
    mov ax, bx
    mov edx, 4
    mul edx
    mov ebx, eax
    ret
    
get_length:
    mov esi, eax
length_loop:
    inc esi
    cmp byte [esi], 0x00
    jne length_loop
    sub esi, eax
    mov eax, esi
    inc eax
    ret
morse_encrypt:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 12]
    call get_length
    mov ebx, 7
    mul ebx
    sub esp, eax; alocarea noului mesaj pe stiva
    mov byte[esp], 4
    push esp
    push dword [ebp + 12]
    call convert_message
    add esp, 4
    mov eax, [esp]
    call get_length
    push eax
    mov ebx, [ebp + 16]
    add ebx, ebx
    add ebx, ebx
    push ebx; inserarea noului mesaj pe pozitia indicata
    call insert_message
    leave
    ret
convert_message:
    push ebp
    mov ebp, esp  
    ; creearea tabela conversie catre morse
    dec esp
    push "--.." ;Z
    mov byte [esp + 4], 0x00
    
    dec esp
    push "-.--" ;Y
    mov byte[esp + 4], 0x00

    dec esp
    push "-..-" ;X
    mov byte[esp + 4], 0x00
    
    dec esp
    push ".--" ;W
    mov byte[esp + 3], 0x00
   

    dec esp
    mov byte [esp], 0x00
    push "...-" ;V
    
    dec esp
    push "..-" ;U
    mov byte[esp + 3], 0x00
    
    dec esp
    push "-000" ;T
    mov byte[esp + 1], 0x00
    
    dec esp
    push "..." ;S
    mov byte[esp + 3], 0x00
    
    dec esp
    push ".-." ;R
    mov byte[esp + 3], 0x00
    
    dec esp
    push "--.-" ;Q
    mov byte[esp + 4], 0x00
    
    dec esp
    push ".--." ;P
    mov byte[esp + 4], 0x00
    
    dec esp
    push "---" ;O
    mov byte[esp + 3], 0x00
    
    dec esp
    push "-." ;N
    mov byte[esp + 2], 0x00
    
    dec esp
    push "--" ;M
    mov byte[esp + 2], 0x00
    
    dec esp
    push ".-.." ;L
    mov byte[esp + 4], 0x00
    
    dec esp
    push "-.-" ;K
    mov byte[esp + 3],0x00
    
    dec esp
    push ".---" ;J
    mov byte[esp + 4], 0x00
    
    dec esp
    push ".." ;I
    mov byte[esp + 2], 0x00
    
    dec esp
    push "...." ;H
    mov byte[esp + 4], 0x00
    
    dec esp
    push "--." ;G
    mov byte[esp + 3], 0x00
    
    dec esp
    push "..-." ;F
    mov byte[esp + 4], 0x00
    
    dec esp
    push "." ;E
    mov byte[esp +1], 0x00
    
    dec esp
    push "-.." ;D
    mov byte[esp + 3], 0x00
    
    dec esp
    push "-.-." ;C
    mov byte[esp + 4], 0x00
    
    dec esp
    push "-..." ;B
    mov byte[esp + 4], 0x00
    
    dec esp
    push ".-" ;A
    mov byte[esp + 2], 0x00
    
    mov eax, esp
   
    sub esp, 2
    push "----"; 9
    mov byte[esp + 4], '.'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "---."; 8
    mov byte[esp + 4], '.'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "--.."; 7
    mov byte[esp + 4], '.'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "-..."; 6
    mov byte[esp + 4], '.'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "...."; 5
    mov byte[esp + 4], '.'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "...."; 4
    mov byte[esp + 4], '-'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "...-"; 3
    mov byte[esp + 4], '-'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "..--"; 2
    mov byte[esp + 4], '-'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push ".---"; 1
    mov byte[esp + 4], '-'
    mov byte[esp + 5], 0x00
    
    sub esp, 2
    push "----"; 0
    mov byte[esp + 4], '-'
    mov byte[esp + 5], 0x00
    mov ebx, esp
    mov esi, [ebp + 8]
    mov edi, [ebp + 12]
    mov byte[edi], 123
start_convert_loop:
    cmp byte[esi], ','; verificare virgula
    jne verify_letter
    mov dword[edi], "--.."
    mov word[edi + 4], "--"
    mov byte[edi + 6], ' '
    add edi, 7
    jmp end_convert_loop
verify_letter:
    cmp byte[esi], 'A'
    jl verify_digit
    mov cl, [esi]
    sub ecx, 'A'
    xchg eax, ecx
    mov edx, 5
    mul edx
    xchg eax, ecx
    add eax, ecx
    push esi
    push ecx
    mov esi, eax
    call copy_code; copierea codului corespunzator
    mov byte [edi], ' '
    inc edi
    pop ecx
    pop esi
    sub eax, ecx
    jmp end_convert_loop
verify_digit:
    xor ecx, ecx
    mov cl, [esi]
    sub ecx, '0'
    xchg eax, ecx
    mov edx, 6
    mul edx
    xchg ebx, ecx
    add ebx, ecx
    push esi
    push ecx
    mov esi, ebx
    call copy_code; copierea codului corespunzator
    mov byte [edi], ' '
    inc edi
    pop ecx
    pop esi
    sub ebx, ecx
end_convert_loop:
    inc esi
    cmp byte[esi], 0x00
    jne start_convert_loop
    dec edi
    mov byte [edi], 0x00
    leave
    ret
copy_code:
    push ebp
    mov ebp, esp
start_loop_copy:
    mov cl, byte[esi]
    mov byte[edi], cl
    inc edi
    inc esi
    cmp byte[esi], 0x00
    jne start_loop_copy
   leave
   ret
lsb_encode:
     push ebp
     mov ebp, esp
     mov eax, [ebp + 8] ;img
     mov esi, [ebp + 12] ;string
     mov ecx, [ebp + 16] ;position
     dec ecx
     add ecx, ecx
     add ecx, ecx
     add eax, ecx
start_iterate_over_letters:
     mov bl, byte[esi]
     mov ecx, 8
     sub esp, 9
get_bits:; obtinere biti din litera curenta
     mov bh, bl
     and bh, 1
     shr bl, 1 
     dec ecx
     add bh, 48
     mov byte[esp + ecx], bh
     cmp ecx, 0
     jne get_bits
     mov byte[esp + 8], 0x00
     mov edi, esp
start_iterate_over_bits:
     mov bl, byte[edi]
     mov edx, [eax]
     cmp bl, '1'
     je set_one
     jmp set_zero

continue_enc:
     mov dword [eax], edx
     add eax, 4
     inc edi
     cmp byte[edi], 0x00
     
     jne start_iterate_over_bits
     add esp, 9
     inc esi
     cmp byte[esi], 0x00
     jne start_iterate_over_letters

     mov ecx, 8
start_set_zero:
     mov edx, [eax]
     test edx, 1
     je continue_set_zero
     dec edx
     
continue_set_zero:
     mov dword[eax], edx
     add eax, 4
     dec ecx
     cmp ecx, 0
     jg start_set_zero
     
     leave
     ret
set_one:
    or edx, 1
    jmp continue_enc
set_zero:
    test edx, 1
    je continue_enc
    dec edx
    jmp continue_enc

lsb_decode:
     push ebp
     mov ebp, esp
     mov esi, [ebp + 8] ;img
     mov ebx, [ebp + 12] ;position
     dec ebx
     add ebx, ebx
     add ebx, ebx
     add esi, ebx
     sub esp, 21
     mov edi, esp
get_word:
     mov ecx, 8
     sub esp, 9
get_byte:
     mov dl, byte[esi]
     and dl, 1
     add dl, 48
     dec ecx
     add esi,4
     mov byte [esp + ecx], dl
     cmp ecx, 0
     jne get_byte
     mov byte[esp + 8], 0x00
     mov eax, esp
     push esi
     push ebx
     call bits_to_dec
     mov byte[edi], al
     inc edi
     pop ebx
     pop esi
     add esp, 9
     cmp al, 0x00
     jne get_word
     PRINT_STRING [ESP]
     leave
     ret
bits_to_dec:
    mov esi, eax
    xor eax, eax
    xor ebx, ebx
    inc ebx
convert_bit:
    cmp byte[esi], '0'
    je continue_convert
    add eax, ebx
continue_convert:
    add ebx, ebx
    inc esi
    cmp byte[esi], 0x00
    jne convert_bit
    ret
    
blur:
  push ebp
  mov ebp, esp
  mov esi, [ebp + 8]
  mov eax, [img_width]
  mov ecx, [img_height]
  mul ecx
  add eax, 2
  sub esp, eax; alocarea matrice noua pe stiva
  mov edi, esp
  xor ecx, ecx
iterate_over_rows:
  xor ebx, ebx
iterate_over_columns:
  push edi
  call validate_pixel
  pop edi
  cmp al, 0
  je old_pixel
  push edi
  call compute_mean
  pop edi
  jmp write_pixel
old_pixel:
  mov al, byte[esi]
write_pixel:
  mov byte[edi], al
  inc edi
  add esi, 4
  inc ebx
  cmp ebx, [img_width]
  jb iterate_over_columns
  inc ecx
  cmp ecx, [img_height]
  jb iterate_over_rows
  mov edi, esp
  mov esi, [img]
  call copy_new_elements
  leave
  ret

validate_pixel:; verificare daca pixelul este sau nu pe contur
  xor al, al
  inc al
  cmp ecx, 0
  je invalid_pixel
  cmp ebx, 0
  je invalid_pixel
  mov edi, [img_height]
  dec edi
  cmp ecx, edi
  je invalid_pixel
  mov edi, [img_width]
  dec edi
  cmp ebx, edi
  je invalid_pixel
  ret
invalid_pixel:
  xor al, al
  ret
compute_mean:
  mov eax, [esi]
  add eax, [esi + 4]
  add eax, [esi - 4]
  mov edx, [img_width]
  add edx, edx
  add edx, edx
  mov edi , esi
  sub edi, edx
  add eax, [edi]
  add eax, [esi + edx]
  mov dl, 5
  div dl
  ret
copy_new_elements:
  mov eax, [img_width]
  mov ecx, [img_height]
  mul ecx
copy_element:
  mov bl, byte[edi]
  mov [esi], bl
  inc edi
  add esi, 4
  dec eax
  cmp eax, 0
  jne copy_element
  ret