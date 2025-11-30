; Conventions:
; - If there's an "if" (cmp), the conditional jump has indentation
; - If we start preping params to call a function, assigning the 1st param doesn't have extra indentation, but
;   other lines related to the function call - those are indented
.global _isBigLetter
.global _MfParser_new
.global _MfParser_destroy
.global _MfParser_parseSanitized
.global _ptable_getElementBySymbol_short
.global _MfParser_consumeCoeff

.data
    ; struct MfParser field offsets and so on:
    .equ MfParser_elements, 0
    .equ MfParser_coeffs, 8
    .equ MfParser_len, 16
    .equ MfParser_SIZE, 24 ; total size after alignment
    .equ MfParser_DEFAULT_ELEMENTS_CNT, 20 ; number of elements originally in the array

    ; enum ChemikazeErrorCode:
    .equ ChemikazeErrorCode_PARSE, 0
    .equ ChemikazeErrorCode_OOM, 1
    .equ ChemikazeErrorCode_NULL_POINTER, 2

    ; struct ChemikazeError field offsets:
    .equ ChemikazeError_msg, 0 ; char *msg
    .equ ChemikazeError_code, 8 ; ChemikazeErrorCode
    .equ ChemikazeError_SIZE, 16 ; char *msg

    ChemikazeError_EMPTY_MOL_MSG: .asciz "Empty Molecular Formula"

    PTABLE_ELEMENTHASH_TO_ELEMENT: ; hash(char[2]) -> ChemicalElement, see periodic_table.c
        .byte 0,0,55,83,38,0,0,9,0,0,20,0,50,21,0,15,23,0,0,8,0,0,0,0,0,0,53,43,0,0,13,0
        .byte 74,0,0,69,0,0,27,84,0,0,0,0,0,0,0,64,0,0,42,0,0,0,0,0,0,16,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,65,0,0,0,36,0,0,0,0,0,0,0,10,0,0,0,0,0,0,0,52,0,0
        .byte 0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        .byte 0,47,0,0,0,67,59,68,76,63,0,0,79,29,0,72,4,0,0,44,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,25,0,0,0,26,58,0,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,40,0,0,41,0,0,0,0,0,34,0,0,62,57,0,0,70
        .byte 0,0,54,0,73,0,0,0,0,0,0,0,0,0,0,0,0,80,77,0,17,0,0,0,0,0,0,0,0,48,0,0
        .byte 0,0,0,78,0,0,0,0,71,0,0,51,24,0,19,31,37,0,0,0,0,0,0,0,7,0,0,0,0,0,0,0
        .byte 0,0,0,0,0,0,0,12,0,0,0,0,0,0,0,0,0,0,0,0,0,0,14,0,0,0,0,0,0,0,39,22
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,33,0,0,0,0,0,0,0,49,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0
        .byte 0,0,0,0,0,0,0,61,0,0,0,0,0,82,66,75,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte 0,45,56,0,0,0,30,0,0,0,28,0,18,46,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,35,5,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,11,0,0,0,0
        .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,60,0,0,0,0,0,0,0,0,0,0,0,81,0,0,0,0,0,0
    .equ PTABLE_ELEMENTHASH_TO_ELEMENT_LEN, 512
    .equ PTABLE_ELEMENTHASH_TO_ELEMENT_MASK, 511

    MfParser_readSymbolsAndCoeffs__bigLetter_name: .asciz "MfParser_readSymbolsAndCoeffs__bigLetter\n"
    MfParser_consumeSymbolAndCoeff_name: .asciz "MfParser_consumeSymbolAndCoeff\n"
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

;
; Assumes you already trimmed the MF, and you're passing the right boundaries. If you didn't do this, then call
; a non-sanitized method.
;
; @param MfParser *parser
; @param const char *mf start of the molecular formula
; @param const char *mfEnd end of the formula, exclusive
; @param ChemikazeError** to fill if error occurs
; @return x0 AtomCounts* or null. If null then check the error param.
;
_MfParser_parseSanitized:
    stp fp, lr, [sp, -16]!
        mov fp, sp
    stp x19, x20, [sp, -16]!
        mov x19, x3 ; ChemikazeError* to be optionally filled
        mov x20, x4
    cmp x1, x2
        b.hs _MfParser_parseSanitized__emptyMfError
    mov x0, x1
        mov x1, x2
        bl MfParser_readSymbolsAndCoeffs
_MfParser_parseSanitized__out:
    ldp x19, x20, [sp], 16
    ldp fp, lr, [sp], 16
    ret
_MfParser_parseSanitized__emptyMfError:
    mov x0, ChemikazeErrorCode_PARSE
        adrp x1, ChemikazeError_EMPTY_MOL_MSG@page
        add x1, x1, ChemikazeError_EMPTY_MOL_MSG@pageoff
        bl _ChemikazeError_new
    str x0, [x19] ; return ChemikazeError*
    mov x0, 0 ; return null
    b _MfParser_parseSanitized__out

; @param [x0 -> x19] const char *mf - start of the MF
; @param [x1 -> x20] const char *mfEnd - exclusive
; @param ChemElement *elements
; @param unsigned *coeff,
; @param ChemikazeError **error
MfParser_readSymbolsAndCoeffs:
    stp fp, lr, [sp, -16]!
        mov fp, sp
    stp x19, x20, [sp, -16]!
        mov x19, x0
        mov x20, x1
    stp x21, x22, [sp, -16]!
MfParser_readSymbolsAndCoeffs__loop:
    cmp x19, x20
    b.eq MfParser_readSymbolsAndCoeffs__out
    ldrb w21, [x19], 1 ; isBigLetter?
        sub w22, w21, 'A'
            cmp w22, 26
                b.lo MfParser_readSymbolsAndCoeffs__bigLetter
        ; TODO: else if (isPunctuation(*i) || isDigit(*i)), and then the error case
    add x19, x19, 1
    b MfParser_readSymbolsAndCoeffs__loop
MfParser_readSymbolsAndCoeffs__bigLetter:
    adrp x0, MfParser_readSymbolsAndCoeffs__bigLetter_name@page
        add x0, x0, MfParser_readSymbolsAndCoeffs__bigLetter_name@pageoff
        bl _printf
    bl MfParser_consumeSymbolAndCoeff
    mov x0, 16
    b MfParser_readSymbolsAndCoeffs__loop
MfParser_readSymbolsAndCoeffs__out:
    ldp x21, x22, [sp], 16
    ldp x19, x20, [sp], 16
    ldp fp, lr, [sp], 16
    ret

; @param const char *mf - start of the MF
; @param const char **i - exclusive
; @param const char *mfEnd - exclusive
; @param [x3] ChemElement *resultElements
; @param [x4] unsigned *resultCoeff,
; @param ChemikazeError **error
MfParser_consumeSymbolAndCoeff:
    adrp x0, MfParser_consumeSymbolAndCoeff_name@page
        add x0, x0, MfParser_consumeSymbolAndCoeff_name@pageoff
        bl _printf
    mov x5, 'H'
    mov x6, 1
    str x5, [x3]
    str x6, [x4]
    ret

; @param char **i symbol to start with
; @param const char *mfEnd - end of the MF
; @var x2 *i address of the symbol
; @var w3 **i the symbol itself
; @var w4 the result (number)
; @var x5 i for the loop
; @var w10 is a constant 10 for multiplication
_MfParser_consumeCoeff:
    mov w10, 10
    mov w4, 1 ; result = 1 (default)
    ldr x2, [x0] ; load address *i
    cmp x2, x1 ; *i >= mfEnd
        b.hs _MfParser_consumeCoeff__ret
    ldrb w3, [x2] ; load value (symbol) **i
    sub w3, w3, '0' ;  0 <= i <= 9
        cmp w3, 9
            b.hi _MfParser_consumeCoeff__ret
    ; now let's calc the real result w4
    mov w4, 0 ; result = 0
_MfParser_consumeCoeff__loop:
    ; loop conditions:
    cmp x2, x1
        b.hs _MfParser_consumeCoeff__ret
    ldrb w3, [x2], 1 ; char c = *i
    sub w3, w3, '0' ;  0 <= i <= 9
        cmp w3, 9
        b.hi _MfParser_consumeCoeff__ret
    ; loop body:
    madd w4, w4, w10, w3 ; result = result * 10 + (**i - '0');
    ; store new i (incremented in the ldrb):
    str x2, [x0]
    b _MfParser_consumeCoeff__loop
_MfParser_consumeCoeff__ret:
    mov w0, w4
    ret

; @param void **oldPointer
; @param size_t newLen
; @return ChemikazeError* or nullptr
MfParser_reallocOrErr:
    stp fp, lr, [sp, -16]!
    mov fp, sp
    str x19, [sp, -8]!

    mov x2, x0

    ldr x0, [x0] ; realloc(*oldPointer, newLen)
        bl _realloc ; TODO: process OOM
    str x0, [x19] ; *oldPointer = newPointer;
    mov x0, 0 ; return nullptr if no error

    ldr x19, [sp], 8
    ldp fp, lr, [sp], 16
    ret

;
; @param ChemikazeCode code
; @param char *msg is owned by the error itself now, so the function owning the error must call the respective destructor
; @return ChemikazeError*
;
_ChemikazeError_new:
    stp fp, lr, [sp, -16]!
        mov fp, sp
    stp x19, x20, [sp, -16]!
        mov x19, x0
        mov x20, x1

    mov x0, ChemikazeError_SIZE
        mov x1, 1
        bl _calloc ; TODO: handle OOM
    str x19, [x0, ChemikazeError_code]
    str x20, [x0, ChemikazeError_msg]

    ldp x19, x20, [sp], 16
    ldp fp, lr, [sp], 16
    ret

; @param short symbol, where byte#0 is the big letter, and byte#1 is the small letter or 0
_ptable_getElementBySymbol_short:
    and w1, w0, 0xFF
    mov w2, 277
    mul w3, w1, w2
    ubfx w4, w0, 8, 8 ; take the 2nd byte
    eor w5, w3, w4
    and w6, w5, PTABLE_ELEMENTHASH_TO_ELEMENT_MASK
    adrp x7, PTABLE_ELEMENTHASH_TO_ELEMENT@page
    add x7, x7, PTABLE_ELEMENTHASH_TO_ELEMENT@pageoff
    ldrb w0, [x7, x6]
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