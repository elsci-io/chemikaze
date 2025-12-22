; Conventions:
; - If there's an "if" (cmp), the conditional jump has indentation
; - If we start preping params to call a function, assigning the 1st param doesn't have extra indentation, but
;   other lines related to the function call - those are indented
; Registers conventions:
; - x9 is "i" for loops, x15 is for the out condition:
;     for (x9 = initial; x15; x9++)
;   and if multiple conditions:
;     for(x9 = initial; x15 or x14; x9++)
; - x9 or x19 for the result in case we can't use x0
; - x20, x21, x22, x23, x24 are for the params if we need caller-saved registers

.global _isBigLetter
.global _MfParser_new
.global _MfParser_destroy
.global _MfParser_parseSanitized
.global _ptable_getElementBySymbol_short
.global _MfParser_consumeCoeff
.global _MfParser_consumeSymbolAndCoeff
.global _MfParser_readSymbolsAndCoeffs
.global _MfParser_scaleForward
.global _MfParser_scaleBackward

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

    MF_PUNCTUATION_SYMBOLS: ; 7 symbols plus the duplicates to make it 16 bytes
        .byte '(', ')', '+', '-', '.', '[', ']', ']'
        .byte ']', ']', ']', ']', ']', ']', ']', ']'
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
        bl _MfParser_readSymbolsAndCoeffs
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

; @param [x0 -> x20] const char *mf - start of the MF
; @param [x1 -> x21] const char *mfEnd (exclusive)
; @param [x2 -> x22] ChemElement *elements
; @param [x3 -> x23] unsigned *coeff,
; @param [x4 -> x24] ChemikazeError **error
; @local [w9] character *i references
; @local [x19] const *i = mf
_MfParser_readSymbolsAndCoeffs:
    stp fp, lr, [sp, -16]!
        mov fp, sp
    stp x20, x21, [sp, -16]!
        mov x20, x0 ; char *mf
        mov x21, x1 ; char *mfEnd
    str x19, [sp, -16]!
        mov x19, x0 ; char *i = mf
    stp x22, x23, [sp, -16]!
        mov x22, x2 ; ChemElement *elements
        mov x23, x3 ; unsigned *coeff
    add sp, sp, -16 ;

    adrp x6, MF_PUNCTUATION_SYMBOLS@page ; load punctuation into q1
        add x6, x6, MF_PUNCTUATION_SYMBOLS@pageoff
        ldr q1, [x6]
MfParser_readSymbolsAndCoeffs__loop:
    cmp x19, x21 ; if(i == mfEnd)
        b.eq MfParser_readSymbolsAndCoeffs__out ; break
    ldrb w9, [x19] ; load character *i references
        sub w9, w9, 'A' ; isBigLetter?
            cmp w9, 26
                b.lo MfParser_readSymbolsAndCoeffs__bigLetter
        sub w9, w9, '0'
            cmp w9, 9 ; is digit
            cset w7, ls
            dup v0.16b, w9 ; compare the symbol with the punctuation => w6
                cmeq v0.16b, v0.16b, v1.16b
                umaxv b0, v0.16b
                cset w6, ne
            orr w7, w7, w6
            cbnz w7, MfParser_readSymbolsAndCoeffs__digitOrPunctuation
    b MfParser_readSymbolsAndCoeffs__loop
MfParser_readSymbolsAndCoeffs__bigLetter:
    str x19, [sp]
    mov x0, x20 ; char *mf
        mov x1, sp ; char **i
        mov x2, x21 ; char *mfEnd
        mov x3, x22 ; ChemElement *resultElements
        mov x4, x23 ; unsigned *resultCoeff
        bl _MfParser_consumeSymbolAndCoeff
    ldr x19, [sp] ; load updates to *i that are made in consumeSymbolAndCoeff()
    b MfParser_readSymbolsAndCoeffs__loop
MfParser_readSymbolsAndCoeffs__digitOrPunctuation:
    add x19, x19, 1
    b MfParser_readSymbolsAndCoeffs__loop
MfParser_readSymbolsAndCoeffs__out:
    add sp, sp, 16
    ldp x22, x23, [sp], 16
    ldr x19, [sp], 16
    ldp x20, x21, [sp], 16
    ldp fp, lr, [sp], 16
    ret

; @param [x0->x20] const char *mf: start of the MF
; @param [x1->x21] const char **i: curr position within MF
; @param [x2->x22] const char *mfEnd, exclusive
; @param [x3->x23] ChemElement *resultElements
; @param [x4->x24] unsigned *resultCoeff
; @param [x5] ChemikazeError **error TODO: implement error handling
; @local [w10] - 2-byte symbol, the letters go in the opposite order: lC (for Cl), \0H for H\0
; @local [x11] char *i - pointer to the current element
; @local [w13] char *(i+1) - next element
; @local [x25] size_t resultPos
_MfParser_consumeSymbolAndCoeff:
    stp fp, lr, [sp, -16]!
        mov fp, sp
    stp x20, x21, [sp, -16]!
        mov x20, x0 ; char *mf
        mov x21, x1 ; char **i
    stp x22, x23, [sp, -16]!
        mov x22, x2 ; char *mfEnd
        mov x23, x3 ; ChemElement *resultElements
    stp x24, x25, [sp, -16]!
        mov x24, x4 ; unsigned *resultCoeff

    ldr x11, [x21] ; *i
    sub x25, x11, x20 ; size_t resultPos = *i - mf
    ldrb w10, [x11], 1 ; char symbol = ++(*i)
    str x11, [x21] ; store the incremented *i to **i
    ldrb w13, [x11], 1 ; load the next symbol
    sub w14, w13, 'a' ; if (++(*i) < mfEnd && isSmallLetter(**i))
        cmp w14, 26 ; isSmallLetter(*i)
            cset w9, hi
        cmp x11, x1 ; *i < mfEnd
            cset w8, hi
        orr w8, w8, w9 ; *i >= mfEnd || !isSmallLetter(w14)
        cbnz w8, MfParser_consumeSymbolAndCoeff__skip2ndSymbol
    bfi w10, w13, 8, 8 ; load 1st byte of w13 into w10, shifted by 8
    str x11, [x21] ; store the incremented *i to **i
MfParser_consumeSymbolAndCoeff__skip2ndSymbol:
    mov w0, w10 ;
        bl _ptable_getElementBySymbol_short
    strb w0, [x23, x25]
    mov x0, x21
        mov x1, x22
        bl _MfParser_consumeCoeff
    str w0, [x24, x25, lsl 2] ; resultCoeff[resultPos] = w0

    ldp x24, x25, [sp], 16
    ldp x22, x23, [sp], 16
    ldp x20, x21, [sp], 16
    ldp fp, lr, [sp], 16
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

; Scales whatever follows a number in situations like {@code 2H2O}, {@code Cl.2H}.
;
; @param [x0] mf the start of the MF string
; @param [x1] mfEnd the end of the MF string, exclusive
; @param [x2] lo the position inside mf where we start applying {@code groupCoeff} and go right from there
; @param [x3] currStackDepth how deep in () we are
; @param [x4] resultCoeff which coefficients to scale (only a specific region of MF will be scaled)
; @param [w5] groupCoeff the coefficient to scale the whole group of symbols
_MfParser_scaleForward:
    cmp w5, 1
        b.eq MfParser_scaleForward__ret
    ; for (int depth = currStackDepth):
    ;  * Incremented each time we run into '('.
    ;  * Once we reach a closing ')' (depth < currentStackDepth) or the end of MF - we're out.
    mov x9, x3
MfParser_scaleForward__loop:
    cmp x2, x1
        cset x15, lo
        cmp x9, x3
        cset x14, ge
        and x14, x14, x15
        cbz x14, MfParser_scaleForward__ret
    ldrb w12, [x2] ; *lo
    cmp w12, '('
        cinc x9, x9, eq
    cmp w12, ')'
        sub x14, x9, 1 ; precomputed decremented x12 in x14
        csel x9, x14, x9, eq
    cmp w12, '.' ; if(*lo == '.' && depth == currStackDepth)
        ccmp x9, x3, 0, eq
        b.eq MfParser_scaleForward__ret
    ; Now resultCoeff[lo - mf] *= groupCoeff
    sub x12, x2, x0 ; lo - mf
        ldr w10, [x4, x12, lsl 2] ;
        mul w10, w10, w5
        str w10, [x4, x12, lsl 2]
    add x2, x2, 1 ; lo++
    b MfParser_scaleForward__loop
MfParser_scaleForward__ret:
    ret

; Scales whatever is in the parentheses like {@code (H2O)2}.
;
; @param [x0] mf the start pointer to the MF string
; @param [x1] current position (inclusive) of the closing parenthesis - to go back and find where it starts
; @param [w2] currStackDepth how deep in () we are
; @param [x3] resultCoeff which coefficients to scale (only a specific region of MF will be scaled)
; @param [w4] groupCoeff the coefficient to scale the whole group of symbols
_MfParser_scaleBackward:
    mov w14, w2 ; depth = currStackDepth
MfParser_scaleBackward__loop:
    cmp x1, x0
        cset x13, lo
        cmp w2, w14
        cset x12, gt
        orr x13, x12, x13
        cbnz x13, MfParser_scaleBackward__ret
    ldrb w13, [x1]
    cmp w13, '('
        cinc w14, w14, eq
    sub w12, w14, 1 ; precomputed decremented w14 in w12
        cmp w13, ')'
        csel w14, w12, w14, eq
    ; resultCoeff[hi - mf] *= groupCoeff:
    sub x11, x1, x0 ; hi - mf
        ldr w10, [x3, x11, lsl 2]
        mul w10, w10, w4
        str w10, [x3, x11, lsl 2]
    sub x1, x1, 1 ; hi--
    b MfParser_scaleBackward__loop
MfParser_scaleBackward__ret:
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