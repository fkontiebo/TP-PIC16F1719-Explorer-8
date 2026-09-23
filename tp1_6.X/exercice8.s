PROCESSOR 16F1719
#include <xc.inc>

; --- Configuration ---
CONFIG WDTE = OFF
CONFIG MCLRE = ON

; --- Variables ---
PSECT udata_shr, class=COMMON, space=1, noexec
    compteur:  DS 1     ; compteur modulo 16
    ovf_cnt:   DS 1     ; débordements de TMR0 à attendre
    s1_now:    DS 1     ; état lu de S1

; --- Vecteur de Reset ---
PSECT resetVec, class=CODE, delta=2
resetVector:
    pagesel main
    goto    main

; --- Programme Principal ---
PSECT code, class=CODE, delta=2
main:
    BANKSEL ANSELB
    clrf    ANSELB
    BANKSEL ANSELD
    clrf    ANSELD
    BANKSEL TRISB
    movlw   0xF0
    movwf   TRISB
    BANKSEL TRISD
    movlw   0xF0
    movwf   TRISD

    ; TIMER0 : Fosc/4, prescaler 1:64
    BANKSEL OPTION_REG
    movlw   0b11000101      ; = 0xC5
    movwf   OPTION_REG

    BANKSEL compteur
    clrf    compteur

loop:
    BANKSEL compteur
    movf    compteur, w
    BANKSEL LATB
    movwf   LATB
    BANKSEL LATD
    movwf   LATD

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

    movlw   6               
    btfss   s1_now, 0       
    movlw   2               
    BANKSEL ovf_cnt
    movwf   ovf_cnt

    call    wait_timer

    BANKSEL compteur
    incf    compteur, f
    movlw   0x0F
    andwf   compteur, f

    goto    loop

wait_timer:
    bcf     INTCON, 2       
wt_loop:
    btfss   INTCON, 2       
    goto    wt_loop
    bcf     INTCON, 2
    decfsz  ovf_cnt, f
    goto    wt_loop
    return


