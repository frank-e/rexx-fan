/* OS/2 REXX or NT ooREXX:  check some UCS transformation formats */

/* Magic numbers  :                                               */
/*       56613888 :  CP = 1024 * c2d( HI ) + c2d( LO ) - 56613888 */
/*        1114111 :  u+10FFFF, last code point in plane 16        */
/*         233006 :  u+038E2E, first UTF-1 using five octets      */
/*         187660 :  BOCU-1 difference with three trailing octets */
/*          65533 :  u+FFFD, replacement char. for input error    */
/*          55296 :  u+D800, 1st UTF-16 high (leading) surrogate  */
/*          56320 :  u+DC00, 1st UTF-16 low (trailing) surrogate  */
/*          16406 :  u+4016, 1st UTF-1 using three octets         */
/*          10513 :  BOCU-1 difference with two trailing octets   */
/*           1024 :  2 ** 10 high/low surrogates (2 ** 20 pairs)  */
/*            243 :  base for trailing BOCU-1 octets (0..3)       */
/*            190 :  base for trailing UTF-1  octets (0..2, or 4) */
/*             64 :  base for trailing UTF-8  octets (0..3)       */
/*             16 :  base for trailing UTF-4  octets (0..6)       */

/* UTF procedures :                                               */
/* UTF.8I, UTF.8O :  UTF-8  string to UTF-16BE, or vice versa     */
/* UTF.7I, UTF.7O :  UTF-7  string to UTF-16BE, or vice versa     */
/* UTF.4I, UTF.4O :  UTF-4  string to UTF-16BE, or vice versa     */
/* UTF.1I, UTF.1O :  UTF-1  string to UTF-16BE, or vice versa     */
/* BOCU.I, BOCU.O :  BOCU-1 string to UTF-16BE, or vice versa     */
/*         BOCU.5 :  BOCU-1 helper (specified rules 5a, 5b, 5c)   */
/*         UTF.32 :  Internal UTF-32BE to UTF-16BE conversion     */

/* Test procedures:                                               */
/* UCS.4          :  Check UCS-4 code points (17 * 65536 - 2048)  */
/* Legacy         :  Check code pages 819, 858, 923, 1252, etc.   */
/* STIR           :  Used to determine average BOCU-1 compression */
/* CHECK          :  Check S = decode( encode( S )), show results */

   signal on novalue
   TEST.    = 0                  ;  TEST.0.1 = 'UTF-16  '
   TEST.0.2 = 'UTF-8   '         ;  TEST.0.3 = 'UTF-7   '
   TEST.0.4 = 'UTF-4   '         ;  TEST.0.5 = 'UTF-1   '
   TEST.0.6 = 'BOCU-1  '         ;  TEST.0.7 = 'reserved'

   if 1  then  call UCS.4        /* code points, excl. surrogates */
   if 0  then  call LEGACY       /* codepage 437, 858, 1252, etc. */
   if symbol( 'RESULT' ) = 'LIT' then  say 'edit "if 0" for a test'

   exit 0

UCS.4:   procedure expose TEST.  /* test 2**21 -2048 code points, */
   N = 0                         /* CAVEAT, this takes some time: */
   if arg( 1, 'e' )  then  do ;  N = arg( 1 )   ;  trace ?R ;  end
   do N = N to x2d( '10FFFF' )
      if x2d( 'D800' ) <= N & N < x2d( 'E000' ) then  iterate N
      if N <= x2d( 'FFFF' )
        then  SRC = x2c( d2x( N, 4 ))
        else  SRC = UTF.32( x2c( d2x( N, 8 )))
      TEST.1.1 = TEST.1.1 + length( SRC )

      DST = UTF.8O( SRC )  ;  if SRC <> UTF.8I( DST ) then  leave N
      TEST.1.2 = TEST.1.2 + length( DST )

      DST = UTF.7O( SRC )  ;  if SRC <> UTF.7I( DST ) then  leave N
      TEST.1.3 = TEST.1.3 + length( DST )

      DST = UTF.4O( SRC )  ;  if SRC <> UTF.4I( DST ) then  leave N
      TEST.1.4 = TEST.1.4 + length( DST )

      DST = UTF.1O( SRC )  ;  if SRC <> UTF.1I( DST ) then  leave N
      TEST.1.5 = TEST.1.5 + length( DST )

      DST = BOCU.O( SRC )  ;  if SRC <> BOCU.I( DST ) then  leave N
      TEST.1.6 = TEST.1.6 + length( DST )

      call charout 'stderr', d2c( 13 ) || N || d2c( 13 )
   end N
   if N = x2d( '110000' )  then  do N = 1 to 6
      say TEST.0.N right( TEST.1.N, 10 )
   end
   else  say ' FAIL u+' || right( d2x( N     ), 6, 0 )
   return 0

LEGACY:  procedure expose TEST.  /* test various legacy codepages */
   S.0  = 0020 ;  E.0  = 007E    ;  S.1  = 00A0 ;  E.1  = 0113
   S.2  = 0116 ;  E.2  = 012B    ;  S.3  = 012E ;  E.3  = 014D
   S.4  = 0150 ;  E.4  = 017E    ;  S.5  = 02C7 ;  E.5  = 02C7
   S.6  = 02D8 ;  E.6  = 02DB    ;  S.7  = 02DD ;  E.7  = 02DD
   S.8  = 2015 ;  E.8  = 2015    ;  S.9  = 2018 ;  E.9  = 2019
   S.10 = 201C ;  E.10 = 201D    ;  S.11 = 20AC ;  E.11 = 20AC
   S.12 = 2122 ;  E.12 = 2122    ;  S.13 = 2126 ;  E.13 = 2126
   S.14 = 215B ;  E.14 = 215E    ;  S.15 = 2190 ;  E.15 = 2193
   S.16 = 266A ;  E.16 = 266A    ;  MES  = ''
   SUM. = 0
   do N = 0 to 16
      do U = x2d( S.N ) to x2d( E.N )
         MES = MES || x2c( d2x( U, 4 ))
         SUM.0 = SUM.0 + 1
      end U
   end N

   BOM = 'FEFF'x                 ;  TEST.2.0 = 'MES-1'
   SRC = BOM || MES              ;  TEST.2.1 = length( SRC )
   SUM.1 = TEST.2.1              ;  TEST.1.1 = left( SRC, 2 )
   if CHECK( 2, 1, SRC, /* == */ SRC ) then  exit 1

   DST = UTF.8O( SRC )           ;  TEST.2.2 = length( DST )
   SUM.2 = TEST.2.2              ;  TEST.1.2 = left( DST, 3 )
   if CHECK( 2, 2, SRC, UTF.8I( DST )) then  exit 1

   DST = UTF.7O( SRC )           ;  TEST.2.3 = length( DST )
   SUM.3 = TEST.2.3              ;  TEST.1.3 = left( DST, 4 )
   if CHECK( 2, 3, SRC, UTF.7I( DST )) then  exit 1

   DST = UTF.4O( SRC )           ;  TEST.2.4 = length( DST )
   SUM.4 = TEST.2.4              ;  TEST.1.4 = left( DST, 5 )
   if CHECK( 2, 4, SRC, UTF.4I( DST )) then  exit 1

   DST = UTF.1O( SRC )           ;  TEST.2.5 = length( DST )
   SUM.5 = TEST.2.5              ;  TEST.1.5 = left( DST, 3 )
   if CHECK( 2, 5, SRC, UTF.1I( DST )) then  exit 1

   AVG  = 0
   do N = 1 to SUM.0             /* ----------------------------- */
      call charout 'stderr', 'BOCU-1' N || d2c( 13 )
      SRC = BOM || STIR( MES, N )
      DST = BOCU.O( SRC )
      if SRC == BOCU.I( DST )
         then  AVG = AVG + length( DST )
         else  exit CHECK( 2, 6, SRC, BOCU.I( DST ))
   end N
   TEST.2.6 = format( AVG / N,, 0 )
   TEST.1.6 = left( DST, 3 )     ;  SUM.6 = TEST.2.6
   call CHECK 2, 6               /* ----------------------------- */

   TEST = 'n/a n/a 437 819 858 923 1252 1257 10000'
   do CASE = 3 to words( TEST )
      PAGE = word( TEST, CASE )  ;  TEST.CASE.0 = PAGE
      SRC  = ''                  ;  T = ''
      say                        ;  call CHECK CASE, 0
      do N = 0 to 127   ;  SRC = SRC || x2c( d2x( N, 4 ))   ;  end N
      select
         when  PAGE =  819 | PAGE = 28591 then  do /* ISO Latin 1 */
            do N = 128 to 255 ;  T = T d2x( N ) ;  end N /* 80-FF */
         end                        /* -------------------------- */
         when  PAGE =  923 | PAGE = 28605 then  do /* ISO Latin 9 */
            do N = 128 to 159 ;  T = T d2x( N ) ;  end N /* 80-9F */
            T = T '  A0   A1   A2   A3 20AC   A5  160   A7' /* A0 */
            T = T ' 161   A9   AA   AB   AC   AD   AE   AF' /* A8 */
            T = T '  B0   B1   B2   B3  17D   B5   B6   B7' /* B0 */
            T = T ' 17E   B9   BA   BB  152  153  178   BF' /* B8 */
            do N = 192 to 255 ;  T = T d2x( N ) ;  end N /* C0-FF */
         end                        /* -------------------------- */
         when  PAGE = 1252 then  do /* windows variant of Latin-1 */
            T = T '20AC   81 201A  192 201E 2026 2020 2021' /* 80 */
            T = T ' 2C6 2030  160 2039  152   86  17D   88' /* 88 */
            T = T '  90 2018 2019 201C 201D 2022 2013 2014' /* 90 */
            T = T ' 2DC 2122  161 203A  153   96  17E  17F' /* 98 */
            do N = 160 to 255 ;  T = T d2x( N ) ;  end N /* A0-FF */
         end                        /* -------------------------- */
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
         when  PAGE =  858 then  do /* PC-multilingual-850+euro   */
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
         when  PAGE = 1257 then  do /* windows variant of Latin-4 */
            T = T '20AC   81 201A   83 201E 2026 2020 2021' /* 80 */
            T = T '  88 2030   8A 2039   8C   A8  2C7   B8' /* 88 */
            T = T '  90 2018 2019 201C 201D 2022 2013 2014' /* 90 */
            T = T '  98 2122   9A 203A   9C   AF  2DB   9F' /* 98 */
            T = T '  A0   A1   A2   A3   A4   A5   A6   A7' /* A0 */
            T = T '  D8   A9  156   AB   AC   AD   AE   C6' /* A8 */
            T = T '  B0   B1   B2   B3   B4   B5   B6   B7' /* B0 */
            T = T '  F8   B9  157   BB   BC   BD   BE   E6' /* B8 */
            T = T ' 104  12E  100  106   C4   C5  118  112' /* C0 */
            T = T ' 10C   C9  179  116  122  136  12A  13B' /* C8 */
            T = T ' 160  143  145   D3  14C   D5   D6   D7' /* D0 */
            T = T ' 172  141  15A  16A   DC  17B  17D   DF' /* D8 */
            T = T ' 105  12F  101  107   E4   E5  119  113' /* E0 */
            T = T ' 10D   E9  17A  117  123  137  12B  13C' /* E8 */
            T = T ' 161  144  146   F3  14D   F5   F6   F7' /* F0 */
            T = T ' 173  142  15B  16B   FC  17C  17E  2D9' /* F8 */
         end                        /* -------------------------- */
         when PAGE = 10000 then  do /* Mac Roman (Euro version)   */
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
      end                        /* otherwise raise REXX error 40 */

      LEN = words( T )           ;  AVG = 0
      do N = 1 to LEN
         SRC = SRC || x2c( right( word( T, N ), 4, 0 ))
      end N

      SUM.0 = SUM.0 + LEN        ;  TEST.CASE.1 = length( SRC )
      if CHECK( CASE, 1, SRC, /* == */ SRC ) then  exit 1
      SUM.1 = SUM.1 + TEST.CASE.1

      DST = UTF.8O( SRC )        ;  TEST.CASE.2 = length( DST )
      if CHECK( CASE, 2, SRC, UTF.8I( DST )) then  exit 1
      SUM.2 = SUM.2 + TEST.CASE.2

      DST = UTF.7O( SRC )        ;  TEST.CASE.3 = length( DST )
      if CHECK( CASE, 3, SRC, UTF.7I( DST )) then  exit 1
      SUM.3 = SUM.3 + TEST.CASE.3

      DST = UTF.4O( SRC )        ;  TEST.CASE.4 = length( DST )
      if CHECK( CASE, 4, SRC, UTF.4I( DST )) then  exit 1
      SUM.4 = SUM.4 + TEST.CASE.4

      DST = UTF.1O( SRC )        ;  TEST.CASE.5 = length( DST )
      if CHECK( CASE, 5, SRC, UTF.1I( DST )) then  exit 1
      SUM.5 = SUM.5 + TEST.CASE.5

      do N = 1 to LEN            /* ----------------------------- */
         call charout 'stderr', 'BOCU-1' N || d2c( 13 )
         MIX = STIR( SRC, N )
         DST = BOCU.O( MIX )
         if MIX == BOCU.I( DST )
            then  AVG = AVG + length( DST )
            else  exit CHECK( CASE, 6, MIX, BOCU.I( DST ))
      end N
      TEST.CASE.6 = format( AVG / LEN,, 0 )
      call CHECK CASE, 6         ;  SUM.6 = SUM.6 + TEST.CASE.6
   end CASE                      /* ----------------------------- */

   L = words( TEST ) - 2         ;  say
   do N = 0 to 6
      if N = 0 then  TEST...N = 'average'
               else  TEST...N = format( SUM.N / L,, 0 )
      call CHECK ., N
   end
   return 0

STIR:    procedure               /* stir SRC sequence for BOCU-1: */
   parse arg SRC, GAP
   POS = 2 * ( length( SRC ) / 2 - GAP )
   DST = ''                      /* move n-th character from SRC  */
   do N = 1 while SRC <> ''      /* to DST for BOCU-1 comparison  */
      POS = ( POS + 2 * GAP ) // length( SRC )
      DST = DST || substr( SRC, POS + 1, 2 )
      SRC = left( SRC, POS ) || substr( SRC, POS + 3 )
   end N
   return DST

CHECK:   procedure expose TEST.  /* progress (or error) indicator */
   parse arg CASE, N, WANT, GOT
   if N > 0 then  LINE = TEST.0.N left( c2x( TEST.1.N ), 10 )
            else  LINE = right( 'codepage:', 19 )

   if GOT == WANT then  do
      do L = 2 to 9
         if TEST.L.N <> 0  then  LINE = LINE right( TEST.L.N, 5 )
      end L
      if TEST...N <> 0  then  LINE = LINE right( TEST...N, 9 )
      say LINE                   ;  return 0
   end
   else  do
      LINE = LINE 'error in case' CASE
      do L = 1 to length( WANT ) by 4
         if substr( WANT, L, 4 ) \== substr( GOT, L, 4 ) then  do
            LINE = LINE 'wanted' c2x( substr( WANT, L, 4 ))
            LINE = LINE 'but got' c2x( substr( GOT, L, 4 ))
            leave L
         end
      end L
      say LINE                   ;  return 1
   end

UTF.8I:  procedure               /* UTF-8 via UTF-4 to UTF-16BE   */
   parse arg SRC                 ;  DST = ''

   do while sign( length( SRC ))
      POS = verify( SRC, xrange( '00'x, '7F'x )) - 1
      if POS < 0  then  leave    ;  DST = DST || left( SRC, POS )
      SRC = substr( SRC, POS + 1 )
      parse var SRC TOP 2 SRC    ;  LOS = length( SRC )
      TMP = left( c2x( left( SRC, 1 )), 1 )

      if       TOP < 'C0'x | LOS = 0   then  LEN = -0
      else  if TOP < 'C2'x             then  LEN = -1
      else  if TOP < 'E0'x             then  LEN = +1
      else  if TOP = 'E0'x & TMP = '8' then  LEN = -2
      else  if TOP = 'E0'x & TMP = '9' then  LEN = -2
      else  if TOP = 'ED'x & TMP = 'A' then  LEN = -2
      else  if TOP = 'ED'x & TMP = 'B' then  LEN = -2
      else  if TOP < 'F0'x             then  LEN = +2
      else  if TOP = 'F0'x & TMP = '8' then  LEN = -3
      else  if TOP < 'F4'x             then  LEN = +3
      else  if TOP = 'F4'x & TMP = '8' then  LEN = +3
      else  if TOP < 'F8'x             then  LEN = -3
      else  if TOP < 'FC'x             then  LEN = -4
      else  if TOP < 'FE'x             then  LEN = -5
      else                                   LEN = -0

      BAD = ( LEN <= 0 )         ;  LEN = abs( LEN )
      if LOS < LEN   then  do
         BAD = 1                 ;  LEN = LOS
      end
      CHR = left( SRC, LEN )     ;  SRC = substr( SRC, LEN + 1 )
      TMP = verify( CHR, xrange( '80'x, 'BF'x ))
      if TMP > 0     then  do
         BAD = 1                 ;  SRC = substr( CHR, TMP ) || SRC
      end
      if BAD = 0     then  do    /* convert valid UTF-8 to bits   */
         TOP = x2b( c2x( TOP ))  ;  LEN = verify( TOP, 1 ) - 2
         TOP = copies( 0, LEN ) || right( TOP, 6 - LEN )
         do L = 1 to LEN         /* determine 12, 18, or 24 bits: */
            parse var CHR TMP 2 CHR
            TOP = TOP || right( x2b( c2x( TMP )), 6 )
         end
         if LEN = 2              then  TOP = 00 || TOP
         if abbrev( TOP, 0000 )  then  TOP = substr( TOP, 5 )
         if abbrev( TOP, 0000 )  then  TOP = substr( TOP, 5 )
         LEN = length( TOP ) % 4
         if LEN > 2 | abbrev( TOP, 100 )  then  do
            DST = DST || x2c( 8 || LEN )
            do L = 1 to LEN      /* use pieces of four bits       */
               parse var TOP TMP 5 TOP
               DST = DST || x2c( 9 || b2x( TMP ))
            end
         end
         else  DST = DST || x2c( b2x( TOP ))
      end
      else  DST = DST || '849F9F9F9D'x
   end
   return UTF.4I( DST || SRC )

UTF.8O:  procedure               /* UTF-16BE to UTF-8 encoder     */
   parse arg SRC                 ;  DST = ''
   LOS = length( SRC )           ;  if LOS // 2 then  signal UTF.ERR

   do while LOS > 0
      parse var SRC CHR 3 SRC    ;  LOS = LOS - 2
      select
         when  CHR << '0080'x then  do
            DST = DST || right( CHR, 1 )
            iterate
         end
         when  CHR << 'D800'x then  CHR = c2d( CHR )
         when  CHR >> 'DFFF'x then  CHR = c2d( CHR )
         when  CHR >> 'DBFF'x then  CHR = 65533
         when  LOS = 0        then  CHR = 65533
      otherwise
         parse var SRC TMP 3 SRC ;  LOS = LOS - 2
         if TMP << 'DC00'x | 'DFFF'x << TMP  then  do
            SRC = TMP || SRC     ;  CHR = 65533
            LOS = LOS + 2        /* undo wrong trailing surrogate */
         end
         else  CHR = 1024 * c2d( CHR ) + c2d( TMP ) - 56613888
      end

      BIN = reverse( x2b( d2x( CHR )))
      CHR = ''
      do LEN = 2 until verify( substr( BIN, 8 - LEN ), 0 ) = 0
         CHR = CHR || left( BIN, 6, 0 ) || 01
         BIN = substr( BIN, 7 )
      end LEN

      BIN = CHR || left( BIN, 8 - LEN, 0 ) || copies( 1, LEN )
      DST = DST || x2c( b2x( reverse( BIN )))
   end
   return DST

UTF.7I:  procedure               /* UTF-7 via UTF-4 to UTF-16BE   */
   parse arg SRC                 ;  DST = ''
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = translate( B64 ) || B64 || '0123456789+/'

   do while sign( length( SRC ))
      POS = pos( '+', SRC ) - 1  ;  if POS < 0  then  leave
      DST = DST || left( SRC, POS )
      SRC = substr( SRC, POS + 2 )
      if abbrev( SRC, '-' )   then  do
         DST = DST || '+'        ;  SRC = substr( SRC, 2 )
         iterate                 /* decode '+-' as '+' = u+002B   */
      end
      LEN = verify( SRC || '-', B64 ) - 1
      if LEN = 0  then  do       /* '+' before non-B64 is invalid */
         DST = DST || '849F9F9F9D'x
         iterate
      end

      TOP = left( SRC, LEN )     ;  SRC = substr( SRC, LEN + 1 )
      if abbrev( SRC, '-' )   then  SRC = substr( SRC, 2 )
      U16 = ''                   ;  POS = ( LEN * 6 ) // 8
      do N = 1 to LEN            /* decode B64 chars.s after '+'  */
         HEX = d2x( pos( substr( TOP, N, 1 ), B64 ) - 1 )
         U16 = U16 || right( x2b( HEX ), 6, 0 )
      end N
      U16 = x2c( b2x( left( U16, LEN * 6 - POS )))
      LEN = length( U16 )
      if LEN // 2 | POS = 6   then  do
         if LEN // 2 then  U16 = left( U16, LEN - 1 )
         U16 = U16 || 'FFFD'x    /* odd length or invalid padding */
      end
      DST = DST || UTF.4O( U16 )
   end
   return UTF.4I( DST || SRC )

UTF.7O:  procedure               /* UTF-16BE to UTF-7 encoder     */
   parse arg SRC                 ;  DST = '' ;  U16 = ''
   LOS = length( SRC )           ;  if LOS // 2 then  signal UTF.ERR
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = translate( B64 ) || B64 || '0123456789+/'

   do while LOS > 0
      parse var SRC CHR 3 SRC    ;  LOS = LOS - 2
      select                     /* special cases '\', '~', etc.  */
         when  abbrev( CHR, '09'x ) then  nop
         when  abbrev( CHR, '20'x ) then  nop
         when  CHR == '0009'x       then  CHR = '09'x
         when  CHR == '000A'x       then  CHR = '0A'x
         when  CHR == '000D'x       then  CHR = '0D'x
         when  CHR << '0020'x       then  nop
         when  CHR == '005C'x       then  nop
         when  CHR << '007E'x       then  CHR = right( CHR, 1 )
         when  CHR << 'D800'x       then  nop
         when  CHR >> 'DFFF'x       then  nop
         when  CHR >> 'DBFF'x       then  CHR = 'FFFD'x
         when  LOS = 0              then  CHR = 'FFFD'x
      otherwise
         parse var SRC TMP 3 SRC ;  LOS = LOS - 2
         if TMP << 'DC00'x | 'DFFF'x << TMP  then  do
            SRC = TMP || SRC     ;  CHR = 'FFFD'x
            LOS = LOS + 2        /* undo wrong trailing surrogate */
         end
         else  do
            U16 = U16 || CHR     ;  CHR = TMP
         end
      end
      if length( CHR ) = 2 then  do
         U16 = U16 || CHR        ;  if SRC \== ''  then  iterate
         CHR = ''                /* abbrev( '-', CHR ) = 1 at end */
      end                        /* collect U16 until UTF-7 ASCII */

      if U16 \== ''  then  do    /* output U16 before UTF-7 ASCII */
         DST = DST || '+'        /* '+' (excl. '+-') starts a B64 */
         U16 = x2b( c2x( U16 ))  /* '-' or non-B64 terminates B64 */
         U16 = U16 || copies( '00', ( length( U16 ) % 4 ) // 3 )
         do while U16 <> ''
            parse var U16 TMP 7 U16
            DST = DST || substr( B64, x2d( b2x( TMP )) + 1, 1 )
         end                     /* add '-' also if next is a '-' */
         if sign( pos( CHR, B64 )) | abbrev( '-', CHR )
            then  DST = DST || '-'
      end
      if CHR = '+'   then  DST = DST || '+-'
                     else  DST = DST || CHR
   end
   return DST

UTF.4I:  procedure               /* UTF-4 to UTF-16BE decoder     */
   parse arg SRC                 ;  DST = ''

   do while sign( length( SRC ))
      parse var SRC TOP 2 SRC
      if TOP < '80'x | 'A0'x <= TOP then  do
         DST = DST || right( TOP, 2, '00'x )
         iterate
      end
      LEN = c2d( TOP ) - 128     /* check lead byte '82'x - '86'x */
      if LEN < 2 | 6 < LEN then  do
         DST = DST || 'FFFD'x    ;  iterate
      end

      TOP = left( SRC, LEN )     ;  SRC = substr( SRC, LEN + 1 )
      POS = verify( TOP, xrange( '90'x, '9F'x ))
      select
         when  POS > 0 | abbrev( TOP, '90'x )   then  do
            if POS > 0  then  SRC = substr( TOP, POS ) || SRC
            DST = DST || 'FFFD'x ;  iterate
         end                     /* found invalid UTF-4 tail byte */
         when  LEN = 3 | LEN = 5 then  TOP = '90'x || TOP
         when  LEN = 4 & TOP << '9D989090'x     then  nop
         when  LEN = 4 & TOP >> '9D9F9F9F'x     then  nop
         when  LEN = 2 & abbrev( TOP, '98'x )   then  nop
         when  LEN = 2 & abbrev( TOP, '99'x )   then  nop
         when  LEN = 6 & abbrev( TOP, '9190'x ) then  nop
         when  LEN = 2 | LEN = 4 | LEN = 6      then  do
            DST = DST || 'FFFD'x ;  iterate
         end                     /* reject invalid UTF-4 encoding */
      end                        /* no OTHERWISE, match all cases */

      LEN = LEN + LEN // 2       ;  HEX = ''
      do L = 1 to LEN            /* UTF-4 tail byte '9?'x to hex. */
         HEX = HEX || right( c2x( substr( TOP, L, 1 )), 1 )
      end
      select
         when  LEN = 2  then  DST = DST || '00'x || x2c( HEX )
         when  LEN = 4  then  do
            DST = DST || x2c(  left( HEX, 2 ))
            DST = DST || x2c( right( HEX, 2 ))
         end
         when  LEN = 6  then  do /* encode UTF-16 surrogate pair: */
            DEC = x2d( substr( HEX, 1, 2 )) - 1
            DEC = x2d( substr( HEX, 3, 2 )) + 256 * DEC
            DEC = x2d( substr( HEX, 5, 2 )) + 256 * DEC
            DST = DST || d2c( 55296 + DEC  % 1024 )
            DST = DST || d2c( 56320 + DEC // 1024 )
         end
      end
   end
   return DST

UTF.4O:  procedure               /* UTF-16BE to UTF-4 encoder     */
   parse arg SRC                 ;  DST = ''
   LOS = length( SRC )           ;  if LOS // 2 then  signal UTF.ERR

   do while LOS > 0
      parse var SRC CHR 3 SRC    ;  LOS = LOS - 2
      select
         when  CHR << '0080'x then  DST = DST || right( CHR, 1 )
         when  CHR << '00A0'x then  do
            CHR = c2x( right( CHR, 1 ))
            DST = DST || x2c( 82 )
            DST = DST || x2c( 9 ||  left( CHR, 1 ))
            DST = DST || x2c( 9 || right( CHR, 1 ))
         end
         when  CHR << '0100'x then  DST = DST || right( CHR, 1 )
         when  CHR << '1000'x then  do
            TOP = c2x(  left( CHR, 1 ))
            CHR = c2x( right( CHR, 1 ))
            DST = DST || x2c( 83 )
            DST = DST || x2c( 9 || right( TOP, 1 ))
            DST = DST || x2c( 9 ||  left( CHR, 1 ))
            DST = DST || x2c( 9 || right( CHR, 1 ))
         end
         when  CHR << 'D800'x | 'DFFF'x << CHR  then  do
            TOP = c2x(  left( CHR, 1 ))
            CHR = c2x( right( CHR, 1 ))
            DST = DST || x2c( 84 )
            DST = DST || x2c( 9 ||  left( TOP, 1 ))
            DST = DST || x2c( 9 || right( TOP, 1 ))
            DST = DST || x2c( 9 ||  left( CHR, 1 ))
            DST = DST || x2c( 9 || right( CHR, 1 ))
         end
         when  CHR >> 'DBFF'x then  DST = DST || '849F9F9F9D'x
         when  LOS = 0        then  DST = DST || '849F9F9F9D'x
      otherwise
         parse var SRC TMP 3 SRC ;  LOS = LOS - 2
         if TMP << 'DC00'x | 'DFFF'x << TMP  then  do
            SRC = TMP || SRC     ;  DST = DST || '849F9F9F9D'x
            LOS = LOS + 2        /* undo wrong trailing surrogate */
         end
         else  do
            CHR = 1024 * c2d( CHR ) + c2d( TMP ) - 56613888
            TOP = ''
            do until CHR = 0
               TMP = CHR // 16   ;  CHR = CHR % 16
               TOP = x2c( 9 || d2x( TMP )) || TOP
            end
            DST = DST || x2c( 8 || length( TOP )) || TOP
         end
      end
   end
   return DST

UTF.1I:  procedure               /* UTF-1 to UTF-16BE decoder     */
   parse arg SRC                 ;  DST = ''

   do while sign( length( SRC ))
      parse var SRC TOP 2 SRC
      select
         when  TOP > 'FB'x then  TOP = 4 233006 c2d( TOP ) - 252
         when  TOP > 'F5'x then  TOP = 2  16406 c2d( TOP ) - 246
         when  TOP > 'A0'x then  TOP = 1    256 c2d( TOP ) - 161
         when  TOP = 'A0'x then  TOP = 1     66 0
      otherwise
         DST = DST || right( TOP, 4, '00'x )
         iterate
      end

      parse var TOP T CHR TOP    ;  CHR = CHR + TOP * ( 190 ** T )
      do N = T - 1 to 0 by -1
         parse var SRC TOP 2 SRC ;  L = c2d( TOP )
         select                  /* accept trailing 21..7E/A0..FF */
            when  160 <= L             then  L = L - 66
            when   33 <= L & L < 127   then  L = L - 33
         otherwise               /* reject trailing 00..20/7F..9F */
            CHR = x2d( 'FFFD' )  ;  SRC = TOP || SRC
            leave N
         end
         CHR = CHR + L * ( 190 ** N )
      end N
      if 160 <= CHR & CHR <= 1114111
         then  DST = DST || x2c( d2x( CHR, 8 ))
         else  DST = DST || '0000FFFD'x
   end                           /* bad UTF-1 A021..A07E replaced */
   return UTF.32( DST )          /* UTF.32 handles any surrogates */

UTF.1O:  procedure               /* UTF-16BE to UTF-1 encoder     */
   parse arg SRC                 ;  DST = ''
   LOS = length( SRC )           ;  if LOS // 2 then  signal UTF.ERR

   do while LOS > 0
      parse var SRC CHR 3 SRC    ;  LOS = LOS - 2
      select
         when  CHR << '00A0'x then  do
            DST = DST || right( CHR, 1 )
            iterate
         end
         when  CHR << 'D800'x then  CHR = c2d( CHR )
         when  CHR >> 'DFFF'x then  CHR = c2d( CHR )
         when  CHR >> 'DBFF'x then  CHR = 65533
         when  SRC == ''      then  CHR = 65533
      otherwise
         parse var SRC TMP 3 SRC ;  LOS = LOS - 2
         if TMP << 'DC00'x | 'DFFF'x << TMP  then  do
            SRC = TMP || SRC     ;  CHR = 65533
            LOS = LOS + 2        /* undo wrong trailing surrogate */
         end
         else  CHR = 1024 * c2d( CHR ) + c2d( TMP ) - 56613888
      end

      select
         when  CHR <    256   then  TMP = ( CHR -     66 ) 160 1
         when  CHR <  16406   then  TMP = ( CHR -    256 ) 161 1
         when  CHR < 233006   then  TMP = ( CHR -  16406 ) 246 2
         otherwise                  TMP = ( CHR - 233006 ) 252 4
      end
      parse var TMP CHR L T
      DST = DST || d2c( L + CHR % ( 190 ** T ))

      do N = T - 1 to 0 by -1    /* trailing bytes 21..7E, A0..FF */
         L = ( CHR % ( 190 ** N )) // 190
         if L < 94   then  DST = DST || d2c( L + 33 )
                     else  DST = DST || d2c( L + 66 )
      end N
   end
   return DST

BOCU.I:  procedure               /* BOCU-1 to UTF-16BE decoder    */
   parse arg SRC                 ;  DST = ''
                                 ;  PREV = 64            /* (RD1) */

   do while sign( length( SRC ))
      parse var SRC TOP 2 SRC
      select                     /* single RD4 or multi-byte RD5: */
         when  TOP = 'FF'x | TOP << '21'x then  do       /* (RD2) */
            if TOP < 'FF'x then  DST = DST || right( TOP, 4, '00'x )
            if TOP \== ' ' then  PREV = 64               /* (RD3) */
            iterate              /* if 255 only reset state (RD6) */
         end
         when  TOP = 'FE'x then  N = +187660 3  254
         when  TOP > 'FA'x then  N =  +10513 2  251
         when  TOP > 'CF'x then  N =     +64 1  208
         when  TOP > '4F'x then  N =       0 0  144
         when  TOP > '24'x then  N =     -64 1   80
         when  TOP > '21'x then  N =  -10513 2   37
         when  TOP = '21'x then  N = -187660 3   34
      end
      parse var N DIFF T N       ;  TOP = c2d( TOP ) - N
      CHR = DIFF + PREV + TOP * ( 243 ** T )

      do N = 1 to T
         parse var SRC TOP 2 SRC ;  TOP = c2d( TOP )
         select
            when  33 <= TOP               then  TOP = TOP - 13
            when  28 <= TOP & TOP <= 31   then  TOP = TOP - 12
            when  16 <= TOP & TOP <= 25   then  TOP = TOP - 10
            when   1 <= TOP & TOP <=  6   then  TOP = TOP -  1
         otherwise
            CHR = c2d( 'FFFD'x ) ;  SRC = d2c( TOP ) || SRC
            leave N              /* restore any invalid tail byte */
         end
         CHR = CHR + TOP * ( 243 ** ( T - N ))
      end N

      PREV = BOCU.5( CHR )       ;  DST = DST || x2c( d2x( CHR, 8 ))
   end
   return UTF.32( DST )

BOCU.O:  procedure               /* UTF-16BE to BOCU-1 encoder    */
   parse arg SRC                 ;  DST = ''
   LOS = length( SRC )           ;  if LOS // 2 then  signal UTF.ERR
   PREV = 64                                                /* R1 */

   do while LOS > 0
      parse var SRC CHR 3 SRC    ;  LOS = LOS - 2
      select
         when  CHR << 'D800'x then  CHR = c2d( CHR )
         when  CHR >> 'DFFF'x then  CHR = c2d( CHR )
         when  CHR >> 'DBFF'x then  CHR = 65533
         when  LOS = 0        then  CHR = 65533
      otherwise
         parse var SRC TMP 3 SRC ;  LOS = LOS - 2
         if TMP << 'DC00'x | 'DFFF'x << TMP  then  do
            SRC = TMP || SRC     ;  CHR = 65533
            LOS = LOS + 2        /* undo wrong trailing surrogate */
         end
         else  CHR = 1024 * c2d( CHR ) + c2d( TMP ) - 56613888
      end

      if CHR <= 32   then  do    /* C0 control or space, R2 or R3 */
         if CHR < 32 then  PREV = 64                        /* R3 */
         DST = DST || d2c( CHR ) ;  iterate                 /* R2 */
      end
      DIFF = CHR - PREV          ;  PREV = BOCU.5( CHR ) /* R4,R5 */

      select                     /* R4.2 base LEAD bytes and R4.3 */
         when   187660 <= DIFF   then  N = 3 254 ( DIFF - 187660 )
         when    10513 <= DIFF   then  N = 2 251 ( DIFF -  10513 )
         when       64 <= DIFF   then  N = 1 208 ( DIFF -     64 )
         when      -64 <= DIFF   then  N = 0 144 ( DIFF -      0 )
         when   -10513 <= DIFF   then  N = 1  80 ( DIFF +     64 )
         when  -187660 <= DIFF   then  N = 2  37 ( DIFF +  10513 )
         otherwise                     N = 3  34 ( DIFF + 187660 )
      end                        /* UTF-16 abs( DIFF ) <= 1114111 */

      parse var N T LEAD DIFF    ;  TAIL = ''
      do N = 1 to T              /* determine trail bytes (R4.4): */
         M = DIFF // 243         ;  DIFF = DIFF % 243
         if M < 0 then  do       /* non-negative modulo   (R4.4a) */
            M = M + 243          ;  DIFF = DIFF - 1
         end
         select                  /* avoid 00, 07..0F, 1A..1B, 20: */
            when  M <=   5 then  TAIL = d2c( M +  1 ) || TAIL
            when  M <=  15 then  TAIL = d2c( M + 10 ) || TAIL
            when  M <=  19 then  TAIL = d2c( M + 12 ) || TAIL
            otherwise            TAIL = d2c( M + 13 ) || TAIL
         end
      end N

      DST = DST || d2c( LEAD + DIFF ) || TAIL   /* R4.5 and R4.6  */
   end
   return DST

BOCU.5:  procedure               /* middle of page or CJK range   */
   arg DEC
   select
      when  DEC < 12352 then  return 64 + DEC - DEC // 128
      when  DEC < 12448 then  return 12400      /* Hiragana (R5a) */
      when  DEC < 19968 then  return 64 + DEC - DEC // 128
      when  DEC < 40870 then  return 30481      /* Unihan   (R5b) */
      when  DEC < 44032 then  return 64 + DEC - DEC // 128
      when  DEC < 55204 then  return 49617      /* Hangul   (R5c) */
      otherwise               return 64 + DEC - DEC // 128
   end

UTF.32:  procedure               /* internal UTF-32BE to UTF-16BE */
   parse arg SRC                 ;  DST = ''
   do while sign( length( SRC )) /* internal use for good lengths */
      parse var SRC TOP 3 LOW 5 SRC
      select
         when  TOP == '0000'x & LOW << 'D800'x
         then  DST = DST || LOW
         when  TOP == '0000'x & LOW >> 'DFFF'x
         then  DST = DST || LOW
         when  TOP == '0000'x | TOP >> '0010'x
         then  DST = DST || 'FFFD'x
      otherwise                  /* encode UTF-16 surrogate pair: */
         DEC = c2d( right( TOP, 1 )) - 1
         DEC = c2d(  left( LOW, 1 )) + 256 * DEC
         DEC = c2d( right( LOW, 1 )) + 256 * DEC
         DST = DST || d2c( 55296 + DEC  % 1024 )
         DST = DST || d2c( 56320 + DEC // 1024 )
      end
   end
   return DST

UTF.ERR:                         /* odd number of octets is fatal */
   UTF.ERR = 'odd number of octets in UTF-16 string'
   parse version . !V! .
   if !V! < 6
      then  exit 22 + lineout( 'stderr:', UTF.ERR 'line' sigl )
      else  raise syntax 22 description ( UTF.ERR )

