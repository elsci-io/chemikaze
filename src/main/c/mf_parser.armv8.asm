; Useful links:
;  https://developer.apple.com/documentation/xcode/writing-arm64-code-for-apple-platforms
;  https://github.com/ARM-software/abi-aa
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
.global _MfParser_parse
.global _MfParser_parseSanitized
.global _MfParser_parseOrPanic
.global _ptable_getElementBySymbol_short
.global _ptable_getElementBySymbol
.global _MfParser_consumeCoeff
.global _MfParser_consumeSymbolAndCoeff
.global _MfParser_readSymbolsAndCoeffs
.global _MfParser_scaleForward
.global _MfParser_scaleBackward
.global _MfParser_findAndApplyGroupCoeffs
.global _MfParser_combineIntoAtomCounts
.global _AtomCounts_new
.global _AtomCounts_free
.global _AtomCounts_toString

.data
    ; For use in ccmp where we have to set NZCV flags directly:
    .equ NZCV_EQ, 0b0100
    .equ NZCV_HI, 0b0010

    ; struct MfParser field offsets and so on:
    .equ MfParser_elements, 0
    .equ MfParser_coeffs, 8
    .equ MfParser_len, 16
    .equ MfParser_SIZE, 24 ; total size after alignment
    .equ MfParser_DEFAULT_ELEMENTS_CNT, 20 ; number of elements originally in the array

    .equ NULL, 0
    ; enum ChemikazeErrorCode:
    .equ ChemikazeErrorCode_PARSE, 0
    .equ ChemikazeErrorCode_OOM, 1
    .equ ChemikazeErrorCode_NULL_POINTER, 2

    ; struct ChemikazeError field offsets:
    .equ ChemikazeError_msg, 0 ; char *msg
    .equ ChemikazeError_code, 8 ; ChemikazeErrorCode
    .equ ChemikazeError_SIZE, 16 ; char *msg

    ; struct AtomCounts
    .equ AtomCounts_counts, 0 ; unsigned *counts;
    .equ AtomCounts_SIZE, 8
    .equ AtomCounts_TOTAL_SIZE, 348 ; array of earth elements (85 * 4) + ref to the array (8)
    .equ AtomCounts_EARTH_ELEMENT_CNT, 85

    ChemikazeError_EMPTY_MOL_MSG: .asciz "Empty Molecular Formula"
    ChemikazeError_NULL_MF_MSG: .asciz "MF is null"
    ChemikazeError_COULD_NOT_PARSE_MSG: .asciz "Couldn't parse "
    ChemikazeError_DOT_AND_SPACE_MSG: .asciz ". "
    ChemikazeError_PARENTH_DO_NOT_MATCH_MSG: .asciz "The opening and closing parentheses don't match."

    MF_PUNCTUATION_SYMBOLS: ; 7 symbols plus the duplicates to make it 16 bytes
        .byte '(', ')', '+', '-', '.', '[', ']', ']'
        .byte ']', ']', ']', ']', ']', ']', ']', ']'
    EARTH_SYMBOLS: ; see the analogous array in periodic_table.h. Each element is 3 bytes, with either one or two \0
        .ascii "H\0\0C\0\0O\0\0N\0\0P\0\0F\0\0S\0\0Br\0Cl\0Na\0Li\0Fe\0K\0\0Ca\0Mg\0Ni\0Al\0"
        .ascii "Pd\0Sc\0V\0\0Cu\0Cr\0Mn\0Co\0Zn\0Ga\0Ge\0As\0Se\0Ti\0Si\0Be\0B\0\0"
        .ascii "Kr\0Rb\0Sr\0Y\0\0Zr\0Nb\0Mo\0Ru\0Rh\0Ag\0Cd\0In\0Sn\0Sb\0Te\0I\0\0"
        .ascii "Xe\0Cs\0Ba\0La\0Ce\0Pr\0Nd\0Sm\0Eu\0Gd\0Tb\0Dy\0Ho\0Er\0Tm\0Yb\0"
        .ascii "Lu\0Hf\0Ta\0Tc\0W\0\0Re\0Os\0Ir\0Pt\0Au\0Hg\0Tl\0Pb\0Bi\0Th\0Pa\0"
        .ascii "U\0\0He\0Ne\0Ar\0"
    EARTH_SYMBOLS_LENGTHS:
        .byte 1,1,1,1,1,1,1,2,2,2,2,2,1,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,2,2,2,2,1,2,2,2,1,2
        .byte 2,2,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2
        .byte 2,2,2,2,2,1,2,2,2
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

; @param [x0->x20] MfParser *parser
; @param [x1->x21] const char *mf start of the molecular formula, possibly with extra whitespaces
; @param [x2->x22] ChemikazeError** to fill if error occurs
; @local [w3] MfNextChar
; @return x0 AtomCounts* or null. If null then check the error param.
_MfParser_parse:
    mfNextChar .req w3
    MfParser   .req x20
    Mf         .req x21
    Error      .req x22
    MfEnd      .req x23
    sub sp, sp, 0x30
        stp fp, lr, [sp, 0x20]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp, 0x0]
    mov MfParser, x0
        mov Mf, x1
        mov Error, x2
    cbz Mf, MfParser_parse__mfNullPointerError
    sub Mf, Mf, 1
    MfParser_parse__trimLeftLoop:
        add Mf, Mf, 1
        ldrb mfNextChar, [Mf]
        cmp Mf, ' '
            b.eq MfParser_parse__trimLeftLoop
    mov x0, Mf ; mfEnd = Mf + strlen(Mf) - 1
        bl _strlen
        add MfEnd, Mf, x0
    MfParser_parse__trimRightLoop:
        sub MfEnd, MfEnd, 1
        ldrb mfNextChar, [MfEnd]
        cmp mfNextChar, ' '
            b.eq MfParser_parse__trimRightLoop
    mov x0, MfParser
        mov x1, Mf
        add x2, MfEnd, 1
        mov x3, Error
        bl _MfParser_parseSanitized
        b MfParser_parse__ret
    MfParser_parse__mfNullPointerError:
        mov x0, ChemikazeErrorCode_NULL_POINTER
            adrp x1, ChemikazeError_NULL_MF_MSG@page
            add x1, x1, ChemikazeError_NULL_MF_MSG@pageoff
            bl _ChemikazeError_new
        str x0, [Error]
        mov x0, NULL
    MfParser_parse__ret:
        .unreq mfNextChar
        .unreq MfParser
        .unreq Mf
        .unreq Error
        .unreq MfEnd
        ldp fp, lr, [sp, 0x20]
        ldp x20, x21, [sp, 0x10]
        ldp x22, x23, [sp]
        add sp, sp, 0x30
        ret

; @param [x0->x20] MfParser *parser
; @param [x1->x21] const char *mf start of the molecular formula, possibly with extra whitespaces
; @local [x2] Error
_MfParser_parseOrPanic:
    MfParser .req x20
    Mf       .req x21
    error    .req x2
    sub sp, sp, 0x30
        stp lr, fp, [sp, 0x20]
        stp x20, x21, [sp, 0x10]
    mov MfParser, x0
        mov Mf, x1
    str xzr, [sp] ; error = NULL
    mov x2, sp
        bl _MfParser_parse
        ldr error, [sp]
    cbz x0, MfParser_parseOrPanic__error
    MfParser_parseOrPanic__ret:
        ldp lr, fp, [sp, 0x20]
        ldp x20, x21, [sp, 0x10]
        add sp, sp, 0x30
        ret
    MfParser_parseOrPanic__error:
        ldr x0, [error, ChemikazeError_msg]
            mov x1, 2 ; stderr
            bl _puts
        mov x0, error
            bl _ChemikazeError_destroy
        mov x16, 1
            mov x0, 62 ; error code
            svc 1
    .unreq MfParser
    .unreq Mf
    .unreq error
; Assumes you already trimmed the MF, and you're passing the right boundaries. If you didn't do this, then call
; a non-sanitized method.
;
; @param [x0->x20] MfParser *parser
; @param [x1->x21] const char *mf start of the molecular formula
; @param [x2->x22] const char *mfEnd end of the formula, exclusive
; @param [x3->x23] ChemikazeError** to fill if error occurs
; @return x0 AtomCounts* or null. If null then check the error param.
_MfParser_parseSanitized:
    Mf                    .req x21
    MfEnd                 .req x22
    Error                 .req x23
    MfParserCoeffsArray   .req x20
    MfParserElementsArray .req x24
    MfLen                 .req x25
    sub sp, sp, 0x40
        stp fp, lr, [sp, 0x30]
        mov fp, sp
        stp x20, x21, [sp, 0x20]
        stp x22, x23, [sp, 0x10]
        stp x24, x25, [sp, 0x00]
        mov Mf, x1 ; char *mf
        mov MfEnd, x2 ; char *mfEnd
        mov Error, x3  ; ChemikazeError* to be optionally filled
    cmp Mf, MfEnd
        b.hs MfParser_parseSanitized__emptyMfError
    sub MfLen, MfEnd, Mf
    ldr MfParserElementsArray, [x0, MfParser_elements]
    ldr MfParserCoeffsArray  , [x0, MfParser_coeffs]
    mov x0, Mf
        mov x1, MfEnd
        mov x2, MfParserElementsArray
        mov x3, MfParserCoeffsArray
        mov x4, Error
        bl _MfParser_readSymbolsAndCoeffs
    mov x0, Mf
        mov x1, MfEnd
        mov x2, MfParserCoeffsArray
        bl _MfParser_findAndApplyGroupCoeffs
    cbnz x0, MfParser_parseSanitized__nestedMethodReturnedError
    bl _AtomCounts_new
    mov x3, x0
        mov x0, MfParserElementsArray
        mov x1, MfParserCoeffsArray
        mov x2, MfLen
        bl _MfParser_combineIntoAtomCounts
    MfParser_parseSanitized__out:
        ldp fp, lr, [sp, 0x30]
        ldp x20, x21, [sp, 0x20]
        ldp x22, x23, [sp, 0x10]
        ldp x24, x25, [sp, 0x00]
        add sp, sp, 0x40
        ret
    MfParser_parseSanitized__nestedMethodReturnedError:
        str x0, [Error]
        mov x0, NULL
        b MfParser_parseSanitized__out
    MfParser_parseSanitized__emptyMfError:
        mov x0, ChemikazeErrorCode_PARSE
            adrp x1, ChemikazeError_EMPTY_MOL_MSG@page
            add x1, x1, ChemikazeError_EMPTY_MOL_MSG@pageoff
            bl _ChemikazeError_new
        str x0, [Error] ; return ChemikazeError*
        mov x0, 0 ; return null
        b MfParser_parseSanitized__out
    .unreq Mf
    .unreq MfEnd
    .unreq Error
    .unreq MfParserCoeffsArray
    .unreq MfParserElementsArray
    .unreq MfLen

; @param [x0] const ChemElement *elements
; @param [x1] const unsigned *coeffs
; @param [w2] size_t len, is used to decrement until it reaches -1 which would signify the look end
; @param [x3] AtomCounts *result
; @return AtomCounts *result
; @local [w15] result->counts
; @local [w14] coeffs[i]
; @local [w13] elements[i]
_MfParser_combineIntoAtomCounts:
    cmp x2, 0
        b.eq MfParser_combineIntoAtomCounts__ret
    sub x2, x2, 1
    add x15, x3, AtomCounts_counts ; (unsigned*)result->counts
    ldr x15, [x15] ; actual array result->counts
    MfParser_combineIntoAtomCounts__loop:
        ldr w14, [x1, x2, lsl 2] ; coeffs[i]
            cbz w14, MfParser_combineIntoAtomCounts__loop_continue
        ldrb w13, [x0, x2] ; elements[i]
        ldr w12, [x15, x13, lsl 2]; result->counts[elements[i]]
            add w12, w12, w14 ; result->counts[elements[i]] + coeffs[i]
            str w12, [x15, x13, lsl 2]; result->counts[elements[i]] += coeffs[i]
        MfParser_combineIntoAtomCounts__loop_continue:
        subs x2, x2, 1
        b.lo MfParser_combineIntoAtomCounts__ret ; when we reached -1, it means we iterated over every element
        b MfParser_combineIntoAtomCounts__loop
MfParser_combineIntoAtomCounts__ret:
    mov x0, x3
    ret

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

; const char *mf, const char *mfEnd/*exclusive*/, unsigned *resultCoeffs
; @param [x0 ->x20] mf the start of the MF string
; @param [x1 ->x21] mfEnd the end of the MF string, exclusive
; @param [x2 ->x22] resultCoeffs which coefficients to scale (only a specific region of MF will be scaled)
; @local [x24] - currStackDepth
; @local [x25 -> sp] - i, that starts with x0 and ends with x1
_MfParser_findAndApplyGroupCoeffs:
    Mf             .req x20
    MfEnd          .req x21
    ResultCoeffs   .req x22
    CurrStackDepth .req x24
    MfCurr         .req x25
    sub sp, sp, 0x40
        stp fp, lr, [sp, 0x30]
        mov fp, sp
        stp x20, x21, [sp, 0x20]
        stp x22, x24, [sp, 0x10]
        str x25, [sp, 0x08]
    mov Mf, x0 ; mf
        mov MfEnd, x1 ; mfEnd
        mov ResultCoeffs, x2 ; resultCoeffs
        mov CurrStackDepth, 0  ; currStackDepth
    mov MfCurr, x0 ; i
    MfParser_findAndApplyGroupCoeffs__loop:
        cmp MfCurr, MfEnd
            b.hs MfParser_findAndApplyGroupCoeffs__loopout
        str MfCurr, [sp]
        mov x0, sp
            mov x1, MfEnd
            bl _MfParser_consumeCoeff
        ldr MfCurr, [sp] ; the updated i value from consumeCoeff()
        mov x5, x0 ; coeff
            mov x0, Mf ; mf
            mov x1, MfEnd ; mfEnd
            mov x2, MfCurr ; lo
            mov x3, CurrStackDepth ; currStackDepth
            mov x4, ResultCoeffs ; resultCoeffs
            bl _MfParser_scaleForward
        cmp MfCurr, x1
            b.hs MfParser_findAndApplyGroupCoeffs__loopout
        MfParser_findAndApplyGroupCoeffs__whileAlphanumeric: ; // skip all letters, numbers
            ldrb w0, [MfCurr]
            sub x1, x0, 'A' ; is big letter
            sub x2, x0, 'a' ; is small letter
            sub x3, x0, '0' ; is digit
            cmp x1, 26
                cset x1, lo
            cmp x2, 26
                cset x2, lo
            cmp x3, 10
                cset x3, lo
            orr x4, x1, x2
                orr x5, x4, x3
                cbz x5, MfParser_findAndApplyGroupCoeffs__loop__isOpeningBracket
            cmp MfCurr, MfEnd ; if i >= mfEnd
                b.hs MfParser_findAndApplyGroupCoeffs__loopout
            add MfCurr, MfCurr, 1
            b MfParser_findAndApplyGroupCoeffs__whileAlphanumeric
        MfParser_findAndApplyGroupCoeffs__loop__isOpeningBracket:
            cmp x0, '(' ; loaded from MfCurr in the 1st line of the while loop
                b.ne MfParser_findAndApplyGroupCoeffs__loop__isClosingBracket
                add CurrStackDepth, CurrStackDepth, 1 ; currStackDepth++
                b MfParser_findAndApplyGroupCoeffs__loop_suffix
        MfParser_findAndApplyGroupCoeffs__loop__isClosingBracket:
            cmp x0, ')'
                b.ne MfParser_findAndApplyGroupCoeffs__loop_suffix
                sub x26, MfCurr, 1 ; chunkEnd for scaleBackward()
                add MfCurr, MfCurr, 1 ; i++
                str MfCurr, [sp] ; consumeCoeff(**i, mfEnd)
                    mov x0, sp
                    mov x1, MfEnd
                    bl _MfParser_consumeCoeff
                    ldr MfCurr, [sp]
                mov x4, x0 ; groupCoeff from previous consumeCoeff()
                    mov x0, Mf ; mf
                    mov x1, x26 ; chunkEnd aka hi
                    mov x2, CurrStackDepth ; currStackDepth
                    mov x3, ResultCoeffs
                    bl _MfParser_scaleBackward
                sub CurrStackDepth, CurrStackDepth, 1 ; currStackDepth--
                b MfParser_findAndApplyGroupCoeffs__loop
        MfParser_findAndApplyGroupCoeffs__loop_suffix:
            add MfCurr, MfCurr, 1
            b MfParser_findAndApplyGroupCoeffs__loop
    MfParser_findAndApplyGroupCoeffs__loopout:
        cbnz CurrStackDepth, MfParser_findAndApplyGroupCoeffs__unmatchedParenethError
    MfParser_findAndApplyGroupCoeffs__ret:
        ldp fp, lr, [sp, 0x30]
        ldp x20, x21, [sp, 0x20]
        ldp x22, x24, [sp, 0x10]
        ldr x25, [sp, 0x08]
        add sp, sp, 0x40
        ret
    MfParser_findAndApplyGroupCoeffs__unmatchedParenethError:
        adrp x0, ChemikazeError_PARENTH_DO_NOT_MATCH_MSG@page
            add x0, x0, ChemikazeError_PARENTH_DO_NOT_MATCH_MSG@pageoff
            mov x1, Mf
            sub x2, MfEnd, Mf
            bl _ChemikazeError_newParsing
        b MfParser_findAndApplyGroupCoeffs__ret
    .unreq Mf
    .unreq MfEnd
    .unreq ResultCoeffs
    .unreq CurrStackDepth
    .unreq MfCurr

; Scales whatever follows a number in situations like {@code 2H2O}, {@code Cl.2H}.
;
; @param [x0] mf the start of the MF string
; @param [x1] mfEnd the end of the MF string, exclusive
; @param [x2] lo the position inside mf where we start applying {@code groupCoeff} and go right from there
; @param [x3] currStackDepth how deep in () we are
; @param [x4] resultCoeff which coefficients to scale (only a specific region of MF will be scaled)
; @param [w5] groupCoeff the coefficient to scale the whole group of symbols
_MfParser_scaleForward:
    stp lr, fp, [sp, -16]!
        mov fp, sp
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
    ldp lr, fp, [sp], 16
    ret

; Scales whatever is in the parentheses like {@code (H2O)2}.
;
; @param [x0] mf the start pointer to the MF string
; @param [x1] current position (inclusive) of the closing parenthesis - to go back and find where it starts
; @param [w2] currStackDepth how deep in () we are
; @param [x3] resultCoeff which coefficients to scale (only a specific region of MF will be scaled)
; @param [w4] groupCoeff the coefficient to scale the whole group of symbols
_MfParser_scaleBackward:
    stp fp, lr, [sp, -16]!
        mov fp, sp
    mov w14, w2 ; depth = currStackDepth
MfParser_scaleBackward__loop:
    cmp x1, x0
        cset x13, lo
        cmp w14, w2
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
    ldp fp, lr, [sp], 16
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

_AtomCounts_new:
    ; Don't understand this, but if I don't persist fp & lr, malloc() hangs:
    ; https://stackoverflow.com/questions/21732487/how-to-call-malloc-in-arm64-ios-assembly
    stp fp, lr, [sp, -16]!
        mov fp, sp
    mov x0, AtomCounts_TOTAL_SIZE
        bl _malloc
    cbz x0, AtomCounts_new__ret
    mov x1, 0
        mov x2, AtomCounts_TOTAL_SIZE
        bl _memset
    ldr x1, [x0] ; load ref to the array: AtomCounts->counts
    add x1, x0, AtomCounts_SIZE ; the actual array is stored
        str x1, [x0]
AtomCounts_new__ret:
    ldp fp, lr, [sp], 16
    ret

_AtomCounts_free:
    stp fp, lr, [sp, -16]!
        mov fp, sp
    bl _free
    ldp fp, lr, [sp], 16
    ret
; @param [x0] AtomCounts*, which we immediately replace with Atom
; @local [x20] AtomCounts->counts, which is unsigned*
; @local [x21] reference to EARTH_SYMBOLS_LENGTHS
; @local [x22] len of the resulting string
_AtomCounts_toString:
    result              .req x0
    coeffLen            .req x1
    coeffOrder          .req w2
    three               .req x3
    earthSymbolsLengths .req x4 ; this is used in the first part of the function
    earthSymbols        .req x4 ; this one is used in the 2nd part
    ten                 .req w10
    ten_x               .req x10
    coeff               .req w14
    i                   .req x15
    strPos              .req x16
    CountsArrayRef      .req x20
    ResultLen           .req x21
    stp fp, lr, [sp, -0x10]
        mov fp, sp
        stp x20, x21, [sp, -0x20]
    sub sp, sp, 0x20

    mov w10, 10 ; just a constant
    ldr CountsArrayRef, [x0, AtomCounts_counts] ; AtomCounts->counts (unsigned*)
    ; First, calculate the len of the resulting string:
    adrp earthSymbolsLengths, EARTH_SYMBOLS_LENGTHS@page
        add earthSymbolsLengths, earthSymbolsLengths, EARTH_SYMBOLS_LENGTHS@pageoff
    mov ResultLen, 1 ; unsigned len = 1, as we'll add a '\0' at the end
    mov i, 0 ; unsigned i = 0
    AtomCounts_toString__len_counting_loop:
        ; count the number of letters in the symbol:
        ldr coeff, [CountsArrayRef, i, lsl 2] ; AtomCounts->counts[i]
        cbz coeff, AtomCounts_toString__len_counting_loop__continue ; if coeff==0, continue
        ldrb w11, [earthSymbolsLengths, i]
        add ResultLen, ResultLen, x11 ; len += EARTH_SYMBOLS_LENGTHS[i]
        cmp coeff, 1 ; we don't put "1" coeff to MF
            b.eq AtomCounts_toString__len_counting_loop__continue
        ; count the number of symbols in the coefficient:
        AtomCounts_toString__coeff_len_loop:
            add ResultLen, ResultLen, 1
            udiv coeff, coeff, ten
            cbz coeff, AtomCounts_toString__len_counting_loop__continue ; break out if reached 0
        AtomCounts_toString__len_counting_loop__continue:
            add i, i, 1 ; i++
            cmp i, AtomCounts_EARTH_ELEMENT_CNT ; if i == len
                b.ne AtomCounts_toString__len_counting_loop
    AtomCounts_toString__malloc:
        ; Now generate the actual string
        mov x0, ResultLen
            bl _malloc ; malloc(len)
    ; Go through each element in AtomCounts->counts, and:
    ; 1. The "i" of the array is the element. Write the symbol of the element to the result (if its coeff wasn't 0).
    ; 2. Form a string from the AtomCount-count (actual unsigned) and write it too
    mov i, 0 ; e - chem element idx
    mov strPos, 0 ; strPosition
    mov three, 3 ; num of bytes per symbol
    mov ten, 10 ; after the previous malloc(), it must be re-populated
    adrp earthSymbols, EARTH_SYMBOLS@page
        add earthSymbols, earthSymbols, EARTH_SYMBOLS@pageoff
    AtomCounts_toString__str_forming_loop:
        ldr coeff, [CountsArrayRef, i, lsl 2] ; AtomCounts->counts[i]
        cbz coeff, AtomCounts_toString__str_forming_loop__continue ; if coeff==0, continue
        mul x11, i, three ; each symbol is 3 bytes, so getting Nth element is N * 3
            ldrb w13, [earthSymbols, x11] ; EARTH_SYMBOLS[e][0]
            strb w13, [result, strPos] ; result[strPos] = EARTH_SYMBOLS[e][0]
            add strPos, strPos, 1 ; strPosition++
        add x11, x11, 1 ; loading next char of the symbol
            ldrb w13, [earthSymbols, x11] ; EARTH_SYMBOLS[e][0]
            cbz w13, AtomCounts_toString__skipSecondSymbol ; skipping if we ran into \0 (1-symbol element)
            strb w13, [result, strPos] ; result[strPos] = EARTH_SYMBOLS[e][0]
            add strPos, strPos, 1 ; strPosition++
        AtomCounts_toString__skipSecondSymbol:
        cmp coeff, 1 ; if coeff=1, we don't add it to the string
            b.eq AtomCounts_toString__str_forming_loop__continue
        ; Now finally write the coefficient, but for this we first need to know the order (1, 10, 100):
        AtomCounts_toString__coeff2_len_loop:
            mov coeffOrder, 1
            mov w13, coeff
            AtomCounts_toString__coeff2_len_loop__body:
                mul coeffOrder, coeffOrder, ten
                udiv w13, w13, ten
                cbnz w13, AtomCounts_toString__coeff2_len_loop__body ; break out if reached 0
        udiv coeffOrder, coeffOrder, ten ; removing extra 0 that we added in the loop
        ; We know the len of the coeff string, so form the actual string now:
        AtomCounts_toString__coeff_toStr:
            mov w13, coeff ; copy of the coeff
            AtomCounts_toString__coeff_toStr__loop:
                udiv w12, w13, coeffOrder ; coeff / 100 or whatever the order is
                    add w11, w12, '0' ; ascii symbol for the digit
                    strb w11, [result, strPos] ; str[strPos] = digit ascii
                add strPos, strPos, 1 ; strPos++
                msub w13, coeffOrder, w12, w13
                udiv coeffOrder, coeffOrder, ten ; coeffLen++
                cbnz coeffOrder, AtomCounts_toString__coeff_toStr__loop ; break out if reached 0
        AtomCounts_toString__str_forming_loop__continue:
            add i, i, 1 ; i++
            cmp i, AtomCounts_EARTH_ELEMENT_CNT ; if i == len
                b.ne AtomCounts_toString__str_forming_loop
    AtomCounts_toString__ret:
    add sp, sp, 0x20
    ldp fp, lr, [sp, -0x10]
    ldp x20, x21, [sp, -0x20]
    .unreq result
    .unreq coeffLen
    .unreq three
    .unreq ten
    .unreq coeff
    .unreq i
    .unreq strPos
    .unreq ResultLen
    .unreq CountsArrayRef
    .unreq earthSymbolsLengths
    ret

; @param ChemikazeCode code
; @param char *msg is owned by the error itself now, so the function owning the error must call the respective destructor
; @return ChemikazeError*
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

; @param [x0] const char *staticMsg
; @param [x1] const char *mf
; @param [x2] size_t mfLen
_ChemikazeError_newParsing:
    StaticMsg .req x20
    Mf        .req x21
    MfLen     .req x22
    Msg       .req x23
    msgLen    .req x0
    sub sp, sp, 0x30
        stp fp, lr, [sp, 0x20]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp]
    mov StaticMsg, x0
        mov Mf, x1
        mov MfLen, x2
    bl _strlen ; x0 still has staticMsg
    add msgLen, x0, 50 ; msgLen is x0 too
        add msgLen, msgLen, MfLen
        bl _malloc
    mov Msg, x0 ; strcpy(msg, "Couldn't parse ");
        adrp x1, ChemikazeError_COULD_NOT_PARSE_MSG@page
        add x1, x1, ChemikazeError_COULD_NOT_PARSE_MSG@pageoff
        bl _strcpy
    mov x0, Msg ; strncat(msg, mf, mfLen);
        mov x1, Mf
        mov x2, MfLen
        bl _strncat
    mov x0, Msg ; strcat(msg, ". ");
        adrp x1, ChemikazeError_DOT_AND_SPACE_MSG@page
        add x1, x1, ChemikazeError_DOT_AND_SPACE_MSG@pageoff
        bl _strcat
    mov x0, Msg ; strcat(msg, staticMsg);
        mov x1, StaticMsg
        bl _strcat
    mov x0, ChemikazeErrorCode_PARSE
        mov x1, Msg
        bl _ChemikazeError_new
    ldp fp, lr, [sp, 0x20]
    ldp x20, x21, [sp, 0x10]
    ldp x22, x23, [sp]
    add sp, sp, 0x30
    ret
    .unreq StaticMsg
    .unreq Mf
    .unreq MfLen
    .unreq Msg
    .unreq msgLen

_ChemikazeError_destroy:
    stp fp, lr, [sp, -0x10]!
    bl _free
    add sp, sp, 0x10
    ret

; @param [x0] - ref to the 2-byte array
_ptable_getElementBySymbol:
    char1 .req w1
    char2 .req w2
    coeff .req w3
    hash  .req w7
    hashX .req x7
    table .req x8
    ldrb char1, [x0]
    ldrb char2, [x0, 1]
    mov coeff, 277
    mul char1, char1, coeff
    eor hash, char1, char2
        and hash, hash, PTABLE_ELEMENTHASH_TO_ELEMENT_MASK
    adrp table, PTABLE_ELEMENTHASH_TO_ELEMENT@page
        add table, table, PTABLE_ELEMENTHASH_TO_ELEMENT@pageoff
    ldrb w0, [table, hashX]
    .unreq char1
    .unreq char2
    .unreq coeff
    .unreq hash
    .unreq hashX
    .unreq table
    ret

; @param short symbol, where byte#0 is the big letter, and byte#1 is the small letter or 0
_ptable_getElementBySymbol_short:
    char1 .req w1
    char2 .req w2
    coeff .req w3
    hash  .req w7
    hashX .req x7
    table .req x8
    and char1, w0, 0xFF
    mov coeff, 277
    mul char1, char1, coeff
    ubfx char2, w0, 8, 8 ; take the 2nd byte
    eor w5, char1, char2
    and hash, w5, PTABLE_ELEMENTHASH_TO_ELEMENT_MASK
    adrp table, PTABLE_ELEMENTHASH_TO_ELEMENT@page
    add table, table, PTABLE_ELEMENTHASH_TO_ELEMENT@pageoff
    ldrb w0, [table, hashX]
    .unreq char1
    .unreq char2
    .unreq coeff
    .unreq hash
    .unreq hashX
    .unreq table
    ret
