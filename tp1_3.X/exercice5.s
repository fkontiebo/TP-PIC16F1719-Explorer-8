PROCESSOR 16F1719
#include <xc.inc>

; --- Configuration ---
CONFIG WDTE = OFF
CONFIG MCLRE = ON

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
    bsf     TRISB, 0        
    bcf     TRISB, 1        

    BANKSEL TRISD
    bcf     TRISD, 0

    BANKSEL LATB
    clrf    LATB
    BANKSEL LATD
    clrf    LATD

loop:
    BANKSEL PORTB
    btfss   PORTB, 0        
    goto    s1_on
    BANKSEL LATD
    bcf     LATD, 0
    goto    test_s2
s1_on:
    BANKSEL LATD
    bsf     LATD, 0

test_s2:
    BANKSEL PORTA
    btfss   PORTA, 5      
    goto    s2_on
    BANKSEL LATB
    bcf     LATB, 1
    goto    loop
s2_on:
    BANKSEL LATB
    bsf     LATB, 1
    goto    loop