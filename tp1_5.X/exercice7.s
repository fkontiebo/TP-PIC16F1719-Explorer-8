PROCESSOR 16F1719
#include <xc.inc>

; --- Configuration ---
CONFIG WDTE = OFF
CONFIG MCLRE = ON

; --- Variables ---
PSECT udata_shr, class=COMMON, space=1, noexec
    compteur:  DS 1     
    ovf_cnt:   DS 1     

; --- Vecteur de Reset ---
PSECT resetVec, class=CODE, delta=2
resetVector:
    pagesel main
    goto    main

; --- Programme Principal ---
PSECT code, class=CODE, delta=2
main:
    ; --- Configuration des broches ---
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

    ; --- Configuration du TIMER0 ---
    ; TMR0CS=0 : horloge interne Fosc/4
    ; PSA=0    : prédiviseur affecté à TMR0
    ; PS=101   : prédiviseur 1:64
    BANKSEL OPTION_REG
    movlw   0b11000101      ; = 0xC5
    movwf   OPTION_REG

    ; --- Initialisation ---
    BANKSEL compteur
    clrf    compteur

loop:
    BANKSEL compteur
    movf    compteur, w
    BANKSEL LATB
    movwf   LATB
    BANKSEL LATD
    movwf   LATD

    call    wait_1s

    BANKSEL compteur
    incf    compteur, f
    movlw   0x0F
    andwf   compteur, f

    goto    loop

; --- Attente d'environ 1 seconde avec TMR0 ---
; On attend 'ovf_cnt' débordements complets du timer
wait_1s:
    BANKSEL ovf_cnt
    movlw   6              
    movwf   ovf_cnt
    bcf     INTCON, 2       
wait_loop:
    btfss   INTCON, 2       
    goto    wait_loop      
    bcf     INTCON, 2       
    decfsz  ovf_cnt, f      
    goto    wait_loop
    return                  


