# OM (Ore Mensili) 

> **Un gestore presenze professionale per DOS, scritto in QuickBASIC nel 1988.**

![BASIC Banner](https://img.shields.io/badge/Language-QuickBASIC-blue.svg) ![Platform](https://img.shields.io/badge/Platform-MS--DOS-black.svg) ![Year](https://img.shields.io/badge/Vintage-1988-orange.svg)

**OM.EXE** è un'applicazione gestionale sviluppata alla fine degli anni '80 per tracciare gli orari di lavoro (2 entrate e 2 uscite giornaliere), calcolare i totali mensili e generare report di stampa.

Il progetto è un esempio di come si realizzavano interfacce utente (TUI) robuste e "user-friendly" in ambiente DOS puro, senza l'ausilio di librerie esterne, utilizzando tecniche avanzate di gestione della memoria video e input masking.

## ? Caratteristiche Tecniche

Per gli appassionati di retro-coding, **OM** presenta diverse soluzioni interessanti per l'epoca:

* **Custom Input Handler (`SUB editline`):** Una routine di input che sostituisce la `INPUT` standard. Gestisce maschere di inserimento (es. forza il formato `HH:MM`), previene crash da input errati e gestisce il cursore a basso livello.
* **Windowing System:** Simulazione di finestre modali (popup) istantanee utilizzando `PCOPY` per salvare e ripristinare le pagine della memoria video.
* **Algoritmo Perpetuo:** Calcolo matematico del giorno della settimana (senza dipendere dall'orologio di sistema per la logica del calendario), funzionante dal 1899 al 4099.
* **Macro Programmabili:** Un sistema interno che permette all'utente di registrare sequenze di orari sui tasti funzione (F1-F12) per un inserimento dati rapido.
* **Database Testuale:** Salvataggio dati in formato sequenziale `.CSV` con header di controllo integrità).

##  Come eseguirlo oggi

Essendo codice nativo a 16-bit, hai due strade principali:

### 1. Emulazione (Consigliato)
Il file compilato `.EXE` gira perfettamente su **DOSBox** o **DOSBox-X**.
1. Monta la cartella del progetto in DOSBox.
2. Lancia `OM.EXE`.

### 2. Ricompilazione
Il codice sorgente `OM.BAS` è compatibile con **Microsoft QuickBASIC**.
* Può essere aperto e studiato anche con moderni interpreti/compilatori come **QB64** (con minimi adattamenti per la gestione della memoria video).

##  Documentazione Originale

All'interno della repository è presente il file `OM.TXT`, il manuale originale del 1988 che spiega nel dettaglio:
* Come creare un nuovo foglio ore.
* La gestione dei colori e della stampa su LPT1.
* I trucchi per la gestione dei turni notturni.

##  Struttura dei File

* `OM.BAS`: Il codice sorgente completo.
* `OM.TXT`: Documentazione originale in formato testo.
* `*.CSV`: File dati (generati dal programma).
* `PAL.OM`, `NOMI.OM`: File di configurazione generati automaticamente.

##  Autore e Licenza

Scritto da **Marco da Venezia** nel 1988.
Rilasciato come Freeware/Open Source per scopi educativi e di preservazione storica.

---
*Happy Retro-Coding!* 
