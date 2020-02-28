/* Classic REXX 4.00 .. 6.0n (tested: Regina 3.8 and ooRexx 4.2). */
/* A static Regina will do, the REXXUTIL library is NOT required. */

/* Purpose: Portable REXX procedures to convert UTF-8 strings to  */
/*          some supported SBCS (Single Byte Character Set) code  */
/*          pages, or vice versa.  These procedures are designed  */
/*          for SBCS code pages based on US-ASCII, anything else  */
/*          (EBCDIC, UTF-16, UTF-7, etc.) won't work.             */

/* This is only the code and a small test suite, copy procedures  */
/* UTF.I (UTF-8 to local), UTF.O (local to UTF-8), and UTF.8 to a */
/* a script needing UTF-8 conversions.                            */

/* UTF.I( x, cp ) decodes an UTF-8 string x for codepage cp.      */
/* UTF.O( x, cp ) encodes a codepage cp string x into UTF-8.      */
/* The 2nd argument cp can be omitted after it was initialized.   */

/* UTF. is a global variable exposed by UTF.I() and UTF.O(), it   */
/* is reinitialized if a 2nd argument for UTF.I() or UTF.O() does */
/* not match the last used local codepage.                        */

/* History - see also <URL:http://purl.net/xyzzy/src/utf-8.cmd> : */
/* 0.1 - added codepage 437 using <URL:http://www.eki.ee/letter/> */
/*     - obvious bug in UTF.I() REXX positional parsing fixed :-( */
/* 0.2 - avoid syntax trap in UTF.I() for invalid UTF.8 strings   */
/*     - added UTF.I() test cases for nine invalid UTF-8 strings  */
/*     - moved old tests to procedure DEBUG, two codepages tested */
/*     - use OS/2 SysQueryProcessCodePage() directly (+ comments) */
/* 0.3 - 80..BF now "eat" only 1 byte, shown as one unknown char. */
/*     - C0..C1 still "eat" 2 bytes, shown as 1 unknown character */
/*     - F5..F7 still "eat" 4 bytes (F5..FD illegal for RfC 3629) */
/*     - F8..FB still "eat" 5 bytes (F5..FD unused for ISO 10646) */
/*     - FC..FD still "eat" 6 bytes (F5..FD allow 2**31 Unicodes) */
/*     - FE..FF now "eat" only 1 byte, shown as one unknown char. */
/*     - added tests EF BB BF (u+FEFF BOM) and C0 AF (bad 2F '/') */
/*     - bad / unknown / unsupported character shown as UTF.? set */
/*       by UTF. = '?', any US-ASCII character could be used      */
/* 0.4 - bug fix for windows-1252 (OS/2 1004) 8D, 8E, 9D, 9E, 9F  */
/* 0.5 - bug fix for invalid u+4000000 encoding as FC84 8080 8080 */
/*       etc. only used in <http://purl.net/xyzzy/kex/x-wiki.kex> */
/* 0.6 - SysQueryProcessCodePage() removed:  UTF.I() and UTF.O()  */
/*       now expect a 2nd argument specifying the local codepage  */
/* 0.7 - replaced UTF-8 prose explanation by simple CharMapML     */
/*     - replaced '?' by ASCII SUB (0x1A) for unmapped char.s     */
/*     - added Latin-9 and MacRoman; explicit Latin-1, no default */
/* 0.8 - added ibm-878 (KOI8-R) for the Russian OS/2 community    */
/* 0.9 - renamed 'MAC' Roman to '10000' (the number used on W2K)  */
/*       added '28591' as alias of '819' for ISO 8859-1           */
/*       added '28605' as alias of '923' for ISO 8859-15          */
/*       Various not yet supported W2K codepages to complete the  */
/*       already implemented Latin-1 and Cyrillic variants, plus  */
/*       some obscure W2K codepages noted here "while I'm at it": */
/*         855:  OEM Cyrillic                                     */
/*         866:  OEM Russian                                      */
/*        1251: ANSI Cyrillic, presumably 28595 excl. C1 controls */
/*       10017:  MAC Cyrillic                                     */
/*       28593:  IS0 8859-3 (Latin-3, Esperanto)                  */
/*       28595:  IS0 8859-5 (Cyrillic)                            */
/*       28599:  IS0 8859-9 (Latin-5)                             */
/*       65001: UTF-8        ToDo: find IBM UTF-8 codepage number */
/*       20127: US-ASCII     ToDo: figure out what US-ASCII is... */
/*       20105:  IA5 IRV     ToDo: allow pure 7bit US-ASCII input */
/*       20106:  IA5 German (out of scope, noted for reference)   */
/*       20261: T.61                         ToDo: what is this ? */
/*       20269:  ISO 6937 non-spacing accent (out of scope)       */
/*       21027:  Ext Alpha lower case        ToDo: what is this ? */
/* 1.0 - removed the since version 0.6 unused UTIL() procedure    */
/*     - fixed version number in a comment, was still 0.8 for 0.9 */
/*     - kept the old <URL:http://purl.net/xyzzy/src/utf-8.cmd> , */
/*       but at the moment this URL is broken.                    */
/*     - replaced a convoluted TRAP() handler for TRL2 REXX 4.00  */
/*       by a simpler ERROR() handler for ANSI REXX 5.00 tested   */
/*       with Regina 3.8 (REXX 5.00) and ooRexx 4.2 (oREXX 6.04). */
/*     - added a USAGE() procedure (see below)                    */
/*     - added a TEST() procedure for the old 0.9 self tests      */
/*     - added a new UTF.O() demo, it converts an argument string */
/*       to UTF-8, see USAGE() for details.                       */
/*     - added an ERROR() exit for an unsupported code page, the  */
/*       UTF.O() demo will report an unknown code page explicitly */
/* --------------------------------------------------------------
<?xml version="1.0" encoding="US-ASCII" ?>
<!DOCTYPE characterMapping SYSTEM
 "http://www.unicode.org/reports/tr22/CharacterMapping.dtd">

<characterMapping
 id="utf-8"
 version="1"
 description="Based on the UTF-8 example in UTS #22"
 normalization="neither">
<validity>
    <state type="FIRST" next="VALID"    s="00" e="7F" />
    <state type="FIRST" next="T1"       s="C2" e="DF" />
    <state type="FIRST" next="LE0"      s="E0"        />
    <state type="FIRST" next="T2"       s="E1" e="EC" />
    <state type="FIRST" next="LED"      s="ED"        />
    <state type="FIRST" next="T2"       s="EE" e="EF" />
    <state type="FIRST" next="LF0"      s="F0"        />
    <state type="FIRST" next="T3"       s="F1" e="F3" />
    <state type="FIRST" next="LF4"      s="F4"        />

    <state type="T1"    next="VALID"    s="80" e="BF" />
    <state type="T2"    next="T1"       s="80" e="BF" />
    <state type="T3"    next="T2"       s="80" e="BF" />

    <state type="LE0"   next="T1"       s="A0" e="BF" />
    <state type="LED"   next="T1"       s="80" e="9F" />

    <state type="LF0"   next="T2"       s="90" e="BF" />
    <state type="LF4"   next="T2"       s="80" e="8F" />
</validity>
<assignments  sub="EF BF BD">
    <range bFirst="00"              bLast="7F"
             bMin="00"               bMax="7F"
           uFirst="0000"            uLast="007F"        />
    <range bFirst="C2 80"           bLast="DF BF"
             bMin="C2 80"            bMax="DF BF"
           uFirst="0080"            uLast="07FF"        />
    <range bFirst="E0 A0 80"        bLast="ED 9F BF"
             bMin="E0 80 80"         bMax="ED BF BF"
           uFirst="0800"            uLast="D7FF"        />
    <range bFirst="EE 80 80"        bLast="EF BF BF"
             bMin="EE 80 80"         bMax="EF BF BF"
           uFirst="E000"            uLast="FFFF"        />
    <range bFirst="F0 90 80 80"     bLast="F4 8F BF BF"
             bMin="F0 80 80 80"      bMax="F4 BF BF BF"
           uFirst="10000"           uLast="10FFFF"      />
</assignments>
</characterMapping>
   -------------------------------------------------------------- */
/* The simplified intro for version 1.0 offers a new USAGE() and  */
/* a new DEMO() procedure.  The new TEST() procedure is actually  */
/* the same test suite as in version 0.9.                         */

   signal on novalue name ERROR  ;  numeric digits 20

   select
      when  arg() > 2               then  return USAGE( '' )
      when  arg() = 2               then  parse arg OPT, SRC
      when  arg() < 2               then  parse arg OPT  SRC
   end
   if OPT = '' & SRC = ''           then  return TEST()
   if OPT = ''                      then  return USAGE( SRC )
   if SRC = ''                      then  do
      SRC = '? -? -h /? /h'      /* accepting common help options */
      if wordpos( OPT, SRC ) = 0    then  return USAGE( OPT )
                                    else  return USAGE()
   end
   if datatype( OPT, 'w' ) = 0      then  return USAGE( OPT )
   if OPT < 0                       then  return USAGE( OPT )

   STR = strip( SRC )            ;  LEN = length( STR )
   TMP = left( STR, 1 )          /* try to unquote quoted string: */
   if TMP <> '"' & TMP <> "'"       then  return UTF.O( SRC, OPT )
   if pos( TMP, STR, 2 ) < LEN      then  return UTF.O( SRC, OPT )
   return UTF.O( substr( STR, 2, LEN - 2 ), OPT )

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE '[CP string]'
   say                           /* suited for REXXC tokenization */
   say '  Without argument (no or empty string) run the self tests '
   say '  for the supported code pages.  Otherwise convert a given '
   say '  string to UTF-8 from code page CP.  Supported code pages:'
   say '  437             en-US DOS                                '
   say '  819 (aka 28591) Latin-1         28590+ 1 for ISO 8859-1  '
   say '  850 (OS/2) interpreted as  858, 850 had u+0131 at 0xD5   '
   say '  858             western DOS   , 858 has u+20AC at 0xD5   '
   say '  878             KOI8-R                                   '
   say '  923 (aka 28605) Latin-9       , 28590+15 for ISO 8859-15 '
   say ' 1004 (OS/2) interpreted as 1252, TBD: check ICU difference'
   say ' 1252             windows-1252                             '
   say '10000             Mac Roman with Omega, Euro, and u+F8FF   '
   return 1

/* -------------------------------------------------------------- */
/* The same test suite as in 0.9 replacing the TRAP() handler by  */
/* a simpler ERROR() handler.  DEBUG() belongs to the test suite. */

TEST:    procedure
   if UTF.O( /**/, 819 ) \== ''  then  exit TRAP( 'init. Latin-1' )

   U = x2c( 77 66 55 44 33 22 )     /* up to 5 char.s "eaten" by  */
   do N = 0 to 8                    /* test invalid UTF-8 strings */
      C = x2c( 22 || b2x( left( copies( 1, N ), 8, 0 ))) || U
      if N = 0 then  C = x2c( '22 EF BB BF 22 C0 AF 22' )
      say 'bad UTF-8' c2x( C ) '=>' c2x( UTF.I( C )) UTF.I( C )
   end N

   Q = '437 858 1252 819 923 878 10000'
   do W = 1 to words( Q )
      CP = word( Q, W )
      select
         when  CP =   437  then  P = '( US PC DOS)   437:'
         when  CP =   858  then  P = '( OS/2  850)   858:'
         when  CP =  1252  then  P = '( OS/2 1004)  1252:'
         when  CP =   819  then  P = '(ISO 8859-1)   819:'
         when  CP =   923  then  P = '(ISO 8859-15)  923:'
         when  CP =   878  then  P = '( KOI8-R   )   878:'
         when  CP = 10000  then  P = '(MAC Roman ) 10000:'
         otherwise               P = right( CP, 18 ) || ':'
      end
      say P DEBUG( CP )
   end W
   exit 0

DEBUG:   procedure
   do N = 0 to 255                  /* check 256 local characters */
      C = centre( d2c( N ), 3 )     ;  U = UTF.O( C, arg( 1 ))
      if UTF.I( U ) == C then iterate N
      say 'error at' N              ;  trace ?R
      U = UTF.O( C )                ;  call UTF.I U
      say result == C               ;  return 'fail'
   end N

   U = 128                          /* find 128 UTF-8 characters: */
   do N = U to 65535 until U = 256
      B = reverse( x2b( d2x( N )))  ;  C = ''

      do L = 2 until verify( substr( B, 8 - L ), 0 ) = 0
         C = C || left( B, 6, 0 ) || 01
         B = substr( B, 7 )
      end L

      B = C || left( B, 8 - L, 0 ) || copies( 1, L )
      C = x2c( b2x( reverse( B )))
      U = U + ( UTF.I( C ) <> UTF.? )
   end N                            /* test error character UTF.? */

   N = 'found' U 'of 256 SBCS characters up to u+' || d2x( N, 4 )
   if U = 256  then  return 'okay,' N
               else  return 'fail,' N

/* -------------------------------------------------------------- */
/* <URL:http://purl.net/xyzzy/src/utf-8.cmd> 1.0, (c) F.Ellermann */

UTF.I:   procedure expose UTF.      /* UTF-8 to local charset     */
   parse arg SRC  ;  DST = ''       ;  UTF.8 = UTF.8( arg( 2 ))

   do while SRC <> ''
      POS = verify( SRC, UTF.8 ) -1 ;  if POS < 0 then leave
      DST = DST || left( SRC, POS ) ;  SRC = substr( SRC, POS + 1 )
      POS = verify( x2b( c2x( left( SRC, 1 ))), 1 ) -1

      if POS > 1 & POS < 7 then  do /* C0..FD introduce 2-6 bytes */
         TOP = left( SRC, POS )     ;  SRC = substr( SRC, POS + 1 )
         DST = DST || UTF.TOP       /* surrogates implicitly bad, */
      end                           /* C0..C1 are implicitly bad, */
      else  do                      /* 80..BF and FE..FF illegal: */
         DST = DST || UTF.?         ;  SRC = substr( SRC, 2 )
      end                           /* show error character UTF.? */
   end
   return DST || SRC

UTF.O:   procedure expose UTF.      /* local charset to UTF-8     */
   parse arg SRC  ;  DST = ''       ;  UTF.8 = UTF.8( arg( 2 ))

   do while SRC <> ''
      POS = verify( SRC, UTF.8 ) -1 ;  if POS < 0 then leave
      DST = DST || left( SRC, POS ) ;  SRC = substr( SRC, POS + 1 )
      parse var SRC TOP 2 SRC       ;  DST = DST || UTF.TOP
   end
   return DST || SRC

UTF.8:   procedure expose UTF.      /* initialize Unicode table   */
   arg PAGE
   select
      when  PAGE = value( 'UTF..' )                then  nop
      when  PAGE = '' & symbol( 'UTF..' ) = 'VAR'  then  nop
   otherwise
      if symbol( 'UTF.?' ) = 'VAR'  then  T = UTF.?
                                    else  T = x2c( 1A )
      drop UTF.      ;  UTF. = T    /* SUB unknown char.s by 0x1A */
      UTF.. = PAGE   ;  T = ''      /* note actual codepage UTF.. */
      select                        /* -------------------------- */
         when  PAGE =  437 then  do                /*  US OEM DOS */
            T = T '  C7   FC   E9   E2   E4   E0   E5   E7' /* 80 */
            T = T '  EA   EB   E8   EF   EE   EC   C4   C5' /* 88 */
            T = T '  C9   E6   C6   F4   F6   F2   FB   F9' /* 90 */
            T = T '  FF   D6   DC   A2   A3   A5 20A7  192' /* 98 */
            T = T '  E1   ED   F3   FA   F1   D1   AA   BA' /* A0 */
            T = T '  BF 2310   AC   BD   BC   A1   AB   BB' /* A8 */
            T = T '2591 2592 2593 2502 2524 2561 2562 2556' /* B0 */
            T = T '2555 2563 2551 2557 255D 255C 255B 2510' /* B8 */
            T = T '2514 2534 252C 251C 2500 253C 255E 255F' /* C0 */
            T = T '255A 2554 2569 2566 2560 2550 256C 2567' /* C8 */
            T = T '2568 2564 2565 2559 2558 2552 2553 256B' /* D0 */
            T = T '256A 2518 250C 2588 2584 258C 2590 2580' /* D8 */
            T = T ' 3B1   DF  393  3C0  3A3  3C3   B5  3C4' /* E0 */
            T = T ' 3A6  398  3A9  3B4 221E  3C6  3B5 2229' /* E8 */
            T = T '2261   B1 2265 2264 2320 2321   F7 2248' /* F0 */
            T = T '  B0 2219   B7 221A 207F   B2 25A0   A0' /* F8 */
         end                        /* -------------------------- */
         when  PAGE =  858 | PAGE = 850   then do  /* western DOS */
            T = T '  C7   FC   E9   E2   E4   E0   E5   E7' /* 80 */
            T = T '  EA   EB   E8   EF   EE   EC   C4   C5' /* 88 */
            T = T '  C9   E6   C6   F4   F6   F2   FB   F9' /* 90 */
            T = T '  FF   D6   DC   F8   A3   D8   D7  192' /* 98 */
            T = T '  E1   ED   F3   FA   F1   D1   AA   BA' /* A0 */
            T = T '  BF   AE   AC   BD   BC   A1   AB   BB' /* A8 */
            T = T '2591 2592 2593 2502 2524   C1   C2   C0' /* B0 */
            T = T '  A9 2563 2551 2557 255D   A2   A5 2510' /* B8 */
            T = T '2514 2534 252C 251C 2500 253C   E3   C3' /* C0 */
            T = T '255A 2554 2569 2566 2560 2550 256C   A4' /* C8 */
            T = T '  F0   D0   CA   CB   C8 20AC   CD   CE' /* D0 */
            T = T '  CF 2518 250C 2588 2584   A6   CC 2580' /* D8 */
            T = T '  D3   DF   D4   D2   F5   D5   B5   FE' /* E0 */
            T = T '  DE   DA   DB   D9   FD   DD   AF   B4' /* E8 */
            T = T '  AD   B1 2017   BE   B6   A7   F7   B8' /* F0 */
            T = T '  B0   A8   B7   B9   B3   B2 25A0   A0' /* F8 */
            /* 0xD5 850: u+0131 small dotless i, 858: u+20AC Euro */
         end                        /* -------------------------- */
         when  PAGE =  819 | PAGE = 28591 then  do /* ISO 8859-1  */
            do N = 128 to 255 ;  T = T d2x( N ) ;  end N /* 80-FF */
         end                        /* -------------------------- */
         when  PAGE =  923 | PAGE = 28605 then  do /* ISO 8859-15 */
            do N = 128 to 159 ;  T = T d2x( N ) ;  end N /* 80-9F */
            T = T '  A0   A1   A2   A3 20AC   A5  160   A7' /* A0 */
            T = T ' 161   A9   AA   AB   AC   AD   AE   AF' /* A8 */
            T = T '  B0   B1   B2   B3  17D   B5   B6   B7' /* B0 */
            T = T ' 17E   B9   BA   BB  152  153  178   BF' /* B8 */
            do N = 192 to 255 ;  T = T d2x( N ) ;  end N /* C0-FF */
         end                        /* -------------------------- */
         when  PAGE = 1252 | PAGE = 1004  then  do /* OEM Latin-1 */
            T = T '20AC   81 201A  192 201E 2026 2020 2021' /* 80 */
            T = T ' 2C6 2030  160 2039  152   8D  17D   8F' /* 88 */
            T = T '  90 2018 2019 201C 201D 2022 2013 2014' /* 90 */
            T = T ' 2DC 2122  161 203A  153   9D  17E  17F' /* 98 */
            do N = 160 to 255 ;  T = T d2x( N ) ;  end N /* A0-FF */
         end                        /* -------------------------- */
         when  PAGE =  878 then  do /* KOI8-R (ibm-878)           */
            T = T '2500 2502 250C 2510 2514 2518 251C 2524' /* 80 */
            T = T '252C 2534 253C 2580 2584 2588 258C 2590' /* 88 */
            T = T '2591 2592 2593 2320 25A0 2219 221A 2248' /* 90 */
            T = T '2264 2265   A0 2321   B0   B2   B7   F7' /* 98 */
            T = T '2550 2551 2552  451 2553 2554 2555 2556' /* A0 */
            T = T '2557 2558 2559 255A 255B 255C 255D 255E' /* A8 */
            T = T '255F 2560 2561  401 2562 2563 2564 2565' /* B0 */
            T = T '2566 2567 2568 2569 256A 256B 256C   A9' /* B8 */
            T = T ' 44E  430  431  446  434  435  444  433' /* C0 */
            T = T ' 445  438  439  43A  43B  43C  43D  43E' /* C8 */
            T = T ' 43F  44F  440  441  442  443  436  432' /* D0 */
            T = T ' 44C  44B  437  448  44D  449  447  44A' /* D8 */
            T = T ' 42E  410  411  426  414  415  424  413' /* E0 */
            T = T ' 425  418  419  41A  41B  41C  41D  41E' /* E8 */
            T = T ' 41F  42F  420  421  422  423  416  412' /* F0 */
            T = T ' 42C  42B  417  428  42D  429  427  42A' /* F8 */
         end                        /* -------------------------- */
         when PAGE = '10000'  then  do   /* MAC Roman             */
            T = T '  C4   C5   C7   C9   D1   D6   DC   E1' /* 80 */
            T = T '  E0   E2   E4   E3   E5   E7   E9   E8' /* 88 */
            T = T '  EA   EB   ED   EC   EE   EF   F1   F3' /* 90 */
            T = T '  F2   F4   F6   F5   FA   F9   FB   FC' /* 98 */
            T = T '2020   B0   A2   A3   A7 2022   B6   DF' /* A0 */
            T = T '  AE   A9 2122   B4   A8 2260   C6   D8' /* A8 */
            T = T '221E   B1 2264 2265   A5   B5 2202 2211' /* B0 */
            T = T '220F  3C0 222B   AA   BA  3A9   E6   F8' /* B8 */
            T = T '  BF   A1   AC 221A  192 2248 2206   AB' /* C0 */
            T = T '  BB 2026   A0   C0   C3   D5  152  153' /* C8 */
            T = T '2013 2014 201C 201D 2018 2019   F7 25CA' /* D0 */
            T = T '  FF  178 2044 20AC 2039 203A FB01 FB02' /* D8 */
            T = T '2021   B7 201A 201E 2030   C2   CA   C1' /* E0 */
            T = T '  CB   C8   CD   CE   CF   CC   D3   D4' /* E8 */
            T = T 'F8FF   D2   DA   DB   D9  131  2C6  2DC' /* F0 */
            T = T '  AF  2D8  2D9  2DA   B8  2DD  2DB  2C7' /* F8 */
            /* 0xBD old u+2126 Ohm             : new u+03A9 Omega */
            /* 0xDB old u+00A4 currency symbol : new u+20AC Euro  */
            /* 0xF0 old u+2665 black heart suit: new u+F8FF priv. */
         end                        /* -------------------------- */
         otherwise   exit ERROR( 'unsupported code page' PAGE )
      end

      do N = 128 to 255             /* table of UTF-8 characters: */
         parse var T SRC T ;  DST = ''
         SRC = reverse( x2b( SRC )) /* scalar bits right to left  */

         do LEN = 2 until verify( substr( SRC, 8 - LEN ), 0 ) = 0
            DST = DST || left( SRC, 6, 0 ) || '01'
            SRC = substr( SRC, 7 )  /* encoded 6 bits of scalar   */
         end LEN                    /* remaining bits of scalar:  */
         DST = DST || left( SRC, 7 - LEN, 0 ) || 0
         DST = x2c( b2x( reverse( DST || copies( 1, LEN ))))

         SRC = d2c( N )             /* SRC: 1 byte (local char.)  */
         UTF.DST = SRC              /* DST: 2 or more UTF-8 bytes */
         UTF.SRC = DST              /* excluding us-ascii 0..127  */
      end N
   end
   return xrange( x2c( 0 ), x2c( 7F ))

/* ----------------------------- (REXX ERROR template 2015-11-28) */
/* ERROR() shows an error message and the source line number sigl */
/* on stderr.  Examples:   if 0 = 1 then  exit ERROR( 'oops' )    */
/*                         call ERROR 'interactive debug here'    */

/* ERROR() can also catch exceptions (REXX conditions), examples: */
/* SIGNAL ON ERROR               non-zero rc or unhandled FAILURE */
/* SIGNAL ON NOVALUE NAME ERROR  uninitialized variable           */
/* CALL ON NOTREADY NAME ERROR   blocked I/O (incl. EOF on input) */

/* ERROR returns 1 for ordinary calls and CALL ON conditions, for */
/* SIGNAL ON conditions ERROR exits with rc 1.                    */

ERROR:
   ERROR.3 = trace( 'o' )        /* disable any trace temporarily */
   parse version ERROR.1 ERROR.2 ERROR.3
   select                        /* unify stderr output kludges   */
      when  abbrev( ERROR.1, 'REXX' ) = 0 then  ERROR.1 = ''
      when  ERROR.1 == 'REXXSAA'          then  ERROR.1 = 'STDERR:'
      when  ERROR.2 == 5.00               then  ERROR.1 = '<STDERR>'
      when  6 <= ERROR.2 & ERROR.2 < 7    then  ERROR.1 = 'STDERR:'
      otherwise                                 ERROR.1 = '/dev/con'
   end
   ERROR.3 = lineout( ERROR.1, '' )
   ERROR.3 = right( sigl '*-*', 10 )
   if sigl <= sourceline()       /* show source line if possible  */
      then  ERROR.3 = ERROR.3 strip( sourceline( sigl ))
      else  ERROR.3 = ERROR.3 '(source line unavailable)'
   ERROR.3 = lineout( ERROR.1, ERROR.3 )
   ERROR.3 = right( '+++', 10 ) condition( 'c' ) condition( 'd' )
   if condition() = ''  then  ERROR.3 = right( '>>>', 10 ) arg( 1 )
   ERROR.3 = lineout( ERROR.1, ERROR.3 )
   select
      when  sign( wordpos( condition( 'c' ), 'ERROR FAILURE' ))
      then  ERROR.3 = 'RC' rc
      when  condition( 'c' ) = 'SYNTAX'
      then  ERROR.3 = errortext( rc )
      when  condition( 'c' ) = 'HALT'
      then  ERROR.3 = errortext( 4 )
      when  condition( 'c' ) = 'NOTREADY' then  do
         ERROR.3 = condition( 'd' )
         if ERROR.3 <> ''  then  do
            ERROR.3 = stream( ERROR.3, 'd' )
         end
      end
      otherwise   ERROR.3 = ''
   end
   if ERROR.3 <> ''  then  do
      ERROR.3 = lineout( ERROR.1, right( '>>>', 10 ) ERROR.3 )
   end
   trace ?L                      ;  ERROR:
   if condition() <> 'SIGNAL'
      then  return 1             ;  else  exit 1

