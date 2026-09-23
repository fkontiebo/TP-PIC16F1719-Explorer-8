Ce depot retrace une progression complète sur 8 bits : du pilotage direct des registres en
assembleur jusqu'à une application C structurée mêlant acquisition analogique,
comparaison à une consigne, PWM et affichage LCD.

---

## Environnement

| Élément | Version / référence |
|---|---|
| Microcontrôleur | PIC16F1719 (8 bits, midrange) |
| Carte | Microchip Explorer 8 Development Board |
| IDE | MPLAB X |
| Compilateur | XC8 (C) et `pic-as` (assembleur) |
| Horloge | 8 MHz (oscillateur interne) |

---

## Contenu du dépôt

### Mini-projet — Régulation de température (C)

[`MicroProjet.X/main.c`](MicroProjet.X/main.c)

Système de surveillance de température avec consigne réglable et alarme progressive.

**Fonctionnement**

1. Lecture de la température ambiante via un capteur **TMP36** sur `AN3`
   (`T°C = (Vout_mV − 500) / 10`)
2. Lecture d'une **consigne** réglable au potentiomètre sur `AN0`, mappée sur 0–50 °C
3. Comparaison et signalisation :

| Condition | Signalisation |
|---|---|
| T < consigne | LED verte (RB1) |
| T ≥ consigne | LED jaune (RB2) |
| T > consigne + 10 % | LED rouge (RB3) en **PWM**, intensité proportionnelle au dépassement |

4. Affichage temps réel sur LCD 2×16 : températures mesurée et consigne, puis l'état du système

**Structure du projet**

```
MicroProjet.X/
├── main.c                  # logique applicative (mesure, seuils, PWM, affichage)
├── lcd.c / lcd.h           # pilote LCD de la carte Explorer 8 (via SPI)
└── mcc_generated_files/    # pilotes générés par MPLAB Code Configurator
    ├── mcc.c               # horloge, init système
    ├── adc.c               # convertisseur A/N 10 bits
    ├── pwm2.c / tmr2.c     # PWM (CCP2) et sa base de temps
    ├── pin_manager.c       # configuration des broches et du PPS
    └── spi.c, tmr0.c, tmr1.c, memory.c, interrupt_manager.c
```

---

### TP 1 — Entrées/sorties et temporisations (assembleur)

### TP 2 — Conversion analogique-numérique (assembleur)



## Compilation et flashage

```
1. Ouvrir le dossier .X voulu dans MPLAB X          (File > Open Project)
2. Vérifier la chaîne d'outils sélectionnée :
     - projets tp*.X       -> pic-as  (assembleur)
     - MicroProjet.X       -> XC8     (C)
3. Build Project                                     (F11)
4. Brancher la carte Explorer 8 puis Make and Program Device
```

Les deux types de projets se compilent sans dépendance externe : le mini-projet embarque
ses pilotes MCC et son driver LCD, les TP assembleur n'utilisent que `xc.inc`.

[`video de demonstration`](https://drive.google.com/file/d/1is7u_tyBi3eYHL9u3ygj6jrT_R-5J5HB/viewgit)