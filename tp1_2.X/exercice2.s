PROCESSOR 16F1719
#include <xc.inc>

; --- Configuration ---
CONFIG WDTE = OFF
CONFIG MCLRE = ON

; --- Variables ---
PSECT udata_shr, class=COMMON, space=1, noexec
    delay1:   DS 1
    delay2:   DS 1
    delay3:   DS 1
    compteur: DS 1
    temp:     DS 1
    result:   DS 1

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

    ; Initialiser le compteur
    BANKSEL compteur
    clrf    compteur

loop:
    BANKSEL compteur
    swapf   compteur, w    
    andlw   0x0F
    call    reverse_nibble  
    BANKSEL LATD
    movwf   LATD

    BANKSEL compteur
    movf    compteur, w
    andlw   0x0F
    call    reverse_nibble
    BANKSEL LATB
    movwf   LATB

    ; Temporisation
    call    delay

    ; Incrémenter (reboucle à 0 après 255)
    BANKSEL compteur
    incf    compteur, f

    goto    loop


reverse_nibble:
    BANKSEL temp
    movwf   temp
    clrf    result

    btfsc   temp, 0         
    bsf     result, 3    

    btfsc   temp, 1         
    bsf     result, 2     

    btfsc   temp, 2        
    bsf     result, 1       

    btfsc   temp, 3       
    bsf     result, 0      

    movf    result, w     
    return

; --- Sous-programme de temporisation (~1s) ---
delay:
    movlw   2
    movwf   delay3
delay_loop3:
    movlw   126
    movwf   delay2
delay_loop2:
    movlw   126
    movwf   delay1
delay_loop1:
    decfsz  delay1, f
    goto    delay_loop1
    decfsz  delay2, f
    goto    delay_loop2
    decfsz  delay3, f
    goto    delay_loop3
    return