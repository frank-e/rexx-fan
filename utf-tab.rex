/* OS/2 REXX: check various UCS transformation formats and BOCU-1 */

   signal on  novalue  name TRAP ;  signal on  syntax name TRAP
   signal on  failure  name TRAP ;  signal on  halt   name TRAP

   U.1  = x2d( 00007F )
   U.2  = x2d( 000080 )
   U.3  = x2d( 00009F )
   U.4  = x2d( 0000A0 )
   U.5  = x2d( 0000BF )
   U.6  = x2d( 0000C0 )
   U.7  = x2d( 0000FF )
   U.8  = x2d( 000100 )
   U.9  = x2d( 00015D )
   U.10 = x2d( 00015E )
   U.11 = x2d( 0001BD )
   U.12 = x2d( 0001BE )
   U.13 = x2d( 0007FF )
   U.14 = x2d( 000800 )
   U.15 = x2d( 000FFF )
   U.16 = x2d( 001000 )
   U.17 = x2d( 004015 )
   U.18 = x2d( 004016 )
   U.19 = x2d( 00D7FF )
   U.20 = x2d( 00E000 )
   U.21 = x2d( 00F8FF )
   U.22 = x2d( 00FDD0 )
   U.23 = x2d( 00FDEF )
   U.24 = x2d( 00FEFF )
   U.25 = x2d( 00FFFD )
   U.26 = x2d( 00FFFE )
   U.27 = x2d( 00FFFF )
   U.28 = x2d( 010000 )
   U.29 = x2d( 01FFFE )
   U.30 = x2d( 01FFFF )
   U.31 = x2d( 038E2D )
   U.32 = x2d( 038E2E )
   U.33 = x2d( 0F0000 )
   U.34 = x2d( 0FFFFE )
   U.35 = x2d( 0FFFFF )
   U.36 = x2d( 100000 )
   U.37 = x2d( 10FFFE )
   U.38 = x2d( 10FFFF )
   numeric digits 21
   U.39 = x2d( 110000 )
   U.40 = x2d( '7FFFFFFF' )
   U.41 = x2d( 'FFFFFFFF' )

   S = 'codepoint  UTF-16BE  UTF-16LE  UTF-8     UTF-4          '
   say S 'UTF-1'
   do N = 1 to 38
      S = ' '                    ;  if U.N = 65279 then S = '*'
      U = x2c( d2x( U.N, 8 ))    ;  S = S || UNIHEX( U.N ) ''
      X = UTF16O( U )            ;  Y = reverse( X )
      if length( X ) > 2
         then  Y = reverse( left( X, 2 )) || left( Y, 2 )
      S = S left( c2x( X ), 8 ) ''
      S = S left( c2x( Y ), 8 ) ''
      S = S left( c2x( UTF32I( U )),  8 ) ''
      S = S left( c2x( UTF4.O( U )), 14 ) ''
   /* S = S left( c2x( UTF7.O( U )), 16 ) */
      S = S left( c2x( UTF1.O( U )), 10 )
      say S
      if U.N = 55295 then say 'surrogates'
   end N
   say length( S )
   exit 0

UNIHEX:  procedure
   U = strip( d2x( arg( 1 )), 'L', 0 )
   return right( 'U+' || right( U, max( 4, length( U )), 0 ), 8 )

UTF32I:  procedure               /* UTF-32BE to UTF-8 encoder     */
   parse arg SRC                 ;  DST = ''

   do while 4 <= length( SRC )   /* split next UTF-32BE from SRC  */
      parse var SRC CHR 5 SRC    ;  CHR = c2d( CHR )

      if CHR <= 127  then  do
         DST = DST || d2c( CHR ) ;  iterate
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
   if sign( length( SRC )) then  DST = DST || SUB
   return DST

UTF32O:  procedure               /* UTF-8 to UTF-32BE decoder     */
   U.2 = xrange( x2c( '80' ), x2c( 'BF' ))
   SUB = x2c( '0000FFFD' )       ;  DST = ''
   parse arg SRC                 ;  LOS = length( SRC )

   do while LOS > 0
      parse var SRC LB 2 SRC     ;  LOS = LOS - 1
      LB = c2d( LB )             ;  TOP = 0

      if LB < 128 then  do
         DST = DST || x2c( d2x( LB, 8 ))  ;  iterate
      end

      if LOS > 0  then  TOP = c2d( left( SRC, 1 )) % 16
      select                     /* for CESU remove both LB = 237 */
         when  LB < 192             then  LEN = -0 /* trail bytes */
         when  LB < 194             then  LEN = -1 /* bad C0 + C1 */
         when  LB < 224             then  LEN = +1
         when  LB = 224 & TOP =  8  then  LEN = -2 /* E08x is bad */
         when  LB = 224 & TOP =  9  then  LEN = -2 /* E09x is bad */
         when  LB = 237 & TOP = 10  then  LEN = -2 /* EDAx is bad */
         when  LB = 237 & TOP = 11  then  LEN = -2 /* EDBx is bad */
         when  LB < 240             then  LEN = +2
         when  LB = 240 & TOP =  8  then  LEN = -3 /* F08x is bad */
         when  LB < 244             then  LEN = +3
         when  LB = 244 & TOP =  8  then  LEN = +3 /* F48x is ok. */
         when  LB < 248             then  LEN = -3 /* bad F4 - F7 */
         when  LB < 252             then  LEN = -4 /* bad F8 - FB */
         when  LB < 254             then  LEN = -5 /* bad FC + FD */
         otherwise                        LEN = -0 /* bad FE + FF */
      end

      BAD = ( LEN <= 0 )         ;  LEN = abs( LEN )
      if LOS < LEN   then  do
         BAD = 1                 ;  LEN = LOS
      end

      TOP = left( SRC, LEN )     ;  SRC = substr( SRC, LEN + 1 )
      TMP = verify( TOP, U.2 )   ;  LOS = LOS - LEN
      if TMP > 0  then  do       /* eat plausible trailing bytes: */
         BAD = 1                 ;  SRC = substr( TOP, TMP ) || SRC
         LOS = length( SRC )     /* but keep possible valid input */
      end                        /* bytes for the next iteration  */

      if BAD = 0  then  do       /* at this point input is valid: */
         LB  = x2b( d2x( LB ))   ;  LEN = verify( LB, 1 ) - 2
         LB  = copies( 0, LEN ) || right( LB, 6 - LEN )

         do until TOP == ''
            TMP = x2b( c2x( left( TOP, 1 )))
            LB  = LB || right( TMP, 6 )
            TOP = substr( TOP, 2 )
         end

         TOP = b2x( strip( LB, 'L', 0 ))
         DST = DST || x2c( right( TOP, 8, 0 ))
      end
      else  DST = DST || SUB
   end
   return DST

UTF16I:  procedure               /* UTF-16BE to UTF-32BE decoder  */
   parse arg SRC                 ;  LO = x2d( 'D800' )
   DST = ''                      ;  HI = x2d( 'DC00' )

   do while 2 <= length( SRC )   /* next UTF-16 or low surrogate  */
      parse var SRC L 3 SRC      ;  L = c2d( L )
      select
         when  LO     > L  then  DST = DST || x2c( d2x( L, 8 ))
         when  57344 <= L  then  DST = DST || x2c( d2x( L, 8 ))
         when  HI    <= L  then  DST = DST || x2c( '0000FFFD' )
         when  length( SRC ) < 2 then  SRC = '?'
         otherwise               /* length < 2: no high surrogate */
            L = L - LO + 64      ;  parse var SRC R 3 SRC
            R = c2d( R ) - HI
            if 0 <= R & R < 57344 - HI
               then  DST = DST || x2c( d2x( L * 1024 + R, 8 ))
               else  DST = DST || x2c( '0000FFFD' )
      end
   end
   if sign( length( SRC )) then  DST = DST || x2c( '0000FFFD' )
   return DST

UTF16O:  procedure               /* UTF-32BE to UTF-16BE encoder  */
   parse arg SRC                 ;  LO = x2d( 'D800' )
   DST = ''                      ;  HI = x2d( 'DC00' )

   do while 4 <= length( SRC )   /* split next UTF-32BE from SRC  */
      parse var SRC L 3 R 5 SRC  ;  L = c2d( L ) - 1

      if L < 0 | 15 < L then  do
         if 15 < L      then  R = x2c( 'FFFD' )
         DST = DST || R          ;  iterate
      end
      R = c2d( R )               ;  L = L * 64 + R % 1024
      R = R // 1024              ;  L = x2c( d2x( LO + L, 4 ))
      R = x2c( d2x( HI + R, 4 )) ;  DST = DST || L || R
   end
   if sign( length( SRC )) then  DST = DST || x2c( 'FFFD' )
   return DST

UTF7.I:  procedure               /* UTF-7 to UTF-32BE decoder     */
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = translate( B64 ) || B64 || '0123456789+/'
   parse arg SRC                 ;  DST = ''

   do while length( SRC ) > 0
      parse var SRC TOP 2 SRC
      if TOP <> '+'  then  do
         DST = DST || right( TOP, 4, x2c( 0 ))
         iterate
      end
      if abbrev( SRC, '-' )   then  do
         SRC = substr( SRC, 2 )  ;  DST = DST || x2c( '0000002B' )
         iterate                 /* decode '+-' as '+' = u+002B   */
      end

      TMP = verify( SRC || '-', B64 )
      if TMP = 1  then  do       /* '+' before non-B64 is invalid */
         DST = DST || x2c( '0000FFFD' )
         iterate
      end

      TOP = left( SRC, TMP - 1 ) ;  SRC = substr( SRC, TMP )
      TMP = ''
      do until TOP == ''         /* decode B64 chars.s after '+'  */
         parse var TOP POS 2 TOP
         POS = d2x( pos( POS, B64 ) - 1 )
         TMP = TMP || right( x2b( POS ), 6, 0 )
      end
      POS = length( TMP )        /* RFC 1642 UTF-7 B64 has no pad */
      TOP = x2c( b2x( left( TMP, POS - POS // 8 )))

      ERR = ( POS // 8 = 6 )     ;  POS = length( TOP )
      if POS // 2 then  do       /* note extraneous B64 char. ERR */
         ERR = 1                 ;  TOP = left( TOP, POS - 1 )
      end                        /* note odd number of octets ERR */

      do until TOP == ''         /* process even number of octets */
         parse var TOP TMP 3 TOP ;  TMP = c2d( TMP )
         select
            when  TMP < 55296 then  DST = DST || x2c( d2x( TMP, 8 ))
            when  57343 < TMP then  DST = DST || x2c( d2x( TMP, 8 ))
            when  56319 < TMP then  DST = DST || x2c( '0000FFFD' )
            when  TOP == ''   then  DST = DST || x2c( '0000FFFD' )
            otherwise            /* got low surrogate, handle U32 */
               POS = 1024 * ( TMP - 55296 + 64 )
               parse var TOP TMP 3 TOP
               TMP = c2d( TMP ) - 56320
               if 0 <= TMP & TMP < 1024
                  then  DST = DST || x2c( d2x( POS + TMP, 8 ))
                  else  DST = DST || x2c( '0000FFFD' )
         end                     /* no high surrogate: use u+FFFD */
      end                        /* after B64 problems add u+FFFD */
      if ERR   then  DST = DST || x2c( '0000FFFD' )
      if abbrev( SRC, '-' )   then  SRC = substr( SRC, 2 )
   end
   return DST

UTF7.O:  procedure               /* UTF-32BE to UTF-7 encoder     */
   B64 = 'abcdefghijklmnopqrstuvwxyz'
   B64 = translate( B64 ) || B64 || '0123456789+/'
   parse arg SRC                 ;  DST = ''
   B16 = ''

   do while 4 <= length( SRC )   /* split next UTF-32BE from SRC  */
      parse var SRC CHR 5 SRC    ;  TMP = c2d( CHR )

      select                     /* special cases '\', '~', etc.  */
         when  TMP <=    8 then  CHR = right( CHR, 2 )
         when  TMP <=   10 then  CHR = right( CHR, 1 )
         when  TMP <=   12 then  CHR = right( CHR, 2 )
         when  TMP =    13 then  CHR = right( CHR, 1 )
         when  TMP <=   31 then  CHR = right( CHR, 2 )
         when  TMP <=   91 then  CHR = right( CHR, 1 )
         when  TMP =    92 then  CHR = right( CHR, 2 )
         when  TMP <=  125 then  CHR = right( CHR, 1 )
         when  TMP < 55296 then  CHR = right( CHR, 2 )
         when  TMP < 57344 then  CHR = x2c( 'FFFD' )
         when  TMP < 65536 then  CHR = right( CHR, 2 )
         otherwise               CHR = UTF16O( CHR )
      end

      if length( CHR ) > 1 then  do
         B16 = B16 || CHR        ;  TMP = length( SRC )
         select                  /* collect UTF-16 in buffer B16  */
            when  4 <= TMP then  iterate
            when  1 <= TMP then  B16 = B16 || x2c( 'FFFD' )
            otherwise   nop      /* but output B16 at end of SRC, */
         end                     /* CHR = '' triggers sanity '-'  */
         SRC = ''                ;  CHR = ''
      end

      if B16 \== ''  then  do    /* output B16 before UTF-7 ASCII */
         DST = DST || '+'        /* '+' (excl. '+-') starts a B64 */
         B16 = x2b( c2x( B16 ))  /* '-' or non-B64 terminates B64 */
         TMP = ( length( B16 ) / 4 ) // 3
         B16 = B16 || copies( '00', TMP )
         do while B16 <> ''
            parse var B16 N 7 B16   ;  N = x2d( b2x( N ))
            DST = DST || substr( B64,  N + 1, 1 )
         end                     /* add '-' also if next is a '-' */
         if sign( pos( CHR, B64 )) | abbrev( '-', CHR )
            then  DST = DST || '-'
      end
      if CHR = '+'   then  DST = DST || '+-'
                     else  DST = DST || CHR
   end
   if sign( length( SRC )) then  DST = DST || '+//0-'
   return DST

UTF4.I:  procedure               /* UTF-4 to UTF-32BE decoder     */
   parse arg SRC                 ;  DST = ''

   do while length( SRC ) > 0
      parse var SRC LB 2 SRC     ;  LB = c2d( LB )

      if LB <= 127 | ( 160 <= LB & LB <= 255 )  then  do
         DST = DST || x2c( d2x( LB, 8 ))  ;  iterate
      end

      LB = LB - 128              ;  CHR = 0
      NX = c2x( left( SRC, LB )) ;  SRC = substr( SRC, LB + 1 )
      do N = 2 to 2 * LB by 2
         CHR = CHR * 16 + x2d( substr( NX, N, 1 ))
      end N
      DST = DST || x2c( d2x( CHR, 8 ))
   end
   return DST

UTF4.O:  procedure               /* UTF-32BE to UTF-4 encoder     */
   parse arg SRC                 ;  DST = ''

   do while 4 <= length( SRC )   /* split next UTF-32BE from SRC  */
      parse var SRC CHR 5 SRC    ;  CHR = c2d( CHR )

      if CHR <= 127 | ( 160 <= CHR & CHR <= 255 )  then  do
         DST = DST || d2c( CHR ) ;  iterate
      end
      CHR = d2x( CHR )           ;  LEN = length( CHR )
      DST = DST || d2c( 128 + LEN )
      do N = 1 to LEN
         DST = DST || d2c( 144 + x2d( substr( CHR, N, 1 )))
      end N
   end
   if sign( length( SRC )) then  DST = DST || x2c( '948F8F8F8D' )
   return DST

UTF1.I:  procedure               /* UTF-1 to UTF-32BE decoder     */
   parse arg SRC                 ;  W.1 = x2d(  4016 )
   DST = ''                      ;  W.2 = x2d( 38E2E )

   do while length( SRC ) > 0
      parse var SRC LB 2 SRC     ;  LB = c2d( LB )
      if LB < 160 then  do
         DST = DST || x2c( d2x( LB, 8 ))  ;  iterate
      end
      select
         when LB = 160  then  do
            T = 1 ;  CHR =  66   ;  LB = 0
         end
         when LB < 246  then  do
            T = 1 ;  CHR = 256   ;  LB = LB - 161
         end
         when LB < 252  then  do
            T = 2 ;  CHR = W.1   ;  LB = LB - 246
         end
         otherwise
            T = 4 ;  CHR = W.2   ;  LB = LB - 252
      end

      CHR = CHR + LB * ( 190 ** T )
      do N = T - 1 to 0 by -1
         parse var SRC LB 2 SRC  ;  L = c2d( LB )
         select                  /* accept trailing 21..7E/A0..FF */
            when 160 <= L           then  L = L - 66
            when  33 <= L & L < 127 then  L = L - 33
            otherwise            /* reject trailing 00..20/7F..9F */
               CHR = x2d( 'FFFD' )
               SRC = LB || SRC   ;  leave N
         end
         CHR = CHR + L * ( 190 ** N )
      end N
      select                     /* accept A0..D7FF, E000..10FFFF */
         when 1114111 <  CHR  then  DST = DST || x2c( '0000FFFD' )
         when   57344 <= CHR  then  DST = DST || x2c( d2x( CHR, 8 ))
         when   55296 <= CHR  then  DST = DST || x2c( '0000FFFD' )
         when     160 <= CHR  then  DST = DST || x2c( d2x( CHR, 8 ))
         otherwise                  DST = DST || x2c( '0000FFFD' )
      end                        /* 7F..9F never arrive here, but */
   end                           /* 00..7E (bad UTF-1 A021..A07E) */
   return DST

UTF1.O:  procedure               /* UTF-32BE to UTF-1 encoder     */
   parse arg SRC                 ;  W.1 = x2d(  4016 )
   DST = ''                      ;  W.2 = x2d( 38E2E )

   do while 4 <= length( SRC )   /* split next UTF-32BE from SRC  */
      parse var SRC CHR 5 SRC    ;  CHR = c2d( CHR )
      if CHR < 256   then  do
         if 160 <= CHR  then  DST = DST || d2c( 160 )
         DST = DST || d2c( CHR ) ;  iterate
      end
      select
         when CHR < W.1 then  do
            T = 1 ;  L = 161     ;  CHR = CHR - 256
         end
         when CHR < W.2 then  do
            T = 2 ;  L = 246     ;  CHR = CHR - W.1
         end
         otherwise
            T = 4 ;  L = 252     ;  CHR = CHR - W.2
      end

      DST = DST || d2c( L + CHR % ( 190 ** T ))
      do N = T - 1 to 0 by -1    /* trailing bytes 21..7E, A0..FF */
         L = ( CHR % ( 190 ** N )) // 190
         if L < 94   then  DST = DST || d2c( L + 33 )
                     else  DST = DST || d2c( L + 66 )
      end N
   end
   if sign( length( SRC )) then  DST = DST || x2c( 'F765AD' )
   return DST

BOCU.I:  procedure               /* BOCU-1 to UTF-32BE decoder    */
   parse arg SRC                 /* (TRAP if invalid trail bytes) */
   PREV = 64                     ;  DST = ''             /* (RD1) */

   do while length( SRC ) > 0
      parse var SRC LB 2 SRC     ;  LB = c2d( LB )

      if LB <= 32 | LB = 255  then do                    /* (RD2) */
         if LB <> 32 then  PREV = 64                     /* (RD3) */
         if LB < 255 then  DST = DST || x2c( d2x( LB, 8 ))
         iterate                 /* reset state if 255 here (RD6) */
      end

      select                     /* single RD4 or multi-byte RD5: */
         when 254  = LB then  do
            T = 3 ;  DIFF =  187660 ;  LB = LB - 254
         end
         when 251 <= LB then  do
            T = 2 ;  DIFF =   10513 ;  LB = LB - 251
         end
         when 208 <= LB then  do
            T = 1 ;  DIFF =      64 ;  LB = LB - 208
         end
         when  80 <= LB then  do
            T = 0 ;  DIFF =       0 ;  LB = LB - 144
         end
         when  37 <= LB then  do
            T = 1 ;  DIFF =     -64 ;  LB = LB -  80
         end
         when  34 <= LB then  do
            T = 2 ;  DIFF =  -10513 ;  LB = LB -  37
         end
         when  33  = LB then  do
            T = 3 ;  DIFF = -187660 ;  LB = LB -  34
         end
      end                        /* otherwise force REXX error 40 */

      CHR  = LB * ( 243 ** T ) + DIFF + PREV
      do N = 1 to T
         parse var SRC LB 2 SRC  /* missing trail bytes => empty, */
         LB = c2d( LB )          /* empty => 0, causes TRAP below */
         select
            when  33 <= LB & LB < 256  then  LB = LB - 13
            when  28 <= LB & LB <= 31  then  LB = LB - 12
            when  16 <= LB & LB <= 25  then  LB = LB - 10
            when   1 <= LB & LB <=  6  then  LB = LB -  1
            otherwise   exit TRAP( 'bad trail byte' x2d( LB ))
         end
         CHR = CHR + LB * ( 243 ** ( T - N ))
      end N

      DST = DST || x2c( d2x( CHR, 8 ))
      PREV = BOCU.5( CHR )
   end
   return DST

BOCU.O:  procedure               /* UTF-32BE to BOCU-1 encoder    */
   parse arg SRC
   PREV = 64                     ;  DST = ''                /* R1 */

   do while 0 < length( SRC )    /* split next UTF-32BE from SRC  */
      parse var SRC CHR 5 SRC
      if length( CHR ) = 4 then  CHR = c2d( CHR )
                           else  CHR = x2d( 'FFFD' )

      if CHR <= 32   then  do    /* C0 control or space, R2 or R3 */
         if CHR < 32 then  PREV = 64                        /* R3 */
         DST = DST || d2c( CHR ) ;  iterate                 /* R2 */
      end
      DIFF = CHR - PREV                                     /* R4 */
      PREV = BOCU.5( CHR )                                  /* R5 */
      TAIL = ''                  /* R4.1 handled with R4.2 - R4.6 */

      select                     /* R4.2 base LEAD bytes and R4.3 */
         when   1114111 <  DIFF  then  exit TRAP( 10FFFF )
         when    187660 <= DIFF  then  do    /*  3,  FE,   2DD0C  */
            T = 3 ; DIFF = DIFF - 187660  ;  LEAD = 254
         end
         when     10513 <= DIFF  then  do    /*  2,  FB,    2911  */
            T = 2 ; DIFF = DIFF -  10513  ;  LEAD = 251
         end
         when        64 <= DIFF  then  do    /*  1,  D0,      64  */
            T = 1 ; DIFF = DIFF -     64  ;  LEAD = 208
         end
         when       -64 <= DIFF  then  do    /*  0,  90,       0  */
            T = 0                         ;  LEAD = 144
         end
         when    -10513 <= DIFF  then  do    /*  1,  50,     -64  */
            T = 1 ; DIFF = DIFF +     64  ;  LEAD =  80
         end
         when   -187660 <= DIFF  then  do    /*  2,  25,   -2911  */
            T = 2 ; DIFF = DIFF +  10513  ;  LEAD =  37
         end
         when  -1114111 <= DIFF  then  do    /*  3,  22,  -2DDC0  */
            T = 3 ; DIFF = DIFF + 187660  ;  LEAD =  34
         end
      end                        /* otherwise force REXX error 40 */

      do N = 1 to T              /* determine trail bytes (R4.4): */
         M = DIFF // 243         ;  DIFF = DIFF % 243
         if M < 0 then  do       /* non-negative modulo   (R4.4a) */
            M = M + 243          ;  DIFF = DIFF - 1
         end
         select                  /* avoid 00, 07..0F, 1A..1B, 20: */
            when  M <=   5 then  TAIL = d2c( M +   1 ) || TAIL
            when  M <=  15 then  TAIL = d2c( M +  10 ) || TAIL
            when  M <=  19 then  TAIL = d2c( M +  12 ) || TAIL
            when  M <= 242 then  TAIL = d2c( M +  13 ) || TAIL
         end                     /* otherwise force REXX error 40 */
      end N

      DST = DST || d2c( LEAD + DIFF ) || TAIL   /* R4.5 and R4.6  */
   end
   return DST

BOCU.5:                          /* Hiragana etc. not tested here */
   select
      when arg( 1 ) < x2d( '3040' ) then  nop   /* Hiragana (R5a) */
      when arg( 1 ) < x2d( '30A0' ) then  return x2d( '3070' )
      when arg( 1 ) < x2d( '4E00' ) then  nop   /* Unihan   (R5b) */
      when arg( 1 ) < x2d( '9FA6' ) then  return x2d( '7711' )
      when arg( 1 ) < x2d( 'AC00' ) then  nop   /* Hangul   (R5c) */
      when arg( 1 ) < x2d( 'D7A4' ) then  return x2d( 'C1D1' )
      otherwise                           nop
   end
   return arg( 1 ) - ( arg( 1 ) // 128 ) + 64   /* middle of page */

/* see <URL:http://purl.net/xyzzy/rexxtrap.htm>, (c) F. Ellermann */

TRAP:                            /* select REXX exception handler */
   call trace 'O' ;  trace N           /* don't trace interactive */
   parse source TRAP                   /* source on separate line */
   TRAP = x2c( 0D ) || right( '+++', 10 ) TRAP || x2c( 0D0A )
   TRAP = TRAP || right( '+++', 10 )   /* = standard trace prefix */
   TRAP = TRAP strip( condition( 'c' ) 'trap:' condition( 'd' ))
   select
      when wordpos( condition( 'c' ), 'ERROR FAILURE' ) > 0 then do
         if condition( 'd' ) > ''      /* need an additional line */
            then TRAP = TRAP || x2c( 0D0A ) || right( '+++', 10 )
         TRAP = TRAP '(RC' rc || ')'   /* any system error codes  */
         if condition( 'c' ) = 'FAILURE' then rc = -3
      end
      when wordpos( condition( 'c' ), 'HALT SYNTAX'   ) > 0 then do
         if condition( 'c' ) = 'HALT' then rc = 4
         if condition( 'd' ) > '' & condition( 'd' ) <> rc then do
            if condition( 'd' ) <> errortext( rc ) then do
               TRAP = TRAP || x2c( 0D0A ) || right( '+++', 10 )
               TRAP = TRAP errortext( rc )
            end                        /* future condition( 'd' ) */
         end                           /* may use errortext( rc ) */
         else  TRAP = TRAP errortext( rc )
         rc = -rc                      /* rc < 0: REXX error code */
      end
      when condition( 'c' ) = 'NOVALUE'  then rc = -2 /* dubious  */
      when condition( 'c' ) = 'NOTREADY' then rc = -1 /* dubious  */
      otherwise                        /* force non-zero whole rc */
         if datatype( value( 'RC' ), 'W' ) = 0 then rc = 1
         if rc = 0                             then rc = 1
         if condition() = '' then TRAP = TRAP arg( 1 )
   end                                 /* direct: TRAP( message ) */

   TRAP = TRAP || x2c( 0D0A ) || format( sigl, 6 )
   signal on syntax name TRAP.SIGL     /* throw syntax error 3... */
   if 0 < sigl & sigl <= sourceline()  /* if no handle for source */
      then TRAP = TRAP '*-*' strip( sourceline( sigl ))
      else TRAP = TRAP '+++ (source line unavailable)'
TRAP.SIGL:                             /* ...catch syntax error 3 */
   if abbrev( right( TRAP, 2 + 6 ), x2c( 0D0A )) then do
      TRAP = TRAP '+++ (source line unreadable)'   ;  rc = -rc
   end
   select
      when 0 then do                   /* in pipes STDERR: output */
         parse version TRAP.REXX       /* REXX/Personal: \dev\con */
         if abbrev( TRAP.REXX, 'REXXSAA ' ) |                /**/ ,
            6 <= word( TRAP.REXX, 2 )  then  TRAP.REXX = 'STDERR'
                                       else  TRAP.REXX = '\dev\con'
         signal on syntax name TRAP.FAIL
         call lineout TRAP.REXX , TRAP /* fails if no more handle */
      end
      when 0 then do                   /* OS/2 PM or ooREXX on NT */
         signal on syntax name TRAP.FAIL
         call RxMessageBox translate( TRAP, ' ', x2c( 0D )), /**/ ,
            'Trap' time(),, 'ERROR'
      end
      otherwise   say TRAP ; trace ?L  /* interactive Label trace */
   end

   if condition() = 'SIGNAL' then signal TRAP.EXIT
TRAP.CALL:  return rc                  /* continue after CALL ON  */
TRAP.FAIL:  say TRAP ;  rc = 0 - rc    /* force TRAP error output */
TRAP.EXIT:  exit   rc                  /* exit for any SIGNAL ON  */
