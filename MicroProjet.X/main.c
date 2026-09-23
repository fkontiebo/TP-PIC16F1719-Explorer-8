/**
  Mini Projet - Gestion de Temperature
  PIC16F1719 - Explorer 8

  Description:
    - TMP36 sur RA3 (AN3) : temperature actuelle
    - Potentiometre R25 sur RA0 (AN0) : temperature de consigne
    - LED verte (RB1)  : temp actuelle < consigne
    - LED jaune (RB2)  : temp actuelle > consigne
    - LED rouge (RB3)  : temp actuelle > consigne + 10%, intensite PWM
    - Affichage LCD des deux temperatures + etat

  Cablage LEDs sur breadboard :
    RB1 ---[330R]--- LED verte --- GND
    RB2 ---[330R]--- LED jaune --- GND
    RB3 ---[330R]--- LED rouge --- GND

  Compilateur : XC8
  IDE         : MPLAB X
*/

#include "mcc_generated_files/mcc.h"
#include "mcc_generated_files/adc.h"
#include "mcc_generated_files/pwm2.h"
#include "mcc_generated_files/tmr2.h"
#include "lcd.h"

#include <xc.h>
#include <stdint.h>

// ============================================================
//  DEFINES
// ============================================================

#define _XTAL_FREQ      8000000

// Canaux ADC
#define TMP36_CHANNEL   0x03        // TMP36 sur RA3 = AN3
#define POT_CHANNEL     0x00        // Potentiometre sur RA0 = AN0

// Tension de reference (carte 5V)
#define VREF_MV         5000

// Plage de consigne du potentiometre (en degres C)
#define CONSIGNE_MIN    0
#define CONSIGNE_MAX    50

// LEDs sur PORTB
#define LED_VERTE_ON()      do { LATBbits.LATB1 = 1; } while(0)
#define LED_VERTE_OFF()     do { LATBbits.LATB1 = 0; } while(0)
#define LED_JAUNE_ON()      do { LATBbits.LATB2 = 1; } while(0)
#define LED_JAUNE_OFF()     do { LATBbits.LATB2 = 0; } while(0)
#define LED_ROUGE_ON()      do { LATBbits.LATB3 = 1; } while(0)
#define LED_ROUGE_OFF()     do { LATBbits.LATB3 = 0; } while(0)

// ============================================================
//  PROTOTYPES
// ============================================================

void    Projet_Init(void);
int16_t Lire_Temperature(void);
int16_t Lire_Consigne(void);
void    Gerer_LEDs(int16_t tempAct, int16_t consigne);
void    Gerer_Alarme_PWM(int16_t tempAct, int16_t consigne);
void    PWM_Rouge_Enable(void);
void    PWM_Rouge_Disable(void);
void    Afficher_LCD(int16_t tempAct, int16_t consigne);
void    LCD_EcrireEntier(int16_t val);

// ============================================================
//  VARIABLES GLOBALES
// ============================================================

uint8_t alarmeActive = 0;

// ============================================================
//  PROGRAMME PRINCIPAL
// ============================================================

void main(void)
{
    int16_t tempActuelle = 0;
    int16_t consigne     = 0;

    // Initialisation
    SYSTEM_Initialize();
    LCD_Initialize();
    Projet_Init();

    // Message d'accueil
    LCD_GoTo(0, 0);
    LCD_WriteString(" Gestion  Temp  ");
    LCD_GoTo(1, 0);
    LCD_WriteString("  Mini Projet   ");
    __delay_ms(2000);

    // Boucle principale
    while (1)
    {
        // 1) Lire temperature actuelle (TMP36 sur AN3)
        tempActuelle = Lire_Temperature();

        // 2) Lire consigne (potentiometre sur AN0)
        consigne = Lire_Consigne();

        // 3) Gerer les LEDs verte et jaune
        Gerer_LEDs(tempActuelle, consigne);

        // 4) Gerer la LED rouge avec PWM (seuil 10%)
        Gerer_Alarme_PWM(tempActuelle, consigne);

        // 5) Afficher sur le LCD
        Afficher_LCD(tempActuelle, consigne);

        // Tempo
        __delay_ms(300);
    }
}

// ============================================================
//  INITIALISATION
// ============================================================

void Projet_Init(void)
{
    // --- RA3 : entree analogique (TMP36) ---
    TRISAbits.TRISA3 = 1;
    ANSELAbits.ANSA3 = 1;

    // --- RA0 : entree analogique (potentiometre) ---
    TRISAbits.TRISA0 = 1;
    ANSELAbits.ANSA0 = 1;

    // --- RB1 : sortie digitale (LED verte) ---
    TRISBbits.TRISB1 = 0;
    ANSELBbits.ANSB1 = 0;

    // --- RB2 : sortie digitale (LED jaune) ---
    TRISBbits.TRISB2 = 0;
    ANSELBbits.ANSB2 = 0;

    // --- RB3 : sortie digitale (LED rouge / PWM) ---
    TRISBbits.TRISB3 = 0;
    ANSELBbits.ANSB3 = 0;

    // Tout eteint au demarrage
    LATB = 0x00;

    // Initialiser ADC
    ADC_Initialize();
}

// ============================================================
//  LECTURE TEMPERATURE (TMP36)
// ============================================================
//  TMP36 : Vout = 10mV/C, offset 500mV a 0C
//  T(C) = (Vout_mV - 500) / 10

int16_t Lire_Temperature(void)
{
    uint16_t adc;
    int32_t  mV;

    // Double lecture pour purger le condensateur ADC
    // apres la lecture du potentiometre (canal different)
    ADC_GetConversion(TMP36_CHANNEL);   // 1ere lecture : on jette
    __delay_us(50);                      // Attente stabilisation
    adc = ADC_GetConversion(TMP36_CHANNEL);  // 2eme lecture : on garde

    mV  = ((int32_t)adc * VREF_MV) / 1023;

    return (int16_t)((mV - 500) / 10);
}

// ============================================================
//  LECTURE CONSIGNE (POTENTIOMETRE)
// ============================================================
//  Potentiometre 0-1023 mappe sur CONSIGNE_MIN..CONSIGNE_MAX

int16_t Lire_Consigne(void)
{
    uint16_t adc;

    // Double lecture pour purger le condensateur ADC
    ADC_GetConversion(POT_CHANNEL);     // 1ere lecture : on jette
    __delay_us(50);                      // Attente stabilisation
    adc = ADC_GetConversion(POT_CHANNEL);  // 2eme lecture : on garde

    return (int16_t)(((int32_t)adc * (CONSIGNE_MAX - CONSIGNE_MIN)) / 1023)
           + CONSIGNE_MIN;
}

// ============================================================
//  GESTION LEDs VERTE ET JAUNE
// ============================================================
//  Verte  : temp < consigne  (tout va bien)
//  Jaune  : temp >= consigne (depassement)

void Gerer_LEDs(int16_t tempAct, int16_t consigne)
{
    if (tempAct < consigne)
    {
        LED_VERTE_ON();
        LED_JAUNE_OFF();
    }
    else
    {
        LED_VERTE_OFF();
        LED_JAUNE_ON();
    }
}

// ============================================================
//  GESTION LED ROUGE AVEC PWM
// ============================================================
//  Si temp actuelle depasse la consigne de plus de 10%,
//  la LED rouge s'allume en PWM avec une intensite
//  proportionnelle au depassement.
//
//  Seuil = consigne + (consigne * 10 / 100) = consigne * 1.10
//
//  Exemple : consigne = 30C -> seuil = 33C
//            a 35C -> PWM proportionnel a (35-33)

void Gerer_Alarme_PWM(int16_t tempAct, int16_t consigne)
{
    // Calcul du seuil a 10% au dessus de la consigne
    int16_t seuil10pct = consigne + (consigne * 10) / 100;

    // Eviter un seuil trop bas si consigne = 0
    if (seuil10pct <= consigne)
        seuil10pct = consigne + 1;

    if (tempAct > seuil10pct)
    {
        // Activer le PWM si pas deja fait
        if (!alarmeActive)
        {
            PWM_Rouge_Enable();
            alarmeActive = 1;
        }

        // Calculer le duty cycle proportionnel au depassement
        // Plus on depasse, plus la LED rouge est intense
        uint16_t depassement = (uint16_t)(tempAct - seuil10pct);
        uint16_t duty = depassement * 200;  // Montee progressive
        if (duty > 1023) duty = 1023;       // Saturation max
        PWM2_LoadDutyValue(duty);
    }
    else
    {
        // Desactiver le PWM
        if (alarmeActive)
        {
            PWM_Rouge_Disable();
            alarmeActive = 0;
        }
    }
}

// ============================================================
//  ACTIVATION PWM SUR RB3 (LED ROUGE)
// ============================================================

void PWM_Rouge_Enable(void)
{
    TMR2_StartTimer();

    // Assigner CCP2 a RB3 via PPS
    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x00;  // Unlock

    RB3PPS = 0x0D;                  // CCP2 -> RB3

    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x01;  // Lock
}

void PWM_Rouge_Disable(void)
{
    // Remettre RB3 en GPIO
    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x00;

    RB3PPS = 0x00;

    PPSLOCK = 0x55;
    PPSLOCK = 0xAA;
    PPSLOCKbits.PPSLOCKED = 0x01;

    TMR2_StopTimer();
    LATBbits.LATB3 = 0;            // Eteindre LED rouge
}

// ============================================================
//  AFFICHAGE LCD
// ============================================================
//
//  Ligne 0 : "T=22C    C=30C"
//  Ligne 1 : "OK" ou "> CONSIGNE" ou "ALERTE >10%"
//

void Afficher_LCD(int16_t tempAct, int16_t consigne)
{
    int16_t seuil10pct = consigne + (consigne * 10) / 100;
    if (seuil10pct <= consigne) seuil10pct = consigne + 1;

    // --- Ligne 0 : temperatures ---
    LCD_GoTo(0, 0);
    LCD_WriteString("T=");
    LCD_EcrireEntier(tempAct);
    LCD_WriteString("\xDF" "C");
    LCD_WriteString("   ");
    LCD_WriteString("C=");
    LCD_EcrireEntier(consigne);
    LCD_WriteString("\xDF" "C ");

    // --- Ligne 1 : etat du systeme ---
    LCD_GoTo(1, 0);

    if (tempAct > seuil10pct)
    {
        // Au dessus de 10% : ALERTE + LED rouge PWM
        LCD_WriteString("ALERTE >10%  [R]");
    }
    else if (tempAct >= consigne)
    {
        // Au dessus de la consigne : LED jaune
        LCD_WriteString("> CONSIGNE   [J]");
    }
    else
    {
        // En dessous : tout va bien, LED verte
        LCD_WriteString("< CONSIGNE   [V]");
    }
}

// ============================================================
//  ECRITURE D'UN ENTIER SUR LE LCD
// ============================================================

void LCD_EcrireEntier(int16_t val)
{
    if (val < 0)
    {
        LCD_WriteByte('-');
        val = -val;
    }
    else
    {
        LCD_WriteByte(' ');
    }

    if (val >= 100)
        LCD_WriteByte((val / 100) + '0');

    if (val >= 10)
        LCD_WriteByte(((val / 10) % 10) + '0');

    LCD_WriteByte((val % 10) + '0');
}

/**
 End of File
*/