PROCESSOR 16F1719
#include <xc.inc>

; --- Configuration ---
CONFIG WDTE = OFF
CONFIG MCLRE = ON

; --- Variables ---
PSECT udata_shr, class=COMMON, space=1, noexec
    cptB:    DS 1        
    cptD:    DS 1       
    s1_old:  DS 1        
    s2_old:  DS 1        
    s1_now:  DS 1        
    d1:      DS 1
    d2:      DS 1

; --- Vecteur de Reset ---
PSECT resetVec, class=CODE, delta=2
resetVector:
    pagesel main
    goto    main

; --- Programme Principal ---
PSECT code, class=CODE, delta=2
main:
    BANKSEL ANSELA
    clrf    ANSELA
    BANKSEL ANSELB
    clrf    ANSELB
    BANKSEL ANSELD
    clrf    ANSELD

    BANKSEL TRISA
    bsf     TRISA, 5

    BANKSEL TRISB
    movlw   0xF0
    movwf   TRISB

    BANKSEL TRISD
    movlw   0xF0
    movwf   TRISD

    BANKSEL cptB
    clrf    cptB
    clrf    cptD
    movlw   1              
    movwf   s1_old
    movwf   s2_old

loop:
 
    BANKSEL TRISB
    bsf     TRISB, 0        
    nop                     
    nop
    BANKSEL PORTB
    clrf    s1_now
    btfsc   PORTB, 0        
    bsf     s1_now, 0       
    BANKSEL TRISB
    bcf     TRISB, 0        

    btfsc   s1_now, 0      
    goto    s1_relache
    BANKSEL s1_old
    btfsc   s1_old, 0      
    incf    cptB, f         ; 
    clrf    s1_old
    goto    test_s2
s1_relache:
    BANKSEL s1_old
    bsf     s1_old, 0

test_s2:

    BANKSEL PORTA
    btfsc   PORTA, 5
    goto    s2_relache
    BANKSEL s2_old
    btfsc   s2_old, 0
    decf    cptD, f
    clrf    s2_old
    goto    affichage
s2_relache:
    BANKSEL s2_old
    bsf     s2_old, 0

affichage:
    BANKSEL cptB
    movlw   0x0F
    andwf   cptB, f
    andwf   cptD, f

    movf    cptB, w
    andlw   0x0F
    BANKSEL LATB
    movwf   LATB

    BANKSEL cptD
    movf    cptD, w
    andlw   0x0F
    BANKSEL LATD
    movwf   LATD

    call    debounce
    goto    loop

debounce:
    movlw   50
    movwf   d2
db2:
    movlw   255
    movwf   d1
db1:
    decfsz  d1, f
    goto    db1
    decfsz  d2, f
    goto    db2
    return