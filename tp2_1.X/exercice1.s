PROCESSOR 16F1719
#include <xc.inc>

; --- Configuration ---
CONFIG WDTE = OFF
CONFIG MCLRE = ON

; --- Variables ---
PSECT udata_shr, class=COMMON, space=1, noexec
    acq: DS 1              

; --- Vecteur de Reset ---
PSECT resetVec, class=CODE, delta=2
resetVector:
    pagesel main
    goto    main

; --- Programme Principal ---
PSECT code, class=CODE, delta=2
main:
    BANKSEL ANSELA
    bsf     ANSELA, 0       
    BANKSEL TRISA
    bsf     TRISA, 0        

    BANKSEL ANSELD
    clrf    ANSELD          
    BANKSEL TRISD
    clrf    TRISD           

    ; --- Configuration de l'ADC ---
    BANKSEL ADCON1
    movlw   0b01110000      
    movwf   ADCON1
    BANKSEL ADCON0
    movlw   0b00000001      
    movwf   ADCON0

loop:
    ; --- Temps d'acquisition ---
    BANKSEL acq
    movlw   20
    movwf   acq
acq_wait:
    decfsz  acq, f
    goto    acq_wait

    ; --- Lancer la conversion (polling) ---
    BANKSEL ADCON0
    bsf     ADCON0, 1      
wait_adc:
    btfsc   ADCON0, 1       
    goto    wait_adc        

    BANKSEL ADRESH
    swapf   ADRESH, w       
    andlw   0x0F          
    BANKSEL LATD
    movwf   LATD            

    goto    loop


