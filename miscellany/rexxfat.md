**rexxfat** 0.6 self test output:

```
c:\Temp>rexxfat *
test  0: PASS
-------------------------------------------------------------------------------
test  1: REXXFAT 4 1 1
a:       1 * 1 FAT12 sectors;   1 +   1 SYS;   1 *         1 data:            1
Uses a for c:\Temp\rexxfat.vfd with 4 sectors
VFD padded to min. 8 sectors
created [0AEF-0F5A] in sparse c:\Temp\rexxfat.vfd
test  1: PASS
-------------------------------------------------------------------------------
test  2: REXXFAT 4 1 1 512
a:       1 * 1 FAT12 sectors;   1 +   1 SYS;   1 *         1 data:            1
Uses a for c:\Temp\rexxfat.vfd with 4 sectors
VFD padded to min. 8 sectors
created [0AEF-1026] in sparse c:\Temp\rexxfat.vfd
test  2: PASS
-------------------------------------------------------------------------------
test  3: REXXFAT 4 1 1 8192 SECLEN 8192

Error: 8192
Usage: rexxfat.rex SECTORS [MINDIR [NUMFAT [SECLEN]]]
REXXFAT 0.6 for NTFS and Windows NT ooREXX.
test  3: PASS
-------------------------------------------------------------------------------
test  4: REXXFAT 4 1 1 64 SECLEN 64

Error: 64
Usage: rexxfat.rex SECTORS [MINDIR [NUMFAT [SECLEN]]]
REXXFAT 0.6 for NTFS and Windows NT ooREXX.
test  4: PASS
-------------------------------------------------------------------------------
test  5: REXXFAT 4 1 1 4096
a:       1 * 1 FAT12 sectors;   1 +   1 SYS;   1 *         1 data:            1
Uses a for c:\Temp\rexxfat.vfd with sector size 4096
created [0AEF-1041] in sparse c:\Temp\rexxfat.vfd
test  5: PASS
-------------------------------------------------------------------------------
test  6: REXXFAT 4 1 1 128
a:       1 * 1 FAT12 sectors;   1 +   1 SYS;   1 *         1 data:            1
Uses a for c:\Temp\rexxfat.vfd with sector size 128
VFD padded to min. 32 sectors
created [0AEF-1057] in sparse c:\Temp\rexxfat.vfd
test  6: PASS
-------------------------------------------------------------------------------
test  7: REXXFAT 4 1 1 128 extraneous

Error: extraneous
Usage: rexxfat.rex SECTORS [MINDIR [NUMFAT [SECLEN]]]
REXXFAT 0.6 for NTFS and Windows NT ooREXX.
test  7: PASS
-------------------------------------------------------------------------------
test  8: REXXFAT 4 1 2 . 1+2+1+1 = 5 > 4
Found no FAT for 4 sectors, 2 FATs, and 1 root dir. sectors
test  8: PASS
-------------------------------------------------------------------------------
test  9: REXXFAT 4 2 1 . 1+1+2+1 = 5 > 4
Found no FAT for 4 sectors, 1 FATs, and 2 root dir. sectors
test  9: PASS
-------------------------------------------------------------------------------
test 10: REXXFAT 4 0 2 . no DIR in FAT1x
Found no FAT for 4 sectors, 2 FATs, and 0 root dir. sectors
test 10: PASS
-------------------------------------------------------------------------------
test 11: REXXFAT 4 1 0 . no FAT in FATFS

Error: 0
Usage: rexxfat.rex SECTORS [MINDIR [NUMFAT [SECLEN]]]
REXXFAT 0.6 for NTFS and Windows NT ooREXX.
test 11: PASS
-------------------------------------------------------------------------------
test 12: REXXFAT 20 2 16
a:       1 *16 FAT12 sectors;   1 +   2 SYS;   1 *         1 data:            1
Uses a for c:\Temp\rexxfat.vfd with 20 sectors
created [0AEF-1063] in sparse c:\Temp\rexxfat.vfd
test 12: PASS
-------------------------------------------------------------------------------
test 13: REXXFAT 20 1 17 . too many FATs

Error: 17
Usage: rexxfat.rex SECTORS [MINDIR [NUMFAT [SECLEN]]]
REXXFAT 0.6 for NTFS and Windows NT ooREXX.
test 13: PASS
-------------------------------------------------------------------------------
test 14: REXXFAT 24 8 1 0 8+ 8+8+8=32 >24
Found no FAT for 24 sectors, 1 FATs, and 8 root dir. sectors
test 14: PASS
-------------------------------------------------------------------------------
test 15: REXXFAT 36 8 1 0 36 is not n*8
512e requires multiples of 8 sectors; got 36 with MINDIR 8
test 15: PASS
-------------------------------------------------------------------------------
test 16: REXXFAT 32 6 1 0  6 is not n*8
512e requires multiples of 8 sectors; got 32 with MINDIR 6
test 16: PASS
-------------------------------------------------------------------------------
test 17: REXXFAT 32 8 2 0 8+16+8+8=40 >32
Found no FAT for 32 sectors, 2 FATs, and 8 root dir. sectors
test 17: PASS
-------------------------------------------------------------------------------
test 18: REXXFAT 32 8 1 0
a:       8 * 1 FAT12 sectors;   8 +   8 SYS;   8 *         1 data:            8
Uses a for c:\Temp\rexxfat.vfd with 32 sectors
created [0AEF-111A] in sparse c:\Temp\rexxfat.vfd
test 18: PASS
-------------------------------------------------------------------------------
test 19: REXXFAT 66557 0
a:     512 * 2 FAT32 sectors;   7 +   0 SYS;   1 *     65526 data:        65526
Uses a for c:\Temp\rexxfat.vfd with 66557 sectors
created [0AEF-1126] in sparse c:\Temp\rexxfat.vfd
test 19: PASS
-------------------------------------------------------------------------------
test 20: REXXFAT 66565 .
a:     512 * 2 FAT32 sectors;  15 +   0 SYS;   1 *     65526 data:        65526
b:     130 * 2 FAT16 sectors;   1 +   8 SYS;   2 *     33148 data:        66296
c:      65 * 2 FAT16 sectors;   1 +  10 SYS;   4 *     16606 data:        66424
d:      33 * 2 FAT16 sectors;   1 +  10 SYS;   8 *      8311 data:        66488
e:      17 * 2 FAT16 sectors;   1 +  18 SYS;  16 *      4157 data:        66512
f:       7 * 2 FAT12 sectors;   1 +  22 SYS;  32 *      2079 data:        66528
g:       4 * 2 FAT12 sectors;   1 +  60 SYS;  64 *      1039 data:        66496
h:       2 * 2 FAT12 sectors;   1 + 128 SYS; 128 *       519 data:        66432
Uses a for c:\Temp\rexxfat.vfd with 66565 sectors
created [0AEF-164C] in sparse c:\Temp\rexxfat.vfd
test 20: PASS
-------------------------------------------------------------------------------
test 21: REXXFAT 525240 0 . 0
a:     512 * 2 FAT32 sectors;   8 +   0 SYS;   8 *     65526 data:       524208
Uses a for c:\Temp\rexxfat.vfd with 525240 sectors
created [0AEF-1C30] in sparse c:\Temp\rexxfat.vfd
test 21: PASS
-------------------------------------------------------------------------------
test 22: REXXFAT 525248 . . 0
a:     512 * 2 FAT32 sectors;  16 +   0 SYS;   8 *     65526 data:       524208
b:     136 * 2 FAT16 sectors;   8 +   8 SYS;  16 *     32810 data:       524960
c:      72 * 2 FAT16 sectors;   8 +   8 SYS;  32 *     16409 data:       525088
d:      40 * 2 FAT16 sectors;   8 +  40 SYS;  64 *      8205 data:       525120
e:      24 * 2 FAT16 sectors;   8 +   8 SYS; 128 *      4103 data:       525184
Uses a for c:\Temp\rexxfat.vfd with 525248 sectors
created [0AEF-3E4A] in sparse c:\Temp\rexxfat.vfd
test 22: PASS
-------------------------------------------------------------------------------
test 23: REXXFAT -17 1
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:       1 * 2 FAT12 sectors;   1 +   1 SYS;   1 *        12 data:           12
b:       1 * 2 FAT12 sectors;   1 +   1 SYS;   2 *         6 data:           12
c:       1 * 2 FAT12 sectors;   1 +   1 SYS;   4 *         3 data:           12
d:       1 * 2 FAT12 sectors;   1 +   5 SYS;   8 *         1 data:            8
Uses a for c:\Temp\rexxfat.vhd with 16 sectors
Please check dummy 16+4+8=28 bits VHD geometry.
created [0AF0-2D55] in output c:\Temp\rexxfat.vhd
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT.
Volumeseriennummer : 0AF0-2D55
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Das Dateisystem wurde überprüft. Es wurden keine Probleme festgestellt.

        6.144 Bytes Speicherplatz auf dem Datenträger insgesamt
        6.144 Bytes auf dem Datenträger verfügbar

          512 Bytes in jeder Zuordnungseinheit
           12 Zuordnungseinheiten auf dem Datenträger insgesamt
           12 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 23: PASS
-------------------------------------------------------------------------------
test 24: REXXFAT -32 8 1 0
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:       8 * 1 FAT12 sectors;   7 +   8 SYS;   8 *         1 data:            8
Uses a for c:\Temp\rexxfat.vhd with 31 sectors
created [0AF1-1162] in output c:\Temp\rexxfat.vhd
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT.
Volumeseriennummer : 0AF1-1162
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Das Dateisystem wurde überprüft. Es wurden keine Probleme festgestellt.

        4.096 Bytes Speicherplatz auf dem Datenträger insgesamt
        4.096 Bytes auf dem Datenträger verfügbar

        4.096 Bytes in jeder Zuordnungseinheit
            1 Zuordnungseinheiten auf dem Datenträger insgesamt
            1 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 24: PASS
-------------------------------------------------------------------------------
test 25: REXXFAT -4142 32
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:      12 * 2 FAT12 sectors;   1 +  32 SYS;   1 *      4084 data:         4084
b:       7 * 2 FAT12 sectors;   1 +  32 SYS;   2 *      2047 data:         4094
c:       4 * 2 FAT12 sectors;   1 +  32 SYS;   4 *      1025 data:         4100
d:       2 * 2 FAT12 sectors;   1 +  32 SYS;   8 *       513 data:         4104
e:       1 * 2 FAT12 sectors;   1 +  42 SYS;  16 *       256 data:         4096
f:       1 * 2 FAT12 sectors;   1 +  42 SYS;  32 *       128 data:         4096
g:       1 * 2 FAT12 sectors;   1 +  42 SYS;  64 *        64 data:         4096
h:       1 * 2 FAT12 sectors;   1 +  42 SYS; 128 *        32 data:         4096
Uses a for c:\Temp\rexxfat.vhd with 4141 sectors
Please check dummy 16+4+8=28 bits VHD geometry.
created [0AF1-1F38] in output c:\Temp\rexxfat.vhd
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT.
Volumeseriennummer : 0AF1-1F38
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Das Dateisystem wurde überprüft. Es wurden keine Probleme festgestellt.

    2.091.008 Bytes Speicherplatz auf dem Datenträger insgesamt
    2.091.008 Bytes auf dem Datenträger verfügbar

          512 Bytes in jeder Zuordnungseinheit
        4.084 Zuordnungseinheiten auf dem Datenträger insgesamt
        4.084 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 25: PASS
-------------------------------------------------------------------------------
test 26: REXXFAT -4151 32 . -512
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:      16 * 2 FAT16 sectors;   1 +  32 SYS;   1 *      4085 data:         4085
b:       7 * 2 FAT12 sectors;   1 +  33 SYS;   2 *      2051 data:         4102
c:       4 * 2 FAT12 sectors;   1 +  33 SYS;   4 *      1027 data:         4108
d:       2 * 2 FAT12 sectors;   1 +  33 SYS;   8 *       514 data:         4112
e:       1 * 2 FAT12 sectors;   1 +  35 SYS;  16 *       257 data:         4112
f:       1 * 2 FAT12 sectors;   1 +  51 SYS;  32 *       128 data:         4096
g:       1 * 2 FAT12 sectors;   1 +  51 SYS;  64 *        64 data:         4096
h:       1 * 2 FAT12 sectors;   1 +  51 SYS; 128 *        32 data:         4096
Uses a for c:\Temp\rexxfat.vhd with 4150 sectors
created [0AF1-2B6A] in output c:\Temp\rexxfat.vhd
CHKDSK: expecting error, reject repairs
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT.
Volumeseriennummer : 0AF1-2B6A
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Windows hat auf dem Datenträger Fehler gefunden, wird diese aber nicht repariere
r /F nicht angegeben wurde.
Fehlerhafte Verknüpfungen in verlorener Kette in Cluster 2 berichtigt.
Verlorene Ketten in Dateien umwandeln (J/N)? n
Es würden 512 Bytes freier Speicherplatz hinzugefügt.
Windows hat Probleme im Dateisystem festgestellt.
Führen Sie CHKDSK mit der Option /F (Fehlerbehebung) aus, um die Probleme zu
beheben.

    2.091.520 Bytes Speicherplatz auf dem Datenträger insgesamt
    2.091.008 Bytes auf dem Datenträger verfügbar

          512 Bytes in jeder Zuordnungseinheit
        4.085 Zuordnungseinheiten auf dem Datenträger insgesamt
        4.084 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 26: PASS
-------------------------------------------------------------------------------
test 27: REXXFAT -4152 32
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:      16 * 2 FAT16 sectors;   1 +  32 SYS;   1 *      4086 data:         4086
b:       7 * 2 FAT12 sectors;   1 +  32 SYS;   2 *      2052 data:         4104
c:       4 * 2 FAT12 sectors;   1 +  34 SYS;   4 *      1027 data:         4108
d:       2 * 2 FAT12 sectors;   1 +  34 SYS;   8 *       514 data:         4112
e:       1 * 2 FAT12 sectors;   1 +  36 SYS;  16 *       257 data:         4112
f:       1 * 2 FAT12 sectors;   1 +  52 SYS;  32 *       128 data:         4096
g:       1 * 2 FAT12 sectors;   1 +  52 SYS;  64 *        64 data:         4096
h:       1 * 2 FAT12 sectors;   1 +  52 SYS; 128 *        32 data:         4096
Uses a for c:\Temp\rexxfat.vhd with 4151 sectors
created [0AF2-1E38] in output c:\Temp\rexxfat.vhd
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT.
Volumeseriennummer : 0AF2-1E38
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Das Dateisystem wurde überprüft. Es wurden keine Probleme festgestellt.

    2.092.032 Bytes Speicherplatz auf dem Datenträger insgesamt
    2.092.032 Bytes auf dem Datenträger verfügbar

          512 Bytes in jeder Zuordnungseinheit
        4.086 Zuordnungseinheiten auf dem Datenträger insgesamt
        4.086 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 27: PASS
-------------------------------------------------------------------------------
test 28: REXXFAT -66070 32
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:     256 * 2 FAT16 sectors;   1 +  32 SYS;   1 *     65524 data:        65524
b:     129 * 2 FAT16 sectors;   1 +  32 SYS;   2 *     32889 data:        65778
c:      65 * 2 FAT16 sectors;   1 +  34 SYS;   4 *     16476 data:        65904
d:      33 * 2 FAT16 sectors;   1 +  34 SYS;   8 *      8246 data:        65968
e:      17 * 2 FAT16 sectors;   1 +  34 SYS;  16 *      4125 data:        66000
f:       7 * 2 FAT12 sectors;   1 +  38 SYS;  32 *      2063 data:        66016
g:       4 * 2 FAT12 sectors;   1 +  76 SYS;  64 *      1031 data:        65984
h:       2 * 2 FAT12 sectors;   1 + 144 SYS; 128 *       515 data:        65920
Uses a for c:\Temp\rexxfat.vhd with 66069 sectors
created [0AF2-2861] in output c:\Temp\rexxfat.vhd
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT.
Volumeseriennummer : 0AF2-2861
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Das Dateisystem wurde überprüft. Es wurden keine Probleme festgestellt.

   33.548.288 Bytes Speicherplatz auf dem Datenträger insgesamt
   33.548.288 Bytes auf dem Datenträger verfügbar

          512 Bytes in jeder Zuordnungseinheit
       65.524 Zuordnungseinheiten auf dem Datenträger insgesamt
       65.524 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 28: PASS
-------------------------------------------------------------------------------
test 29: REXXFAT -66565 . . -512
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:     512 * 2 FAT32 sectors;  15 +   0 SYS;   1 *     65525 data:        65525
b:     130 * 2 FAT16 sectors;   1 +   9 SYS;   2 *     33147 data:        66294
c:      65 * 2 FAT16 sectors;   1 +   9 SYS;   4 *     16606 data:        66424
d:      33 * 2 FAT16 sectors;   1 +   9 SYS;   8 *      8311 data:        66488
e:      17 * 2 FAT16 sectors;   1 +  17 SYS;  16 *      4157 data:        66512
f:       7 * 2 FAT12 sectors;   1 +  21 SYS;  32 *      2079 data:        66528
g:       4 * 2 FAT12 sectors;   1 +  59 SYS;  64 *      1039 data:        66496
h:       2 * 2 FAT12 sectors;   1 + 127 SYS; 128 *       519 data:        66432
Uses a for c:\Temp\rexxfat.vhd with 66564 sectors
created [0AF2-3D58] in output c:\Temp\rexxfat.vhd
CHKDSK: expecting error, reject repairs
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT32.
Nicht genügend Arbeitsspeicher
Unbekannter Fehler (666174766f6c2e63 d6).
CHKDSK: detaching VHD, please wait a minute
test 29: PASS
-------------------------------------------------------------------------------
test 30: REXXFAT -66566 .
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:     512 * 2 FAT32 sectors;  15 +   0 SYS;   1 *     65526 data:        65526
b:     130 * 2 FAT16 sectors;   1 +   8 SYS;   2 *     33148 data:        66296
c:      65 * 2 FAT16 sectors;   1 +  10 SYS;   4 *     16606 data:        66424
d:      33 * 2 FAT16 sectors;   1 +  10 SYS;   8 *      8311 data:        66488
e:      17 * 2 FAT16 sectors;   1 +  18 SYS;  16 *      4157 data:        66512
f:       7 * 2 FAT12 sectors;   1 +  22 SYS;  32 *      2079 data:        66528
g:       4 * 2 FAT12 sectors;   1 +  60 SYS;  64 *      1039 data:        66496
h:       2 * 2 FAT12 sectors;   1 + 128 SYS; 128 *       519 data:        66432
Uses a for c:\Temp\rexxfat.vhd with 66565 sectors
Please check dummy 16+4+8=28 bits VHD geometry.
created [0AF3-3132] in output c:\Temp\rexxfat.vhd
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT32.
Volumeseriennummer : 0AF3-3132
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Das Dateisystem wurde überprüft. Es wurden keine Probleme festgestellt.

   33.549.312 Bytes Speicherplatz auf dem Datenträger insgesamt
   33.548.800 Bytes auf dem Datenträger verfügbar

          512 Bytes in jeder Zuordnungseinheit
       65.526 Zuordnungseinheiten auf dem Datenträger insgesamt
       65.525 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 30: PASS
-------------------------------------------------------------------------------
test 31: REXXFAT -66558 0
press ENTER for CHKDSK c:\Temp\rexxfat.vhd

a:     512 * 2 FAT32 sectors;   7 +   0 SYS;   1 *     65526 data:        65526
Uses a for c:\Temp\rexxfat.vhd with 66557 sectors
created [0AF4-0C33] in output c:\Temp\rexxfat.vhd
CHKDSK: attaching VHD, please wait a minute
Der Typ des Dateisystems ist FAT32.
Volumeseriennummer : 0AF4-0C33
Dateien und Ordner werden überprüft...
Die Datei- und Ordnerüberprüfung ist abgeschlossen.
Das Dateisystem wurde überprüft. Es wurden keine Probleme festgestellt.

   33.549.312 Bytes Speicherplatz auf dem Datenträger insgesamt
   33.548.800 Bytes auf dem Datenträger verfügbar

          512 Bytes in jeder Zuordnungseinheit
       65.526 Zuordnungseinheiten auf dem Datenträger insgesamt
       65.525 Zuordnungseinheiten auf dem Datenträger verfügbar
CHKDSK: detaching VHD, please wait a minute
test 31: PASS
-------------------------------------------------------------------------------
self tests okay

c:\Temp>
```

In test 26 **chkdsk** rejects a FAT16 with 4085 (0xFF5) clusters and suggests to
"repair" this.

In test 29 **chkdsk** crashes for a FAT32 with 65525 (0xFFF5) clusters. 4085 and
65525 should be the minimal cluster sizes for FAT16/32 as specified by MS, but
they implemented 4086 (test 27) and 65526 (test 30) as "off by one" minimum with
4084 (test 25) and 65524 (test 28) working as expected, i.e., FAT12/16 maximum.
