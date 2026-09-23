PROCESSOR 16F1719
#include <xc.inc>

; --- Configuration Words (Fuses) ---
CONFIG WDTE = OFF       ; Watchdog désactivé
CONFIG MCLRE = ON       ; MCLR activé

; --- Déclaration des variables (RAM) ---
PSECT udata_shr, class=COMMON, space=1, noexec
    delay1:  DS 1       ; Compteur tempo1
    delay2:  DS 1       ; Compteur tempo2
    delay3:  DS 1       ; Compteur tempo3
    compteur: DS 1      ; Compteur modulo 16

; --- Vecteur de Reset ---
PSECT resetVec, class=CODE, delta=2
resetVector:
    pagesel main
    goto    main

; --- Programme Principal ---
PSECT code, class=CODE, delta=2
main:
    ; --- Configuration des broches (I/O) ---
    ; Désactiver les entrées analogiques sur PORTB et PORTD
    BANKSEL ANSELB
    clrf    ANSELB
    BANKSEL ANSELD
    clrf    ANSELD

    ; 4 bits bas en sortie (les 4 hauts restent en entrée)
    BANKSEL TRISB
    movlw   0xF0        
    movwf   TRISB
    BANKSEL TRISD
    movlw   0xF0        
    movwf   TRISD

    ; Initialiser le compteur à 0
    BANKSEL compteur
    clrf    compteur

loop:
   
    BANKSEL compteur
    movf    compteur, w     
    BANKSEL LATB
    movwf   LATB            
    BANKSEL LATD
    movwf   LATD            

    
    call    delay

    ; --- compteur modulo 16 ---
    BANKSEL compteur
    incf    compteur, f     
    movlw   0x0F            
    andwf   compteur, f     

    goto    loop

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





