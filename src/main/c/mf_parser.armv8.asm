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
.file "mf_parser.armv8.s"
.global _isBigLetter
.global _MfParser_new
.global _MfParser_destroy
.global _MfParser_parse
.global _MfParser_parseOrPanic
.global _ptable_getElementBySymbol_short
.global _ptable_getElementBySymbol
.global _MfParser_consumeCoeff
.global _MfParser_consumeSymbolAndCoeff
.global _MfParser_scaleForward
.global _MfParser_scaleBackward
.global _MfParser_findAndApplyGroupCoeffs
.global _AtomCounts_free
.global _AtomCounts_toString

.data
    ; For use in ccmp where we have to set NZCV flags directly:
    .equ NZCV_EQ, 0b0100
    .equ NZCV_HI, 0b0010

    .equ stdout, 1
    .equ stderr, 2

    .equ INVALID_CHEM_ELEMENT, 255
    ; struct MfParser field offsets and so on:
    .equ MfParser_elements, 0
    .equ MfParser_coeffs, 8
    .equ MfParser_len, 16
    .equ MfParser_SIZE, 24 ; total size after alignment
    .equ MfParser_DEFAULT_ELEMENTS_CNT, 20 ; number of elements originally in the array

    .equ NULL, 0
    ; enum ChemikazeErrorCode:
    .equ ChemikazeErrorCode_UNKNOWN, 0
    .equ ChemikazeErrorCode_PARSE, 1
    .equ ChemikazeErrorCode_OOM, 2
    .equ ChemikazeErrorCode_NPE, 3
    .equ ChemikazeErrorCode_SIZE, 4

    ChemikazeErrorCode__logMsg__errorPrefix: .asciz "[ERROR] "
    .equ ChemikazeErrorCode__logMsg__errorPrefix__len, 8
    ChemikazeErrorCode__logMsg__semicolon: .asciz ": "
    ChemikazeErrorCode__logMsg__UNKNOWN: .asciz "UNKNOWN ERROR"
    ChemikazeErrorCode__logMsg__PARSE: .asciz "PARSE_ERROR"
    ChemikazeErrorCode__logMsg__OOM: .asciz "OOM"
    ChemikazeErrorCode__logMsg__NPE: .asciz "NPE"
    ChemikazeErrorCode__logMsg__NEW_LINE: .asciz "\n"

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
    ChemikazeError_UNKNOWN_CHEM_SYMBOL_MSG: .asciz "Unknown chemical symbol: %c%c" ; BE CAREFUL - THIS CANNOT BE LONGER AS THIS IS PUT ON STACK AND IS PASSED AS PARAM
    ChemikazeError_UNEXPECTED_SYMBOL_MSG: .asciz "Unexpected symbol: %c" ; BE CAREFUL - THIS CANNOT BE LONGER AS THIS IS PUT ON STACK AND IS PASSED AS PARAM

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
    .equ EARTH_SYMBOLS__CHAR_PER_ELEMENT, 3
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
    sub sp, sp, 0x20
    stp fp, lr, [sp] ; push old frame pointer and return address
    mov fp, sp
    stp x19, x20, [sp, 0x10] ; x19 will store the resulting pointer

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
    ldp fp, lr, [sp]; restore old frame pointer and return address
    ldp x19, x20, [sp, 0x10]
    add sp, sp, 0x20
 _MfParser_new_ret:
    ret

_MfParser_destroy:
    cbz x0, _MfParser_destroy_ret
    sub sp, sp, 0x20
        stp fp, lr, [sp] ; push old frame pointer and return address
        mov fp, sp
        str x19, [sp, 0x10] ; x19 is for MfParser*
    mov x19, x0 ; store MfParser* before invoking other methods
    ldr x0, [x19, MfParser_elements]
        cbz x0, MfParser_destroy_free_coeffs
        bl _free
    MfParser_destroy_free_coeffs:
        ldr x0, [x19, MfParser_coeffs]
            cbz x0, MfParser_destroy_free_MfParser
            bl _free
     MfParser_destroy_free_MfParser:
        mov x0, x19
            bl _free
    ldp fp, lr, [sp]; restore old frame pointer and return address
    ldr x19, [sp, 0x10] ; restore x19 register
    add sp, sp, 0x20
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
        stp fp, lr, [sp]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp, 0x20]
    mov MfParser, x0
        mov Mf, x1
        mov Error, x2
    cbz Mf, MfParser_parse__mfNullPointerError
    sub Mf, Mf, 1
    MfParser_parse__trimLeftLoop:
        add Mf, Mf, 1
        ldrb mfNextChar, [Mf]
        cmp mfNextChar, ' '
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
        mov x0, ChemikazeErrorCode_NPE
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
        ldp fp, lr, [sp]
        ldp x20, x21, [sp, 0x10]
        ldp x22, x23, [sp, 0x20]
        add sp, sp, 0x30
        ret

; @param [x0->x20] MfParser *parser
; @param [x1->x21] const char *mf start of the molecular formula, possibly with extra whitespaces
; @local [x2] Error
_MfParser_parseOrPanic:
    MfParser .req x20
    Mf       .req x21
    Error    .req x22
    sub sp, sp, 0x40
        stp lr, fp, [sp, 0x30]
        stp x20, x21, [sp, 0x20]
        stp x22, x23, [sp, 0x10]
    mov MfParser, x0
        mov Mf, x1
    str xzr, [sp] ; Error = NULL
    mov x2, sp
        bl _MfParser_parse
        ldr Error, [sp]
    cbz x0, MfParser_parseOrPanic__error
    MfParser_parseOrPanic__ret:
        ldp lr, fp, [sp, 0x30]
        ldp x20, x21, [sp, 0x20]
        ldp x22, x23, [sp, 0x10]
        add sp, sp, 0x40
        ret
    MfParser_parseOrPanic__error:
        ; Using write() here instead of puts() to document different options for stderr'ing
        ; write(stderr, "[ERROR] ", 8)
        mov x0, stderr
            adrp x1, ChemikazeErrorCode__logMsg__errorPrefix@page
            add x1, x1, ChemikazeErrorCode__logMsg__errorPrefix@pageoff
            mov x2, ChemikazeErrorCode__logMsg__errorPrefix__len
            bl _write
        ; strlen(ChemikazeError->msg)
        ldr x0, [Error, ChemikazeError_msg]
            bl _strlen
        ; write(stderr, ChemikazeError->msg, strlen(ChemikazeError->msg))
        mov x2, x0
            mov x0, stderr
            ldr x1, [Error, ChemikazeError_msg]
            bl _write
        mov x0, Error
            bl _ChemikazeError_destroy
        mov x16, 1
            mov x0, 62 ; error code
            svc 1
    .unreq MfParser
    .unreq Mf
    .unreq Error
; Assumes you already trimmed the MF, and you're passing the right boundaries. If you didn't do this, then call
; a non-sanitized method.
;
; @param [x0] MfParser *parser
; @param [x1] const char *mf start of the molecular formula
; @param [x2] const char *mfEnd end of the formula, exclusive
; @param [x3] ChemikazeError** to fill if error occurs
; @return x0 AtomCounts* or null. If null then check the error param.
.global _MfParser_parseSanitized
_MfParser_parseSanitized:
    MfParser              .req x19
    MfParserCoeffsArray   .req x20
    Mf                    .req x21
    MfEnd                 .req x22
    Error                 .req x23
    MfParserElementsArray .req x24
    MfLen                 .req x25
    sub sp, sp, 0x50
        stp fp, lr, [sp]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp, 0x20]
        stp x24, x25, [sp, 0x30]
        str x19, [sp, 0x40]
        mov MfParser, x0
        mov Mf, x1 ; char *mf
        mov MfEnd, x2 ; char *mfEnd
        mov Error, x3  ; ChemikazeError*
    cmp Mf, MfEnd
        b.hs MfParser_parseSanitized__emptyMfError
    sub MfLen, MfEnd, Mf
    ; ensureLengths()
    mov x1, MfLen
        mov x2, Error
        bl _MfParser_ensureLengths
         ; TODO: handle OOM from MfParser_ensureLengths
    ; Loading the possibly new MfParserElements after ensureLengths()
    ldr MfParserElementsArray, [MfParser, MfParser_elements]
    ldr MfParserCoeffsArray  , [MfParser, MfParser_coeffs]
    mov x0, Mf
        mov x1, MfEnd
        mov x2, MfParserElementsArray
        mov x3, MfParserCoeffsArray
        mov x4, Error
        bl _MfParser_readSymbolsAndCoeffs
    ldr x0, [Error]
    cbnz x0, MfParser_parseSanitized__nestedMethodReturnedError
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
        ldp fp, lr, [sp]
        ldp x20, x21, [sp, 0x10]
        ldp x22, x23, [sp, 0x20]
        ldp x24, x25, [sp, 0x30]
        ldr x19, [sp, 0x40]
        add sp, sp, 0x50
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
.global _MfParser_combineIntoAtomCounts
_MfParser_combineIntoAtomCounts:
    elements    .req x0
    coeffs      .req x1
    i           .req x2
    atomCounts  .req x3
    count       .req w12
    element     .req w13
    elementX    .req x13
    coeff       .req w14
    countsArray .req x15
    stp fp, lr, [sp, -16]!
        mov fp, sp
    cmp i, 0
        b.eq MfParser_combineIntoAtomCounts__ret
    sub i, i, 1
    ldr countsArray, [atomCounts, AtomCounts_counts] ; actual array result->counts
    MfParser_combineIntoAtomCounts__loop:
        ldr coeff, [coeffs, i, lsl 2] ; coeffs[i]
            cbz coeff, MfParser_combineIntoAtomCounts__loop_continue
        ldrb element, [elements, i] ; elements[i]
        ; result->counts[elements[i]] += coeffs[i]
        ldr count, [countsArray, elementX, lsl 2]
            add count, count, coeff ; result->counts[elements[i]] + coeffs[i]
            str count, [countsArray, elementX, lsl 2]; result->counts[elements[i]] += coeffs[i]
        MfParser_combineIntoAtomCounts__loop_continue:
        subs i, i, 1
        b.lo MfParser_combineIntoAtomCounts__ret ; when we reached -1, it means we iterated over every element
        b MfParser_combineIntoAtomCounts__loop
MfParser_combineIntoAtomCounts__ret:
    mov x0, atomCounts
    ldp fp, lr, [sp], 16
    .unreq elements
    .unreq coeffs
    .unreq i
    .unreq atomCounts
    .unreq count
    .unreq element
    .unreq coeff
    .unreq countsArray
    ret

; @param [x0 -> x20] const char *mf - start of the MF
; @param [x1 -> x21] const char *mfEnd (exclusive)
; @param [x2 -> x22] ChemElement *elements
; @param [x3 -> x23] unsigned *coeff,
; @param [x4 -> x24] ChemikazeError **error
; @local [w9] character *i references
; @local [x19] const *i = mf
.global _MfParser_readSymbolsAndCoeffs
_MfParser_readSymbolsAndCoeffs:
    currChar    .req w9
    I_          .req x19
    Mf          .req x20
    MfEnd       .req x21
    Elements .req x22
    Coeffs      .req x23
    Error       .req x24
    sub sp, sp, 0x50
        stp fp, lr, [sp]
        mov fp, sp
        stp x19, x20, [sp, 0x10]
        stp x21, x22, [sp, 0x20]
        stp x23, x24, [sp, 0x30]
        mov Mf, x0 ; char *mf
        mov MfEnd, x1 ; char *mfEnd
        mov I_, x0 ; char *i = mf
        mov Elements, x2 ; ChemElement *elements
        mov Coeffs, x3 ; unsigned *coeff
        mov Error, x4
    adrp x6, MF_PUNCTUATION_SYMBOLS@page ; load punctuation into q1
        add x6, x6, MF_PUNCTUATION_SYMBOLS@pageoff
        ldr q1, [x6]
    MfParser_readSymbolsAndCoeffs__loop:
        cmp I_, MfEnd ; if(i == mfEnd)
            b.eq MfParser_readSymbolsAndCoeffs__out ; break
        ldrb currChar, [I_] ; load character *i references
        sub w10, currChar, 'A' ; isBigLetter?
            cmp w10, 26
                b.lo MfParser_readSymbolsAndCoeffs__bigLetter
        sub w10, currChar, '0'
            cmp w10, 9 ; is digit
            cset w7, ls
            ; compare the symbol with the punctuation => w6
            dup v0.16b, currChar ; duplicate our character into 16 chars in v0
                cmeq v0.16b, v0.16b, v1.16b ; compare v0 and v1 byte-wise, set FF where equals
                umaxv b0, v0.16b ; take max byte out of v0 and put into the first byte of v0 (b0)
                umov w6, v0.b[0] ; put the first byte into w6
            orr w7, w7, w6
            cbnz w7, MfParser_readSymbolsAndCoeffs__digitOrPunctuation
        sub sp, sp, 0x30
            add x0, sp, 0x10 ; sprintf(msg, "Unexpected symbol: %c", *i);
                mov x1, 0x20
                adrp x2, ChemikazeError_UNEXPECTED_SYMBOL_MSG@page
                    add x2, x2, ChemikazeError_UNEXPECTED_SYMBOL_MSG@pageoff
                str currChar, [sp]
                bl _snprintf
            add x0, sp, 0x10
                mov x1, Mf
                sub x2, MfEnd, Mf
                bl _ChemikazeError_newParsing
            str x0, [Error]
        add sp, sp, 0x30
        mov x0, NULL
        b MfParser_readSymbolsAndCoeffs__out
    MfParser_readSymbolsAndCoeffs__bigLetter:
        str I_, [sp, 0x40]
        mov x0, Mf ; char *mf
            add x1, sp, 0x40 ; char **i
            mov x2, MfEnd ; char *mfEnd
            mov x3, Elements ; Elements *resultElements
            mov x4, Coeffs ; unsigned *resultCoeff
            mov x5, Error
            bl _MfParser_consumeSymbolAndCoeff
        ldr I_, [sp, 0x40] ; load updates to *i that are made in consumeSymbolAndCoeff()
        b MfParser_readSymbolsAndCoeffs__loop
    MfParser_readSymbolsAndCoeffs__digitOrPunctuation:
        add I_, I_, 1
        b MfParser_readSymbolsAndCoeffs__loop
    MfParser_readSymbolsAndCoeffs__out:
        ldp fp, lr, [sp]
        ldp x19, x20, [sp, 0x10]
        ldp x21, x22, [sp, 0x20]
        ldp x23, x24, [sp, 0x30]
        add sp, sp, 0x50
        .unreq currChar
        .unreq I_
        .unreq Mf
        .unreq MfEnd
        .unreq Elements
        .unreq Coeffs
        .unreq Error
        ret

; @param [x0->x20] const char *mf: start of the MF
; @param [x1->x21] const char **i: curr position within MF
; @param [x2->x22] const char *mfEnd, exclusive
; @param [x3->x23] ChemElement *resultElements
; @param [x4->x24] unsigned *resultCoeff
; @param [x5->x25] ChemikazeError
_MfParser_consumeSymbolAndCoeff:
    symbolShort    .req w10 ; 2-byte symbol, the letters go in the opposite order: lC (for Cl), \0H for H\0
    i_             .req x11 ; char *i - pointer to the current element
    Mf             .req x20
    I__            .req x21
    MfEnd          .req x22
    ResultElements .req x23
    ResultCoeffs   .req x24
    Error          .req x25
    ResultPos      .req x26 ; size_t resultPos
    SymbolByte1    .req w27
    SymbolByte1_x  .req x27
    SymbolByte2    .req w28
    SymbolByte2_x  .req x28
    sub sp, sp, 0x60
        stp fp, lr, [sp]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp, 0x20]
        stp x24, x25, [sp, 0x30]
        stp x26, x27, [sp, 0x40]
        str x28, [sp, 0x50]
    mov Mf, x0 ; char *mf
        mov I__, x1 ; char **i
        mov MfEnd, x2 ; char *mfEnd
        mov ResultElements, x3 ; ChemElement *resultElements
        mov ResultCoeffs, x4 ; unsigned *resultCoeff
        mov Error, x5 ; ChemikazeError
    ldr i_, [I__] ; *i
    sub ResultPos, i_, Mf ; size_t resultPos = *i - mf
    ldrb SymbolByte1, [i_], 1 ; char symbol = ++(*i)
    str i_, [I__] ; store the incremented *i to **i
    ldrb SymbolByte2, [i_], 1 ; load the next symbol
    mov symbolShort, SymbolByte1
    sub w14, SymbolByte2, 'a' ; if (++(*i) < mfEnd && isSmallLetter(**i))
        cmp w14, 26 ; isSmallLetter(*i)
            cset w6, hi
        cmp i_, x1 ; *i < mfEnd
            cset w7, hi
        orr w7, w7, w6 ; *i >= mfEnd || !isSmallLetter(w14)
        cbnz w7, MfParser_consumeSymbolAndCoeff__skip2ndSymbol
    bfi symbolShort, SymbolByte2, 8, 8 ; load 1st byte of w13 into w10, shifted by 8
    str i_, [I__] ; store the incremented *i to **i
    MfParser_consumeSymbolAndCoeff__skip2ndSymbol:
        mov SymbolByte2, 0
        mov w0, symbolShort ;
            bl _ptable_getElementBySymbol_short
        cmp w0, INVALID_CHEM_ELEMENT
            b.eq MfParser_consumeSymbolAndCoeff__invalidChemElementError
        strb w0, [ResultElements, ResultPos]
        mov x0, I__
            mov x1, MfEnd
            bl _MfParser_consumeCoeff
        str w0, [ResultCoeffs, ResultPos, lsl 2] ; resultCoeff[resultPos] = w0
    MfParser_consumeSymbolAndCoeff__ret:
        ldp fp, lr, [sp]
        ldp x20, x21, [sp, 0x10]
        ldp x22, x23, [sp, 0x20]
        ldp x24, x25, [sp, 0x30]
        ldp x26, x27, [sp, 0x40]
        ldr x28, [sp, 50]
        add sp, sp, 0x60
        ret
    MfParser_consumeSymbolAndCoeff__invalidChemElementError:
        sub sp, sp, 0x30 ; [0x10 bytes for symbol1 and symbol 2 params, 0x20 bytes for errorMsg]
            add x0, sp, 0x10
                mov x1, 0x20 ; max len of the string is 32 bytes
                adrp x2, ChemikazeError_UNKNOWN_CHEM_SYMBOL_MSG@page
                add x2, x2, ChemikazeError_UNKNOWN_CHEM_SYMBOL_MSG@pageoff
                stp SymbolByte1_x, SymbolByte2_x, [sp]
                bl _snprintf
            add x0, sp, 0x10
                mov x1, Mf
                sub x2, MfEnd, Mf
                bl _ChemikazeError_newParsing
        add sp, sp, 0x30
        str x0, [Error]
        mov x0, NULL
        b MfParser_consumeSymbolAndCoeff__ret
        .unreq SymbolByte1
        .unreq SymbolByte1_x
        .unreq SymbolByte2
        .unreq SymbolByte2_x
        .unreq symbolShort
        .unreq i_
        .unreq Mf
        .unreq I__
        .unreq MfEnd
        .unreq ResultElements
        .unreq ResultCoeffs
        .unreq Error
        .unreq ResultPos

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
        stp fp, lr, [sp]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x24, [sp, 0x20]
        str x25, [sp, 0x30]
    mov Mf, x0 ; mf
        mov MfEnd, x1 ; mfEnd
        mov ResultCoeffs, x2 ; resultCoeffs
        mov CurrStackDepth, 0  ; currStackDepth
    mov MfCurr, x0 ; i
    MfParser_findAndApplyGroupCoeffs__loop:
        cmp MfCurr, MfEnd
            b.hs MfParser_findAndApplyGroupCoeffs__loopout
        str MfCurr, [sp, 0x38]
        add x0, sp, 0x38
            mov x1, MfEnd
            bl _MfParser_consumeCoeff
        ldr MfCurr, [sp, 0x38] ; the updated i value from consumeCoeff()
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
                str MfCurr, [sp, 0x38] ; consumeCoeff(**i, mfEnd)
                    add x0, sp, 0x38
                    mov x1, MfEnd
                    bl _MfParser_consumeCoeff
                    ldr MfCurr, [sp, 0x38]
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
        mov x0, NULL ; returning no error
    MfParser_findAndApplyGroupCoeffs__ret:
        ldp fp, lr, [sp]
        ldp x20, x21, [sp, 0x10]
        ldp x22, x24, [sp, 0x20]
        ldr x25, [sp, 0x30]
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
    mf             .req x0
    mfEnd          .req x1
    lo             .req x2
    currStackDepth .req x3
    resultCoeffs   .req x4
    groupCoeff     .req w5
    stackDepth     .req x9
    currCoeff      .req w10
    currChar       .req w12
    mfIdx          .req x13
    stp lr, fp, [sp, -16]!
        mov fp, sp
    cmp groupCoeff, 1
        b.eq MfParser_scaleForward__ret
    ; for (int depth = currStackDepth):
    ;  * Incremented each time we run into '('.
    ;  * Once we reach a closing ')' (depth < currentStackDepth) or the end of MF - we're out.
    mov stackDepth, currStackDepth
MfParser_scaleForward__loop:
    cmp lo, mfEnd
        cset x15, lo
        cmp stackDepth, currStackDepth
        cset x14, ge
        and x14, x14, x15
        cbz x14, MfParser_scaleForward__ret
    ldrb currChar, [lo] ; *lo
    cmp currChar, '('
        cinc stackDepth, stackDepth, eq
    cmp currChar, ')'
        sub x14, stackDepth, 1 ; precomputed decremented x12 in x14
        csel stackDepth, x14, stackDepth, eq
    cmp currChar, '.' ; if(*lo == '.' && depth == currStackDepth)
        ccmp stackDepth, currStackDepth, 0, eq
        b.eq MfParser_scaleForward__ret
    ; Now resultCoeff[lo - mf] *= groupCoeff
    sub mfIdx, lo, mf ; lo - mf
        ldr currCoeff, [resultCoeffs, mfIdx, lsl 2] ;
        mul currCoeff, currCoeff, groupCoeff
        str currCoeff, [resultCoeffs, mfIdx, lsl 2]
    add lo, lo, 1 ; lo++
    b MfParser_scaleForward__loop
MfParser_scaleForward__ret:
    ldp lr, fp, [sp], 16
    .unreq mf
    .unreq mfEnd
    .unreq lo
    .unreq currStackDepth
    .unreq resultCoeffs
    .unreq groupCoeff
    .unreq stackDepth
    .unreq currCoeff
    .unreq currChar
    .unreq mfIdx
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

; @param [x0] MfParser *parser
; @param [x1] size_t mfLen
; @param [x2] Error** for OOMs
.global _MfParser_ensureLengths
_MfParser_ensureLengths:
    MfParser_          .req x20
    MfLen              .req x21
    mfParserLen        .req x2
    MfParserCoeffs_    .req x22
    MfParserElements_  .req x23
    sub sp, sp, 0x30
        stp fp, lr, [sp]
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp, 0x20]
        mov fp, sp
        mov MfParser_, x0
        mov MfLen, x1
    ldr mfParserLen, [MfParser_, MfParser_len]
    ldr MfParserCoeffs_, [MfParser_, MfParser_coeffs]
    ldr MfParserElements_, [MfParser_, MfParser_elements]
    cmp MfLen, mfParserLen ; if the existing arrays are already enough to fit the MF, then just clear them
        b.ls MfParser_ensureLengths__clearArrays
    ; realloc(coeffs)
    mov x0, MfParserCoeffs_
        lsl x1, MfLen, 2
        bl _realloc
        mov MfParserCoeffs_, x0
        str x0, [MfParser_, MfParser_coeffs]
    ; realloc(elements)
    mov x0, MfParserElements_
        mov x1, MfLen
        bl _realloc
        mov MfParserElements_, x0
        str x0, [MfParser_, MfParser_elements]
    str MfLen, [MfParser_, MfParser_len]
    MfParser_ensureLengths__clearArrays:
        ; memset(coeffs, 0, mfLen * sizeof(unsigned))
        mov x0, MfParserCoeffs_
            mov x1, 0
            lsl x2, MfLen, 2 ; coeffs are 4 byte unsigned integers
            bl _memset
        ; memset(elements, 0, mfLen)
        mov x0, MfParserElements_
            mov x1, 0
            mov x2, MfLen
            bl _memset
    ldp fp, lr, [sp]
    ldp x20, x21, [sp, 0x10]
    ldp x22, x23, [sp, 0x20]
    add sp, sp, 0x30
    .unreq MfParser_
    .unreq MfLen
    .unreq MfParserCoeffs_
    .unreq MfParserElements_
    .unreq mfParserLen
    ret

.global _AtomCounts_new
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
    sub sp, sp, 0x20
        stp fp, lr, [sp]
        mov fp, sp
        stp x20, x21, [sp, 0x10]

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
        ldp fp, lr, [sp]
        ldp x20, x21, [sp, 0x10]
        add sp, sp, 0x20
        .unreq result
        .unreq coeffLen
        .unreq coeffOrder
        .unreq three
        .unreq earthSymbolsLengths
        .unreq earthSymbols
        .unreq ten
        .unreq ten_x
        .unreq coeff
        .unreq i
        .unreq strPos
        .unreq CountsArrayRef
        .unreq ResultLen
        ret

; @param ChemikazeCode code
; @param char *msg is owned by the error itself now, so the function owning the error must call the respective destructor
; @return ChemikazeError*
_ChemikazeError_new:
    sub sp, sp, 0x20
        stp fp, lr, [sp]
        mov fp, sp
        stp x19, x20, [sp, 0x10]
        mov x19, x0
        mov x20, x1

    mov x0, ChemikazeError_SIZE
        mov x1, 1
        bl _calloc ; TODO: handle OOM
    str x19, [x0, ChemikazeError_code]
    str x20, [x0, ChemikazeError_msg]

    ldp fp, lr, [sp]
    ldp x19, x20, [sp, 0x10]
    add sp, sp, 0x20
    ret

; @param [x0] const char *staticMsg
; @param [x1] const char *mf
; @param [x2] size_t mfLen
.global _ChemikazeError_newParsing
_ChemikazeError_newParsing:
    StaticMsg .req x20
    Mf        .req x21
    MfLen     .req x22
    Msg       .req x23
    msgLen    .req x0
    sub sp, sp, 0x30
        stp fp, lr, [sp]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp, 0x20]
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
    ldp fp, lr, [sp]
    ldp x20, x21, [sp, 0x10]
    ldp x22, x23, [sp, 0x20]
    add sp, sp, 0x30
    ret
    .unreq StaticMsg
    .unreq Mf
    .unreq MfLen
    .unreq Msg
    .unreq msgLen

; @param [x0] ChemikazeError*
.global _ChemikazeError_logAndDestroy
_ChemikazeError_logAndDestroy:
    str x20, [sp, -16]!
        mov x20, x0
    bl _ChemikazeError_log
    mov x0, x20
        bl _ChemikazeError_destroy
    ldr x20, [sp], 16

; @param [x0] ChemikazeError*
.global _ChemikazeError_log
_ChemikazeError_log:
    errorCode      .req x1
    Error          .req x20
    ErrorMsgPrefix .req x21
    Error_msg      .req x21 ; need it after ErrorMsgPrefix isn't needed, so reusing the register
    StdErr         .req x22
    sub sp, sp, 0x30
        stp fp, lr, [sp]
        mov fp, sp
        stp x20, x21, [sp, 0x10]
        stp x22, x23, [sp, 0x20]
    mov Error, x0
    ldr errorCode, [x0, ChemikazeError_code]
    cbz errorCode, ChemikazeError_log__unknown
    cmp errorCode, ChemikazeErrorCode_SIZE
        b.hs ChemikazeError_log__unknown
    cmp errorCode, ChemikazeErrorCode_OOM
        b.eq ChemikazeError_log__oom
    cmp errorCode, ChemikazeErrorCode_NPE
        b.eq ChemikazeError_log__npe
    cmp errorCode, ChemikazeErrorCode_PARSE
        b.eq ChemikazeError_log__parse
    ChemikazeError_log__oom:
        adrp ErrorMsgPrefix, ChemikazeErrorCode__logMsg__OOM@page
        add ErrorMsgPrefix, ErrorMsgPrefix, ChemikazeErrorCode__logMsg__OOM@pageoff
        b ChemikazeError_log__print
    ChemikazeError_log__npe:
        adrp ErrorMsgPrefix, ChemikazeErrorCode__logMsg__NPE@page
        add ErrorMsgPrefix, ErrorMsgPrefix, ChemikazeErrorCode__logMsg__NPE@pageoff
        b ChemikazeError_log__print
    ChemikazeError_log__unknown:
        adrp ErrorMsgPrefix, ChemikazeErrorCode__logMsg__UNKNOWN@page
        add ErrorMsgPrefix, ErrorMsgPrefix, ChemikazeErrorCode__logMsg__UNKNOWN@pageoff
        b ChemikazeError_log__print
    ChemikazeError_log__parse: ; the most common, so goes last and doesn't have extra 'b'
        adrp ErrorMsgPrefix, ChemikazeErrorCode__logMsg__PARSE@page
        add ErrorMsgPrefix, ErrorMsgPrefix, ChemikazeErrorCode__logMsg__PARSE@pageoff
    ChemikazeError_log__print:
        ; The address of stderr isn't known at compile-time or link-time as the stdlib is loaded dynamically
        ; when the process starts: DYLD_INSERT_LIBRARIES=libmystdio.dylib ./your_program
        ; Thus we must use GOT (Global Offset Table) page instead of statically-defined @page.
        ; This takes 3 steps:
        ;  1) Loading address to GOT entry
        ;  2) Loading the address of the pointer (FILE**) from GOT
        ;  3) Loading the actual pointer FILE*
        ; In this particular case we should probably use write(fd), but left it as is as this represents the results
        ; of my research.
        adrp StdErr, ___stderrp@gotpage ; computing FILE*** (GOT entry ref)
            ldr StdErr, [StdErr, ___stderrp@gotpageoff] ; loading FILE** from GOT
            ldr StdErr, [StdErr] ; finally loading FILE*
        adrp x0, ChemikazeErrorCode__logMsg__errorPrefix@page
            add x0, x0, ChemikazeErrorCode__logMsg__errorPrefix@pageoff
            mov x1, StdErr
            bl _fputs
        mov x0, ErrorMsgPrefix
            mov x1, StdErr
            bl _fputs
        ldr Error_msg, [Error, ChemikazeError_msg]
        cbz Error_msg, ChemikazeError_log__finalNewLine

        adrp x0, ChemikazeErrorCode__logMsg__semicolon@page
            add x0, x0, ChemikazeErrorCode__logMsg__semicolon@pageoff
            mov x1, StdErr
            bl _fputs
        mov x0, Error_msg
            mov x1, StdErr
            bl _fputs
    ChemikazeError_log__finalNewLine:
        adrp x0, ChemikazeErrorCode__logMsg__NEW_LINE@page ; this definitely should've been write(), but can't mix it with fprintf due to buffering
            add x0, x0, ChemikazeErrorCode__logMsg__NEW_LINE@pageoff
            mov x1, StdErr
            bl _fputs
    ChemikazeError_log__ret:
        ldp fp, lr, [sp]
        ldp x20, x21, [sp, 0x10]
        ldp x22, x23, [sp, 0x20]
        add sp, sp, 0x30
        ret
        .unreq errorCode
        .unreq Error
        .unreq ErrorMsgPrefix
        .unreq Error_msg


; @param [x0->x20] ChemikazeError
_ChemikazeError_destroy:
    Error    .req x20
    ErrorMsg .req x21
    sub sp, sp, 0x20
        stp fp, lr, [sp]
        stp x20, x21, [sp, 0x10]
        mov fp, sp
    add ErrorMsg, x0, ChemikazeError_msg
    cbz ErrorMsg, ChemikazeError_destroy__freeError
    mov x0, ErrorMsg
        bl _free
    ChemikazeError_destroy__freeError:
        mov x0, Error
            bl _free
    ldp fp, lr, [sp]
    ldp x20, x21, [sp, 0x10]
    add sp, sp, 0x20
    ret

; @param [x0] - ref to the 2-byte array
_ptable_getElementBySymbol:
    result       .req w0
    char1        .req w1
    char2        .req w2
    coeff        .req w3
    hash         .req w7
    hashX        .req x7
    table        .req x8
    earthSymbols .req x9
    symbolChar1  .req w10
    symbolChar2  .req w11
    ldrb char1, [x0]
    ldrb char2, [x0, 1]
    mov coeff, 277
    mul hash, char1, coeff
        eor hash, hash, char2
        and hash, hash, PTABLE_ELEMENTHASH_TO_ELEMENT_MASK
    adrp table, PTABLE_ELEMENTHASH_TO_ELEMENT@page
        add table, table, PTABLE_ELEMENTHASH_TO_ELEMENT@pageoff
    ldrb result, [table, hashX]
    ; now check the symbol actually corresponds to whatever was requested
    mov w13, EARTH_SYMBOLS__CHAR_PER_ELEMENT
    mul w13, w13, result
    adrp earthSymbols, EARTH_SYMBOLS@page
        add earthSymbols, earthSymbols, EARTH_SYMBOLS@pageoff
    ldrb symbolChar1, [earthSymbols, x13]
    add x13, x13, 1
    ldrb symbolChar2, [earthSymbols, x13]
    cmp symbolChar1, char1
        ccmp symbolChar2, char2, NZCV_HI, eq
        b.eq ptable_getElementBySymbol__out
    mov result, INVALID_CHEM_ELEMENT
    ptable_getElementBySymbol__out:
;        ldrp w9, [w0]
        .unreq result
        .unreq char1
        .unreq char2
        .unreq coeff
        .unreq hash
        .unreq hashX
        .unreq table
        .unreq earthSymbols
        .unreq symbolChar1
        .unreq symbolChar2
        ret

; @param short symbol, where byte#0 is the big letter, and byte#1 is the small letter or 0
_ptable_getElementBySymbol_short:
    result       .req w0
    char1        .req w1
    char2        .req w2
    coeff        .req w3
    hash         .req w7
    hashX        .req x7
    table        .req x8
    earthSymbols .req x9
    symbolChar1  .req w10
    symbolChar2  .req w11
    and char1, w0, 0xFF
    mov coeff, 277
    mul hash, char1, coeff
    ubfx char2, w0, 8, 8 ; take the 2nd byte
    eor w5, hash, char2
    and hash, w5, PTABLE_ELEMENTHASH_TO_ELEMENT_MASK
    adrp table, PTABLE_ELEMENTHASH_TO_ELEMENT@page
    add table, table, PTABLE_ELEMENTHASH_TO_ELEMENT@pageoff
    ldrb result, [table, hashX]
    ; now check the symbol actually corresponds to whatever was requested
    mov w13, EARTH_SYMBOLS__CHAR_PER_ELEMENT
    mul w13, w13, result
    adrp earthSymbols, EARTH_SYMBOLS@page
        add earthSymbols, earthSymbols, EARTH_SYMBOLS@pageoff
    ldrb symbolChar1, [earthSymbols, x13]
    add x13, x13, 1
    ldrb symbolChar2, [earthSymbols, x13]
    cmp symbolChar1, char1
        ccmp symbolChar2, char2, NZCV_HI, eq
        b.eq ptable_getElementBySymbol_short__out
    mov result, INVALID_CHEM_ELEMENT
    ptable_getElementBySymbol_short__out:
;        ldrp w9, [w0]
        .unreq result
        .unreq char1
        .unreq char2
        .unreq coeff
        .unreq hash
        .unreq hashX
        .unreq table
        .unreq earthSymbols
        .unreq symbolChar1
        .unreq symbolChar2
        ret
