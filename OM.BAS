' =============================================================================
' OM.BAS - Gestione Ore Mensili (Versione Storica 1988)
' Autore: Marco da Venezia
' Piattaforma: Microsoft QuickBASIC
'
' Descrizione:
' Programma gestionale per il tracciamento delle ore lavorative con:
' - Interfaccia grafica "custom" in modalità testo
' - Routine di input mascherato per orari (editline)
' - Calcolo automatico giorni della settimana (algoritmo perpetuo)
' - Gestione Macro su tasti funzione
' =============================================================================

DECLARE SUB vedi.txt (file$)
DECLARE SUB colori (pal!)
DECLARE FUNCTION ver.csv! (e1$, e2$, e3$, e4$, e5$, e6$, file$)
DECLARE SUB file.errato (file$)
DECLARE SUB end.run ()
DECLARE SUB Liste (FDN$, o$)
DECLARE SUB Fk.tasti ()
DECLARE SUB Fk.popup ()
DECLARE SUB Fk.imposta (edit$)
DECLARE SUB formato.ora (edit$)
DECLARE SUB memo ()
DECLARE SUB editline (riga!, colonna!, lung!, cv1$, cv2$, cv3$, cv4$, tipo$, edit$)
DECLARE SUB tab.ore.mod (file$, anno$, mese$)
DECLARE SUB file.txt (file$, nome.mese$)
DECLARE SUB nome.giorno (gs!, gs$)
DECLARE SUB can.riga (r!, c!, l!)
DECLARE FUNCTION gg.in.mese! (mese!, anno!)
DECLARE FUNCTION giorno.settimana! (anno$, mese$)
DECLARE FUNCTION calcola.ore! (ora.inizio$, ora.fine$)

' Variabili condivise per i tasti funzione
DIM SHARED tab.Fv$(12)
DIM SHARED tab.Fk$(12)

' Gestione errori centralizzata
ON ERROR GOTO Gest.Err

CLS

' --- Inizializzazione Colori ---
OPEN "pal.om" FOR APPEND AS #1: CLOSE #1
OPEN "pal.om" FOR INPUT AS #1
IF LOF(1) > 0 THEN INPUT #1, pal
CLOSE #1
CALL colori(pal)

' --- Verifica/Creazione File di Supporto ---
PRINT "Controllo file nomi"
OPEN "nomi.om" FOR APPEND AS #1: CLOSE #1
PRINT "Controllo file ditte"
OPEN "ditte.om" FOR APPEND AS #1: CLOSE #1
PRINT "Controllo file tasti funzione"
CALL Fk.tasti

' --- Controllo presenza istruzioni ---
SHELL "dir OM.TXT /b > temp.om"
OPEN "temp.om" FOR INPUT AS #1
IF LOF(1) = 8 THEN istruzioni = 1
CLOSE #1
KILL "temp.om"

' =============================================================================
' MENU PRINCIPALE
' =============================================================================
CLS
PRINT "PROGRAMMA FOGLIO ORE SERVIZIO MENSILE"
PRINT
PRINT "Premi un tasto:"
PRINT
PRINT "[N] nuovo"
PRINT "[M] modifica"
PRINT "[F] tasti-funzione"
PRINT "[C] colori"
PRINT "[I] istruzioni"
PRINT
PRINT "[Esc] uscita "

DO
    LOCATE 3, 17, 1
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN fine = 1: EXIT DO
    IF UCASE$(k$) = "N" THEN crea = 1
    IF UCASE$(k$) = "M" THEN edit = 1
    IF UCASE$(k$) = "F" THEN
        PCOPY 0, 1  ' Salva schermo attuale (simulazione finestra modale)
        CALL Fk.imposta(edit$)
        PCOPY 1, 0  ' Ripristina schermo
    END IF
    IF UCASE$(k$) = "C" THEN
        cp = 1
        pal = pal + 1
        CALL colori(pal)
    END IF
    IF UCASE$(k$) = "I" THEN
        PCOPY 0, 1
        IF istruzioni = 1 THEN CALL vedi.txt("OM") ELSE CALL memo
        PCOPY 1, 0
    END IF
    IF crea OR edit THEN EXIT DO
LOOP

' Salva preferenza colore se modificata
IF cp THEN
    OPEN "pal.om" FOR OUTPUT AS #1
    WRITE #1, pal
    CLOSE
END IF

IF fine = 1 THEN CLS : END

' --- Sezione Modifica: Caricamento dati esistenti ---
IF edit THEN
    CALL Liste(file$, "File")
    OPEN file$ + ".CSV" FOR INPUT AS #3
    INPUT #3, e1$, e2$, e3$, e4$, e5$, e6$
    ' Verifica integrità file (controllo header e dimensione)
    IF ver.csv(e1$, e2$, e3$, e4$, e5$, e6$, file$) = 0 THEN CALL file.errato(file$)
    OPEN "TEMPCSV.OM" FOR OUTPUT AS #4
END IF

CLS
    
FOR i = 1 TO VAL(e3$): READ nome.mese$: NEXT: RESTORE
PRINT "ORARI: anno "; TAB(13); e2$; TAB(18); "- mese "; TAB(25); nome.mese$; TAB(35); "- di "; e1$; TAB(71); "F:"; file$
LOCATE 2, 1: PRINT "Ditta: "; e4$

' --- Input Dati Intestazione (Nome e Ditta) ---
COLOR 31: LOCATE 1, 40: PRINT e1$: COLOR 7
CALL Liste(nome$, "Nomi")
VIEW PRINT 3 TO 24: CLS : VIEW PRINT
IF nome$ = "" THEN
    LOCATE 4, 1: PRINT "Inserisci nome/matricola o nulla per saltare: ";
    CALL editline(CSRLIN, POS(1), 20, " ", CHR$(127), " ", " ", "nome", edit$)
    IF edit$ = "" THEN
        IF edit THEN nome$ = e1$
    ELSE
        nome$ = LTRIM$(RTRIM$(edit$))
    END IF
END IF
' ...logica salvataggio nuovi nomi in nomi.om...
IF nome$ <> "" AND nome$ <> e1$ THEN
    OPEN "nomi.om" FOR INPUT AS #6
    DO WHILE NOT EOF(6)
        INPUT #6, N$
        IF N$ = nome$ THEN old.n = 1: EXIT DO
    LOOP
    CLOSE #6
    IF old.n = 0 THEN
        OPEN "nomi.om" FOR APPEND AS #6
        PRINT #6, nome$
        CLOSE #6
    END IF
END IF
CALL can.riga(1, 40, 30): PRINT nome$

COLOR 31: LOCATE 2, 8: PRINT e4$: COLOR 7
CALL Liste(ditta$, "Ditte")
VIEW PRINT 3 TO 24: CLS : VIEW PRINT
IF ditta$ = "" THEN
    LOCATE 4, 1: PRINT "Inserisci nome/dati della ditta o nulla per saltare..."
    PRINT "Ditta: ";
    CALL editline(CSRLIN, POS(1), 50, " ", CHR$(127), " ", " ", "ditta", edit$)
    IF edit$ = "" THEN
        IF edit THEN ditta$ = e4$
    ELSE
        ditta$ = LTRIM$(RTRIM$(edit$))
    END IF
END IF
' ...logica salvataggio nuove ditte in ditte.om...
IF ditta$ <> "" AND ditta$ <> e4$ THEN
    OPEN "ditte.om" FOR INPUT AS #6
    DO WHILE NOT EOF(6)
        INPUT #6, d$
        IF d$ = ditta$ THEN old.d = 1: EXIT DO
    LOOP
    CLOSE #6
    IF old.d = 0 THEN
        OPEN "ditte.om" FOR APPEND AS #6
        PRINT #6, ditta$
        CLOSE #6
    END IF
END IF

CALL can.riga(2, 8, 70): PRINT ditta$
CALL can.riga(4, 1, 80)
CALL can.riga(5, 1, 80)

' --- Input Anno e Mese ---
IF edit THEN
    anno$ = e2$
ELSE
    DO
        CALL can.riga(3, 1, 80)
        PRINT "Inserisci l'anno (AAAA) o nulla per "; RIGHT$(DATE$, 4); " o 0 per terminare: ";
        CALL editline(CSRLIN, POS(1), -6, "0", "9", "0", "9", "anno", edit$)
        anno$ = edit$
        IF anno$ = "" THEN anno$ = RIGHT$(DATE$, 4)
        IF VAL(anno$) = 0 THEN LOCATE 24, 1: CALL end.run
        IF VAL(anno$) > 1899 AND VAL(anno$) < 4099 THEN EXIT DO
    LOOP
END IF
LOCATE 1, 13: PRINT anno$

IF edit THEN
    mese$ = e3$
ELSE
    DO
        CALL can.riga(3, 1, 80)
        PRINT "Inserisci il mese (MM) o nulla per "; LEFT$(DATE$, 2); " o 0 per terminare: ";
        CALL editline(CSRLIN, POS(1), -8, "0", "9", "0", "9", "mese", edit$)
        mese$ = edit$
        IF mese$ = "" THEN mese$ = LEFT$(DATE$, 2)
        IF VAL(mese$) = 0 THEN LOCATE 24, 1: CALL end.run
        IF LEN(mese$) = 1 THEN mese$ = "0" + mese$
        IF VAL(mese$) THEN EXIT DO
    LOOP
END IF
FOR i = 1 TO VAL(mese$): READ nome.mese$: NEXT: RESTORE
LOCATE 1, 25: PRINT nome.mese$

' --- Gestione Nome File .CSV ---
IF edit THEN
    WRITE #4, nome$, e2$, e3$, ditta$, e5$, e6$
    CALL tab.ore.mod(file$, e2$, e3$)
ELSE
    SHELL "dir " + anno$ + "-" + mese$ + ".CSV /b > TEMPGIA.OM"
    OPEN "TEMPGIA.OM" FOR INPUT AS #7
    IF LOF(7) = 0 THEN autofile = 1
    CLOSE #7
    DO
        CALL can.riga(3, 1, 80)
        PRINT "Inserisci il nome del file";
        IF autofile THEN PRINT " o nulla per "; anno$ + "-" + mese$;
        PRINT ": ";
        CALL editline(CSRLIN, POS(1), -2, "0", "9", "A", "Z", "File", edit$)
        file$ = UCASE$(edit$)
        IF file$ = "" THEN file$ = anno$ + "-" + mese$
        SHELL "dir " + file$ + ".CSV /b > TEMPGIA.OM"
        OPEN "TEMPGIA.OM" FOR INPUT AS #7
        IF LOF(7) = 0 THEN fine = 0 ELSE fine = 1: LOCATE 5, 1: PRINT "Il file esiste già!": fine = 1
        CLOSE #7: KILL "TEMPGIA.OM"
        IF fine THEN
            SHELL "dir " + file$ + ".CSV"
            LOCATE 24, 1: PRINT "Premi un tasto qualsiasi per continuare o [Esc] per uscire ";
            k$ = INPUT$(1)
            IF k$ = CHR$(27) THEN PRINT : END
        ELSE
            VIEW PRINT 3 TO 24: CLS : VIEW PRINT
            CALL can.riga(1, 71, 10): PRINT "F:"; file$
            EXIT DO
        END IF
    LOOP
    OPEN file$ + ".CSV" FOR OUTPUT AS #2
    WRITE #2, nome$, anno$, mese$, ditta$, file$ + ".CSV", "OM-file"
END IF
    
' Calcola il numero di giorni nel mese e il giorno della settimana
gg = gg.in.mese(VAL(mese$), VAL(anno$))
gs = giorno.settimana(anno$, mese$)

' --- Loop Principale Inserimento Giorni ---
IF edit THEN
    DIM elenco(0 TO 31)
    DO
        CALL can.riga(3, 1, 80): PRINT "Giorno: ";
        CALL editline(CSRLIN, POS(1), -8, "0", "9", "0", "9", "giorno", edit$)
        gmod = VAL(edit$)
        IF gmod <= gg THEN elenco(gmod) = gmod
        IF gmod = 0 THEN EXIT DO
        ' Visualizza giorni selezionati
        r = 0: c = 0
        COLOR 0, 7
            FOR i = 1 TO 31
                r = r + 1
                LOCATE 6 + r, 2 + c, 0
                IF elenco(i) = i THEN PRINT USING "## "; i;
                IF i = 15 THEN r = 0: c = 38
            NEXT
        COLOR 7, 0
    LOOP
ELSE
    ' Visualizzazione griglia giorni
    gs.c = gs
    FOR i = 1 TO gg
        r = r + 1
        LOCATE 6 + r, 2 + c, 0: PRINT USING "## "; i;
        CALL nome.giorno(gs.c, gs$)
        IF gs$ = "DOMENICA" THEN COLOR 15
        PRINT LEFT$(gs$, 2); " ........... ........... .....";
        COLOR 7
        IF i = 15 THEN r = 0: c = 38
    NEXT
END IF

' Attivazione Macro Tasti Funzione
FOR i = 1 TO 12
    IF i > 10 THEN s = 19 ELSE s = 0
    KEY i + s, tab.Fk$(i)
NEXT
KEY ON

tot.ore.mese = 0

' --- Ciclo su ogni giorno del mese ---
FOR giorno = 1 TO gg
    
    IF edit THEN
        INPUT #3, e1$, e2$, e3$, e4$, e5$, e6
        IF giorno <> elenco(giorno) THEN WRITE #4, e1$, e2$, e3$, e4$, e5$, e6
        CALL can.riga(4, 1, 80): PRINT "Entrata Mattina:    "; e2$; TAB(29); "Uscita Mattina:    "; e3$
        CALL can.riga(5, 1, 80): PRINT "Entrata Pomeriggio: "; e4$; TAB(29); "Uscita Pomeriggio: "; e5$
    END IF
                              
    CALL nome.giorno(gs, gs$)
    CALL can.riga(3, 1, 80): PRINT "Giorno"; giorno; gs$; TAB(21); "(Premi Tab per visualizzare popup tasti funzione)";

    IF crea OR edit AND giorno = elenco(giorno) THEN

        IF giorno < 16 THEN r = giorno: c = 5 ELSE r = giorno - 15: c = 43

        ' --- Input Mattina ---
        ent.mat$ = ""
        CALL can.riga(5, 1, 80)
        CALL can.riga(4, 1, 80)
        PRINT "Entrata Mattina:    --:--";
        CALL editline(CSRLIN, POS(1) - 5, -5, "0", "9", "0", "9", "ora", edit$)
        IF edit$ <> "" THEN CALL formato.ora(edit$): ent.mat$ = edit$
     
        usc.mat$ = ""
        IF ent.mat$ <> "" THEN
          DO
            CALL can.riga(4, 29, 51)
            PRINT "Uscita Mattina:    --:--";
            CALL editline(CSRLIN, POS(1) - 5, -5, "0", "9", "0", "9", "ora", edit$)
            IF edit$ = "" THEN
                usc.mat$ = "": ent.mat$ = ""
                EXIT DO
            ELSE
                CALL formato.ora(edit$): usc.mat$ = edit$
                IF usc.mat$ = "00:00" THEN usc.mat$ = "24:00"
                IF usc.mat$ > ent.mat$ THEN
                    LOCATE 6 + r, c + 3: PRINT ent.mat$; "-"; usc.mat$; " ";
                    EXIT DO
                END IF
            END IF
          LOOP
        END IF
        IF ent.mat$ = "" THEN LOCATE 6 + r, c + 3: PRINT "........... ";

        ' --- Input Pomeriggio ---
        ent.pom$ = ""
        DO
          IF usc.mat$ = "24:00" THEN ent.pom$ = "": EXIT DO
          CALL can.riga(5, 1, 80)
          PRINT "Entrata Pomeriggio: --:--";
          CALL editline(CSRLIN, POS(1) - 5, -5, "0", "9", "0", "9", "ora", edit$)
          IF edit$ = "" THEN
            ent.pom$ = ""
            EXIT DO
          ELSE
            CALL formato.ora(edit$)
            ent.pom$ = edit$
            IF ent.pom$ > usc.mat$ THEN EXIT DO
          END IF
        LOOP

        usc.pom$ = ""
        IF ent.pom$ <> "" THEN
          DO
            CALL can.riga(5, 29, 51)
            PRINT "Uscita Pomeriggio: --:--";
            CALL editline(CSRLIN, POS(1) - 5, -5, "0", "9", "0", "9", "ora", edit$)
            IF edit$ = "" THEN
                usc.pom$ = "": ent.pom$ = ""
                EXIT DO
            ELSE
                CALL formato.ora(edit$): usc.pom$ = edit$
                IF usc.pom$ = "00:00" THEN usc.pom$ = "24:00"
                IF usc.pom$ > ent.pom$ THEN
                    LOCATE 6 + r, c + 14: PRINT " "; ent.pom$; "-"; usc.pom$; " ";
                    EXIT DO
                END IF
            END IF
          LOOP
        END IF
        IF ent.pom$ = "" THEN LOCATE 6 + r, c + 14: PRINT " ........... ";
    
        ' Calcola le ore lavorate giornalmente
        ore.giorno = calcola.ore(ent.mat$, usc.mat$) + calcola.ore(ent.pom$, usc.pom$)
      
        IF giorno < 16 THEN r = giorno: c = 5 ELSE r = giorno - 15: c = 43
        LOCATE 6 + r, c + 26: PRINT USING " ##.##"; ore.giorno;
    
    END IF
    
    IF edit AND giorno <> elenco(giorno) THEN ore.giorno = e6

    tot.ore.mese = tot.ore.mese + ore.giorno
    
    ' Scrittura record nel file CSV
    IF edit THEN
        IF giorno = elenco(giorno) THEN WRITE #4, e1$, ent.mat$, usc.mat$, ent.pom$, usc.pom$, ore.giorno
    ELSE
        WRITE #2, LTRIM$(STR$(giorno)) + " " + LEFT$(gs$, 2), ent.mat$, usc.mat$, ent.pom$, usc.pom$, ore.giorno
    END IF

NEXT giorno

' Disattivazione Tasti Funzione
FOR i = 1 TO 12
    IF i > 10 THEN s = 19 ELSE s = 0
    KEY i + s, ""
NEXT
KEY OFF

' --- Totali Finali ---
LOCATE 23, 1: PRINT USING " Totale ore: ###.##"; tot.ore.mese;
IF tot.ore.mese > INT(tot.ore.mese) THEN
    PRINT USING " (### e"; INT(tot.ore.mese);
    PRINT USING " ## min.)"; (tot.ore.mese - INT(tot.ore.mese)) * 60;
END IF

IF crea THEN num.file = 2 ELSE num.file = 4
WRITE #num.file, "", "", "", "", "", tot.ore.mese
CLOSE

' Swap dei file temporanei in fase di modifica
IF edit THEN
    KILL file$ + ".CSV"
    NAME "TEMPCSV.OM" AS file$ + ".CSV"
    OPEN file$ + ".CSV" FOR INPUT AS #3
    INPUT #3, e1$, e2$, e3$, e4$, e5$, e6$
    CALL tab.ore.mod(file$, e2$, e3$)
END IF

CLOSE
CALL file.txt(file$, nome.mese$)

' --- Menu Finale (Stampa/Visualizza) ---
DO
    CALL can.riga(24, 1, 80): PRINT "Premi: [V] vedi "; file$; ".TXT - [S] stampalo - ["; CHR$(17); CHR$(196); "] riavvia - [Esc] esci ";
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN CALL can.riga(24, 1, 78): END
    IF k$ = CHR$(8) THEN CALL can.riga(24, 1, 78): PRINT " Riavvio..."; : RUN "OM"
    IF UCASE$(k$) = "S" THEN
        CLOSE
        OPEN "LPT1:" FOR OUTPUT AS #1
        OPEN file$ + ".TXT" FOR INPUT AS #2
        WHILE NOT EOF(2)
            LINE INPUT #2, a$
            PRINT #1, a$
        WEND
    END IF
    IF UCASE$(k$) = "V" THEN
        PCOPY 0, 1
        CALL vedi.txt(file$)
        PCOPY 1, 0
    END IF
LOOP

END

' --- Gestione Errori Runtime ---
Gest.Err:
IF ERR = 62 THEN CALL file.errato(file$) ' Errore Input past end of file
COLOR 0, 7
CALL can.riga(25, 1, 80)
PRINT "ERRORE"; ERR; "- Premi un tasto qualsiasi per uscire ";
COLOR 7, 0
k$ = INPUT$(1)
RESUME fine

fine:
CLS
END

' Dati per i nomi dei mesi
DATA GENNAIO, FEBBRAIO, MARZO, APRILE, MAGGIO, GIUGNO
DATA LUGLIO, AGOSTO, SETTEMBRE, OTTOBRE, NOVEMBRE, DICEMBRE

' =============================================================================
' FUNZIONI E SUBROUTINE
' =============================================================================

REM OM 2.00 - Freeware 1988 by Marco da Venezia CP 0191 30100 Venezia (I)

' Funzione: calcola.ore
' Input: orari in formato "HH:MM"
' Output: differenza in valore decimale
FUNCTION calcola.ore (ora.inizio$, ora.fine$)
    inizio.ore = VAL(LEFT$(ora.inizio$, 2))
    inizio.minuti = VAL(RIGHT$(ora.inizio$, 2))
    fine.ore = VAL(LEFT$(ora.fine$, 2))
    fine.minuti = VAL(RIGHT$(ora.fine$, 2))
    differenza.minuti = (fine.ore * 60 + fine.minuti) - (inizio.ore * 60 + inizio.minuti)
    calcola.ore = ABS(differenza.minuti / 60)
END FUNCTION

' Sub: can.riga
' Pulisce una porzione di riga a video
SUB can.riga (r, c, l)
    LOCATE r, c, 0
    PRINT SPACE$(l);
    LOCATE r, c, 1
END SUB

' Sub: colori
' Imposta la palette grafica (compatibilità CGA/EGA)
SUB colori (pal)
    IF pal = 13 THEN pal = 0
    IF pal = 0 THEN PALETTE
    ' ...impostazioni palette specifiche per 1-12...
    IF pal = 1 THEN PALETTE 0, 1: PALETTE 7, 7
    IF pal = 2 THEN PALETTE 7, 1: PALETTE 0, 7
    IF pal = 3 THEN PALETTE 0, 2: PALETTE 7, 0
    IF pal = 4 THEN PALETTE 7, 2: PALETTE 0, 0
    IF pal = 5 THEN PALETTE 0, 3: PALETTE 7, 0
    IF pal = 6 THEN PALETTE 7, 3: PALETTE 0, 0
    IF pal = 7 THEN PALETTE 0, 4: PALETTE 7, 7
    IF pal = 8 THEN PALETTE 7, 4: PALETTE 0, 7
    IF pal = 9 THEN PALETTE 0, 5: PALETTE 7, 0
    IF pal = 10 THEN PALETTE 7, 5: PALETTE 0, 0
    IF pal = 11 THEN PALETTE 0, 6: PALETTE 7, 0
    IF pal = 12 THEN PALETTE 7, 6: PALETTE 0, 0
END SUB

' Sub: editline
' Routine avanzata di input mascherato
' Parametri: pos(r,c), lunghezza, caratteri validi (cv), tipo dati
SUB editline (riga, colonna, lung, cv1$, cv2$, cv3$, cv4$, tipo$, edit$)
  
  DIM edit$(lung + 10) ' Buffer interno

  edit$ = ""
  LOCATE riga, colonna, 1 ' Cursore visibile
  
  DO WHILE a$ <> CHR$(13)
    a$ = INKEY$
    c1 = POS(1): c2 = 1 + c1 - colonna
    
      ' Pre-fill per caratteri numerici veloci
      IF tipo$ > "0" AND tipo$ < ":" THEN a$ = tipo$: tipo$ = ""
      
      ' Visualizzazione Popup Tasti Funzione (TAB)
      IF a$ = CHR$(9) AND tipo$ = "ora" THEN CALL Fk.popup
      
      ' Pressione Enter
      IF a$ = CHR$(13) THEN
        ' Auto-completamento zeri per orari
        IF tipo$ = "ora" THEN
            IF c1 = colonna + 1 THEN PRINT "0:00"
            IF c1 = colonna + 3 THEN PRINT "00";
            IF c1 = colonna + 4 THEN PRINT "0";
        END IF
        FOR i = 1 TO c2 - 1: edit$ = edit$ + edit$(i): NEXT
        ERASE edit$
        EXIT DO
      END IF
      
      ' Pressione Back Space
      IF a$ = CHR$(8) THEN
        IF c1 < colonna + 1 THEN c1 = colonna + 1
        IF tipo$ = "ora" THEN
            IF c1 = colonna + 3 THEN c1 = colonna + 2 ' Salta il separatore ':'
            bs$ = "-"
          ELSE
            bs$ = " "
        END IF
        LOCATE riga, c1 - 1: PRINT bs$; : LOCATE riga, c1 - 1
        edit$(c2 - 1) = ""
      END IF

      ' Controllo range caratteri validi
      IF a$ <> CHR$(34) AND ((UCASE$(a$) >= cv1$ AND UCASE$(a$) <= cv2$) OR (UCASE$(a$) >= cv3$ AND UCASE$(a$) <= cv4$)) THEN
        IF c1 > colonna + 9 + lung THEN  ' Fine riga raggiunta
          c1 = colonna + 9 + lung
          c2 = 9 + lung + 1
        END IF
        
        ' Logica specifica per Mese
        IF tipo$ = "mese" THEN
            IF c1 = colonna + 1 THEN
                IF edit$(1) = "0" AND a$ < "1" THEN a$ = "0"
                IF edit$(1) = "1" AND a$ > "2" THEN a$ = "0"
                IF edit$(1) > "1" THEN a$ = edit$(1): c1 = colonna
            END IF
        END IF
        
        ' Logica specifica per ORA (validazione HH:MM in tempo reale)
        IF tipo$ = "ora" THEN
            IF c1 = colonna THEN
                IF a$ > "2" THEN a$ = ""
            END IF
            IF c1 = colonna + 1 THEN
                IF a$ > "3" AND edit$(1) = "2" THEN a$ = "" ELSE sep = 1
            END IF
            IF c1 = colonna + 2 THEN c1 = colonna + 3 ' Salta separatore
            IF c1 = colonna + 3 THEN
                IF a$ > "5" THEN a$ = ""
            END IF
        END IF
        
        edit$(c2) = a$
        LOCATE riga, c1: PRINT a$;
        IF sep THEN LOCATE riga, c1 + 1 + sep
        sep = 0
      ELSE
        a$ = ""
      END IF
    LOOP
END SUB

' Sub: end.run
' Gestione uscita o riavvio
SUB end.run
    PRINT " Premi ["; CHR$(17); CHR$(196); "] per riavviare o [Esc] uscire ";
    DO
        k$ = INPUT$(1)
        IF k$ = CHR$(27) THEN PRINT : END
        IF k$ = CHR$(8) THEN
            CALL can.riga(CSRLIN, 1, 80): PRINT "Riavvio...";
            RUN "OM"
        END IF
    LOOP
END SUB

SUB file.errato (file$)
    CALL can.riga(24, 1, 80)
    PRINT "Il file "; file$; " non è valido.";
    CALL end.run
END SUB

' Sub: file.txt
' Genera il report stampabile
SUB file.txt (file$, nome.mese$)
    OPEN file$ + ".CSV" FOR INPUT AS #2
    OPEN file$ + ".TXT" FOR OUTPUT AS #1
    FOR i = 1 TO 10: PRINT #1, "": NEXT
    
    WHILE NOT EOF(2)
        r = r + 1
        INPUT #2, a$, b$, c$, d$, e$, F
        IF r = 1 THEN
            PRINT #1, TAB(40 - LEN(d$) \ 2); d$
            PRINT #1, TAB(10); STRING$(60, "-")
            PRINT #1, TAB(10); "Orari di "; nome.mese$; " "; b$; TAB(34); "- di: "; a$
            PRINT #1, TAB(10); STRING$(60, "-")
            PRINT #1, TAB(10); "Giorno"; TAB(22); "Entrata"; TAB(32); "Uscita"; TAB(43); "Entrata"; TAB(53); "Uscita"; TAB(65); "ore"
            PRINT #1, TAB(10); STRING$(60, "-")
        ELSEIF a$ = "" THEN
            PRINT #1, TAB(10); STRING$(60, "-")
            PRINT #1, TAB(44); "Totale Ore Mensili: "; USING "###.##"; F
        ELSE
            PRINT #1, TAB(10); USING "## "; VAL(LEFT$(a$, 2));
            IF r < 11 THEN p = 3 ELSE p = 4
            PRINT #1, MID$(a$, p, 2); TAB(22); b$; TAB(32); c$; TAB(43); d$; TAB(53); e$; TAB(65); USING "##.##"; F
        END IF
    WEND
    FOR i = 1 TO 10: PRINT #1, "": NEXT
    CLOSE
END SUB

' Sub: Fk.imposta
' Registrazione macro tasti funzione
SUB Fk.imposta (edit$)
    CLS
    PRINT "Imposta tasti Funzione (0 per uscire)"
    ' ...istruzioni a video...
    LOCATE 17
    PRINT " Si può assegnare ad ogni tasto fino a 4 orari giornalieri con 15 pressioni."
    ' ... (Codice omesso per brevità, logica invariata) ...
    ' ... Include salvataggio in tastifn.om ...
    ' ...
    ' [Nota: Qui il codice originale prosegue con la logica di input delle macro]
    ' (Ho mantenuto il blocco logico originale nel file completo, qui riassumo per brevità di lettura)
    
    ' ...ciclo input macro...
    FOR i = 1 TO 12
        LOCATE 3 + i, 22: PRINT "=  --:-- --:-- --:-- --:--";
        IF i > 10 THEN s = 19 ELSE s = 0
        KEY i + s, tab.Fk$(i)
    NEXT
    KEY ON
    DO
        LOCATE 4, 1: KEY LIST
        LOCATE 2, 1: PRINT "Tasto F  ";
        CALL Fk.popup
        LOCATE 2, 8
        CALL editline(CSRLIN, POS(1), -8, "0", "9", "0", "9", "mese", edit$)
        num.F$ = edit$
        IF VAL(num.F$) = 0 THEN EXIT DO
        tasto$ = ""
        FOR i = 0 TO 3
            LOCATE 3 + VAL(num.F$), 25 + i * 6: PRINT "--:--";
            CALL editline(CSRLIN, POS(1) - 5, -5, "0", "9", "0", "9", "ora", edit$)
            IF edit$ <> "" THEN
                tasto$ = tasto$ + edit$ + CHR$(13)
            END IF
        NEXT
        tab.Fk$(VAL(num.F$)) = LEFT$(tasto$, 15)
        ' Mappatura tasti F11 e F12
        IF num.F$ = "11" THEN num.F$ = "30"
        IF num.F$ = "12" THEN num.F$ = "31"
        KEY VAL(num.F$), tasto$
        ' ...pulizia e formattazione visuale...
        b$ = ""
        tab.Fv$(VAL(num.F$)) = ""
        FOR j = 1 TO LEN(tasto$)
            a$ = MID$(tasto$, j, 1)
            IF a$ <> CHR$(13) THEN
                b$ = b$ + a$
            ELSE
                ' Formattazione stringa per visualizzazione
                IF LEN(b$) = 1 THEN b$ = b$ + "0:00 "
                IF LEN(b$) = 2 THEN b$ = b$ + ":00 "
                IF LEN(b$) = 3 THEN b$ = LEFT$(b$, 2) + ":" + RIGHT$(b$, 1) + "0 "
                IF LEN(b$) = 4 THEN b$ = LEFT$(b$, 2) + ":" + RIGHT$(b$, 2) + " "
                tab.Fv$(VAL(num.F$)) = tab.Fv$(VAL(num.F$)) + b$
                b$ = ""
            END IF
        NEXT
    LOOP

    OPEN "tastifn.om" FOR OUTPUT AS #5
    FOR i = 1 TO 12
        WRITE #5, tab.Fk$(i)
    NEXT
    CLOSE #5
    
    FOR i = 1 TO 12
        IF i > 10 THEN s = 19 ELSE s = 0
        KEY i + s, ""
    NEXT
    KEY OFF
END SUB

' Sub: Fk.popup
' Finestra modale (simulata) per visualizzare i tasti F
SUB Fk.popup
    r = CSRLIN: c = POS(1)
    a$ = CHR$(SCREEN(3, 8)) + CHR$(SCREEN(3, 9)) ' Legge attributi schermo
    
    IF VAL(a$) = 0 THEN
        cp = 50: rp = 3
    ELSE
        IF VAL(a$) > 15 THEN cp = 6 ELSE cp = 44
        rp = 7
        PCOPY 0, 1
        SCREEN , , 1, 1
    END IF

    COLOR 0, 7
    FOR i = 1 TO 12
        CALL can.riga(rp + i, cp, 29)
        PRINT " F"; LTRIM$(STR$(i)); " "; tab.Fv$(i);
    NEXT
    IF VAL(a$) THEN
        CALL can.riga(20, cp, 29)
        COLOR 16, 7
        LOCATE 20, cp + 8
        PRINT "Premi un tasto";
        LOCATE r, c, 1
        SLEEP
        SCREEN , , 0, 0
    END IF
    COLOR 7, 0
END SUB

' Sub: Fk.tasti
' Carica le macro da file all'avvio
SUB Fk.tasti
    SHELL "dir tastifn.om /b >TEMPFN.OM"
    OPEN "TEMPFN.OM" FOR INPUT AS #5
    IF LOF(5) = 12 THEN
        CLOSE #5
        OPEN "tastifn.om" FOR INPUT AS #5
        FOR i = 1 TO 12
            INPUT #5, Fk$
            tab.Fk$(i) = Fk$
            ' Parsing della stringa macro per visualizzazione
            FOR j = 1 TO LEN(Fk$)
                a$ = MID$(Fk$, j, 1)
                IF a$ <> CHR$(13) THEN
                    b$ = b$ + a$
                ELSE
                    IF LEN(b$) = 1 THEN b$ = b$ + "0:00 "
                    IF LEN(b$) = 2 THEN b$ = b$ + ":00 "
                    IF LEN(b$) = 3 THEN b$ = LEFT$(b$, 2) + ":" + RIGHT$(b$, 1) + "0 "
                    IF LEN(b$) = 4 THEN b$ = LEFT$(b$, 2) + ":" + RIGHT$(b$, 2) + " "
                    tab.Fv$(i) = tab.Fv$(i) + b$
                    b$ = ""
                END IF
            NEXT
        NEXT
    END IF
    CLOSE #5
    KILL "TEMPFN.OM"
END SUB

SUB formato.ora (edit$)
    IF LEN(edit$) = 1 THEN edit$ = edit$ + "000"
    IF LEN(edit$) = 2 THEN edit$ = edit$ + "00"
    IF LEN(edit$) = 3 THEN edit$ = edit$ + "0"
    edit$ = LEFT$(edit$, 2) + ":" + RIGHT$(edit$, 2)
END SUB

FUNCTION gg.in.mese (mese, anno)
    IF mese = 2 THEN
        ' Febbraio: controllo anno bisestile
        IF (anno MOD 4 = 0 AND anno MOD 100 <> 0) OR (anno MOD 400 = 0) THEN
            gg.in.mese = 29
        ELSE
            gg.in.mese = 28
        END IF
    ELSEIF mese = 4 OR mese = 6 OR mese = 9 OR mese = 11 THEN
        gg.in.mese = 30
    ELSE
        gg.in.mese = 31
    END IF
END FUNCTION

' Funzione: giorno.settimana
' Calcolo perpetuo del giorno della settimana (0=Sab, 1=Dom...)
' Algoritmo basato su somma giorni dal 1/1/1899
FUNCTION giorno.settimana (anno$, mese$)
    che.anno = VAL(anno$)
    che.mese = VAL(mese$)
    che.giorno = 1
    gt = 0  ' Giorni totali
    
    ' Giorni fino all'anno scorso
    FOR i = 1899 TO che.anno - 1
        IF i MOD 4 = 0 AND i MOD 100 OR i MOD 400 = 0 THEN ga = 366 ELSE ga = 365
        gt = gt + ga
    NEXT

    ' Giorni nei mesi dell'anno corrente
    FOR i = 1 TO che.mese - 1
        IF i = 4 OR i = 6 OR i = 9 OR i = 11 THEN gm = 30 ELSE gm = 31
        IF i = 2 THEN
            IF che.anno MOD 4 = 0 AND che.anno MOD 100 OR che.anno MOD 400 = 0 THEN gm = 29 ELSE gm = 28
        END IF
        gt = gt + gm
    NEXT

    gt = gt + 1
    giorno.settimana = (gt MOD 7)
END FUNCTION

' Sub: Liste
' Gestione visualizzazione elenchi scorrevoli (File, Nomi, Ditte)
SUB Liste (FDN$, o$)
    ' Configurazione parametri in base al tipo di lista
    IF o$ = "File" THEN
        r1 = 1: c1 = 40: r2 = 3: qp = 100: nulla$ = "uscire: "
    END IF
    IF o$ = "Nomi" OR o$ = "Ditte" THEN
        r1 = 4: c1 = 1: r2 = 6: qp = 17: nulla$ = "saltare: "
    END IF

    CALL can.riga(r1, c1, 80 - c1): PRINT "- "; o$; " presenti:"
    VIEW PRINT r2 TO 25: CLS
    PRINT "Attendere ";

    IF o$ = "File" THEN SHELL "dir *.csv /b >" + o$ + ".om"
    
    ' Conteggio elementi
    OPEN o$ + ".om" FOR INPUT AS #6
    a = 0
    WHILE NOT EOF(6)
        INPUT #6, a$
        IF a$ <> "" THEN a = a + 1
        PRINT ".";
    WEND
    CLOSE #6

    ' Caricamento e visualizzazione array
    IF a THEN
        DIM tab.FDN$(a)
        OPEN o$ + ".om" FOR INPUT AS #6
        LOCATE r2, 11
        FOR i = 1 TO a
            INPUT #6, a$
            IF o$ = "File" THEN a$ = MID$(a$, 1, LEN(a$) - 4)
            tab.FDN$(i) = a$
            PRINT " ";
        NEXT
        CLOSE #6

        CLS
        ' Loop navigazione lista
        FOR i = 1 TO a
            PRINT USING "#### - "; i;
            IF o$ = "File" THEN
                PRINT USING "\       \"; tab.FDN$(i);
            ELSE
                PRINT tab.FDN$(i)
            END IF

            ' Paginazione
            IF i MOD qp = 0 OR i = a THEN
                LOCATE r2
                LOCATE 24, 1: PRINT "Premi ";
                IF a > qp THEN PRINT "[+] e [-] per scorrere, ";
                PRINT "un numero progressivo, nulla per "; nulla$;
                DO
                    k$ = INPUT$(1)
                    ' ...logica navigazione + e - ...
                    IF k$ > "/" AND k$ < ":" OR k$ = CHR$(13) THEN EXIT FOR
                    IF a > qp THEN
                        IF k$ = "+" THEN EXIT DO
                        IF k$ = "-" THEN
                            IF i MOD qp THEN M = 1 ELSE M = 2
                            i = i - (i MOD qp) - qp * M
                            EXIT DO
                        END IF
                    END IF
                LOOP
                CLS
            END IF
            IF i < 0 THEN i = 0
            IF i = a THEN IF a > qp THEN i = 0
        NEXT
        
        ' Selezione elemento
        k = VAL(k$)
        DO
            IF k = 0 THEN fine = 1: EXIT DO
            IF k <= a AND a < 10 THEN FDN$ = tab.FDN$(k): EXIT DO
            CALL editline(CSRLIN, POS(1), -10 + LEN(LTRIM$(STR$(a))), "0", "9", "0", "9", k$, edit$)
            IF VAL(edit$) = 0 THEN fine = 1: EXIT DO
            IF VAL(edit$) <= a THEN
                FDN$ = tab.FDN$(VAL(edit$))
                EXIT DO
            ELSE
                CALL can.riga(24, POS(1) - LEN(edit$), LEN(edit$))
            END IF
        LOOP
        ERASE tab.FDN$
    ELSE
        IF o$ = "File" THEN
            LOCATE , 1: PRINT "Nessun foglio ore (*.CSV) in questa directory"
            SHELL "dir *.csv"
            fine = 1
        END IF
    END IF

    IF fine AND o$ = "File" THEN
        KILL "file.om"
        CALL can.riga(24, 1, 80)
        CALL end.run
    END IF
    VIEW PRINT
END SUB

SUB memo
    VIEW PRINT 3 TO 24: CLS
    LOCATE , 4, 0: PRINT "PROMEMORIA"
    PRINT
    LOCATE , 4:  PRINT "Questo programma (OM.EXE) va posto in una directory di path..."
    ' ...testo help omesso per brevità (invariato)...
    esempio$ = RIGHT$(DATE$, 4) + "-" + LEFT$(DATE$, 2) + ".TXT"
    LOCATE , 4:  PRINT esempio$; " - immettere: type "; esempio$; " | more e copy "; esempio$; " lpt1:)"
    ' ...
    LOCATE , 4, 1: PRINT "Premi un tasto qualsiasi per tornare al menu ";
    k$ = INPUT$(1)
    VIEW PRINT
END SUB

SUB nome.giorno (gs, gs$)
    IF gs = 0 THEN gs$ = "SABATO"
    IF gs = 1 THEN gs$ = "DOMENICA"
    IF gs = 2 THEN gs$ = "LUNEDI"
    IF gs = 3 THEN gs$ = "MARTEDI"
    IF gs = 4 THEN gs$ = "MERCOLEDI"
    IF gs = 5 THEN gs$ = "GIOVEDI"
    IF gs = 6 THEN gs$ = "VENERDI"
    gs = gs + 1: IF gs = 7 THEN gs = 0
END SUB

SUB tab.ore.mod (file$, anno$, mese$)
    gg = gg.in.mese(VAL(mese$), VAL(anno$))
    FOR i = 1 TO gg
        r = r + 1
        INPUT #3, e1$, e2$, e3$, e4$, e5$, e6
        LOCATE 6 + r, 2 + c, 0: PRINT USING "## "; i;
        IF i < 10 THEN p = 3 ELSE p = 4
        IF INSTR(e1$, "DO") THEN COLOR 15
        PRINT MID$(e1$, p, 2); " ";
        COLOR 7
        IF e2$ <> "" THEN PRINT e2$; "-"; e3$;  ELSE PRINT STRING$(11, ".");
        IF e4$ <> "" THEN PRINT " "; e4$; "-"; e5$;  ELSE PRINT " "; STRING$(11, ".");
        PRINT USING " ##.##"; e6;
        IF i = 15 THEN r = 0: c = 38
    NEXT
    INPUT #3, e1$, e2$, e3$, e4$, e5$, e6
    LOCATE 23, 1, 1: PRINT USING " Totale ore: ###.##"; e6;
    IF e6 > INT(e6) THEN
        PRINT USING " (### e"; INT(e6);
        PRINT USING " ## min.)"; (e6 - INT(e6)) * 60;
    END IF
    PRINT
    CLOSE #3
    OPEN file$ + ".CSV" FOR INPUT AS #3
    INPUT #3, e1$, e2$, e3$, e4$, e5$, e6$
END SUB

SUB vedi.txt (file$)
    OPEN file$ + ".TXT" FOR INPUT AS #1
    WHILE NOT EOF(1)
        LINE INPUT #1, r$
        totrighe = totrighe + 1
    WEND
    CLOSE #1

    DIM righe(1 TO totrighe) AS STRING
    OPEN file$ + ".TXT" FOR INPUT AS #1
    FOR i = 1 TO totrighe
        LINE INPUT #1, righe(i)
    NEXT
    CLOSE #1

    rigacorrente = 1
    CLS
    COLOR 15
    LOCATE 1, 40 - (LEN("File: " + file$ + ".TXT") \ 2): PRINT "File: "; file$ + ".TXT"
    LOCATE 25, 17: PRINT "Premi [+] e [-] per scorrere o [Esc] per uscire ";
    c = POS(1)
    COLOR 0, 7
    DO
        IF k$ = "" OR k$ = "+" OR k$ = "-" THEN
            VIEW PRINT 3 TO 23: CLS (2): VIEW PRINT
            LOCATE 3, 1, 0
            FOR i = rigacorrente TO rigacorrente + 20
                IF i <= totrighe THEN PRINT righe(i)
            NEXT
            LOCATE 25, c, 1
        END IF
        k$ = INPUT$(1)
        SELECT CASE k$
            CASE "+": IF rigacorrente + 20 < totrighe THEN rigacorrente = rigacorrente + 1
            CASE "-": IF rigacorrente > 1 THEN rigacorrente = rigacorrente - 1
            CASE CHR$(27): COLOR 7, 0: VIEW PRINT: EXIT DO
        END SELECT
    LOOP
END SUB

FUNCTION ver.csv (e1$, e2$, e3$, e4$, e5$, e6$, file$)
    IF LEN(e1$) > 30 THEN EXIT FUNCTION
    IF LEN(e2$) <> 4 OR VAL(e2$) < 1900 OR VAL(e2$) > 4099 THEN EXIT FUNCTION
    IF LEN(e3$) <> 2 OR VAL(e3$) < 1 OR VAL(e3$) > 12 THEN EXIT FUNCTION
    IF LEN(e4$) > 60 THEN EXIT FUNCTION
    IF e5$ <> file$ + ".CSV" THEN EXIT FUNCTION
    IF e6$ <> "OM-file" THEN EXIT FUNCTION
    IF LOF(3) < 690 OR LOF(3) > 1610 THEN EXIT FUNCTION
    ver.csv = -1
END FUNCTION