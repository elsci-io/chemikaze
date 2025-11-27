; Conventions:
; - If there's an "if" (cmp), the conditional jump has indentation
; - If we start preping params to call a function, assigning the 1st param doesn't have extra indentation, but
;   other lines related to the function call - those are indented
.global _isBigLetter
.global _MfParser_new
.global _MfParser_destroy

.data
    ; field offsets:
    .equ MfParser_elements, 0
    .equ MfParser_coeffs, 8
    .equ MfParser_len, 16
    .equ MfParser_SIZE, 24 ; total size after alignment
    .equ MfParser_DEFAULT_ELEMENTS_CNT, 20 ; number of elements originally in the array

.text

_MfParser_new:
    stp fp, lr, [sp, -16]! ; push old frame pointer and return address
    mov fp, sp
    stp x19, x20, [sp, -16]! ; x19 will store the resulting pointer

    mov w0, MfParser_SIZE ; MfParser *x19 = calloc(sizeof(MfParser), 1)
        mov w1, 1
        bl _calloc
        cbz x0, _MfParser_new_out
        mov x19, x0 ; we'll return the address of the parser

    mov w1, MfParser_DEFAULT_ELEMENTS_CNT ; MfParser->len = default
        str w1, [x19, MfParser_len]

    mov w0, 1 ; parser->elements = calloc(sizeof(*parser->elements), default)
        mov w1, MfParser_DEFAULT_ELEMENTS_CNT ; MfParser_elements are uint8, so 1 byte
        bl _calloc
        cbz x0, _MfParser_new_error
        str x0, [x19, MfParser_elements] ; assigning MfParser->elements

    mov w0, 4 ; parser->coeffs = calloc(sizeof(*parser->coeffs), default)
        mov w1, MfParser_DEFAULT_ELEMENTS_CNT
        bl _calloc
        cbz x0, _MfParser_new_error
        str x0, [x19, MfParser_coeffs] ; assign MfParser->coeffs
    b _MfParser_new_out
 _MfParser_new_error:
    bl _MfParser_destroy
 _MfParser_new_out:
    mov x0, x19 ; return MfParser*
    ldp x19, x20, [sp], 16
    ldp fp, lr, [sp], 16; restore old frame pointer and return address
 _MfParser_new_ret:
    ret

_MfParser_destroy:
    cbz x0, _MfParser_destroy_ret
    stp fp, lr, [sp, -32]! ; push old frame pointer and return address
    mov fp, sp
    str x19, [sp, 16] ; x19 is for MfParser*
    mov x19, x0 ; store MfParser* before invoking other methods
;_MfParser_destroy_free_elements:
    ldr x0, [x19, MfParser_elements]
        cbz x0, _MfParser_destroy_free_coeffs
        bl _free
 _MfParser_destroy_free_coeffs:
    ldr x0, [x19, MfParser_coeffs]
        cbz x0, _MfParser_destroy_free_MfParser
        bl _free
 _MfParser_destroy_free_MfParser:
    mov x0, x19
        bl _free
 _MfParser_destroy_out:
    ldr x19, [sp, 16] ; restore x19 register
    ldp fp, lr, [sp], 32; restore old frame pointer and return address
 _MfParser_destroy_ret:
    ret

; @param unsigned c
_isNumeric:
    sub w0, w0, '0' ;  c - '0'
    cmp w0, 10
    cset w0, lo ; c < 10
    ret

; @param unsigned c
_isBigLetter:
    sub w0, w0, 'A'
    cmp w0, 26
    cset w0, lo
    ret

; @param unsigned c
_isSmallLetter:
    sub w0, w0, 'a'
    cmp w0, 26
    cset w0, lo
    ret