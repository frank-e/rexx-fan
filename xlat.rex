/* REXX: convert UTF-16 or UTF-32 source.??? to UTF-4 source.bak  */

/* If the input begins with a signature (BOM) for UTF-32, UTF-16, */
/* UTF-8, or UTF-4 it is interpreted as a reliable indicator of   */
/* the encoding.  Otherwise the encoding is only a "best guess":  */

/* - a 0000???? or ????0000 pattern for ???? <> 0000 is handled   */
/*   as UTF-32BE or UTF-32LE; please note that this excludes all  */
/*   code points above u+00FFFF from this "best guess" effort.    */
/* - a source is handled as UTF-16LE or UTF-16BE for 75% visible  */
/*   Latin-1 code points without u+0000, u+FFFF, or surrogates,   */
/*   where "visible" stands for u+0020..u007F or u+00A0..u+00FF.  */
/* - after that if it contains any "unusual" C0 controls assume   */
/*   that it is binary junk.  This could be valid UTF-8 or UTF-4. */
/* - if it could be ASCII (in the test buffer) treat it as UTF-8. */
/* - if it could be UTF-8 and cannot be UTF-4 handle it as UTF-8. */
/* - if it could be UTF-4 and cannot be UTF-8 handle it as UTF-4. */
/* - if it could be UTF-8 (in the test buffer) treat it as UTF-8. */
/* - if it could be UTF-4 (in the test buffer) treat it as UTF-4. */
/* - finally assume that it is some binary junk or windows-1252.  */
/*   The buffer size is 512 octets unless the source is shorter.  */

/* While a signature (BOM) for UTF-1, UTF-EBCDIC, BOCU-1, or SCSU */
/* is respected, these charsets are not supported.  No attempt is */
/* made to identify UTF-7, as a result UTF-7 is handled as ASCII. */

/* UTF-8 sources are translated to UTF-4, and vice versa, without */
/* adding a new signature.  Consequently US-ASCII and UTF-7 input */
/* is unmodified.  For UTF-16 and UTF-32 sources a signature will */
/* be added if the input has no signature.  The file extension of */
/* the output is BAK, the output is intended for use with legacy  */
/* applications not supporting Unicode.                           */
/*                                        (Frank Ellermann, 2008) */

   signal on novalue          ;  signal on notready   name XLAT..
   parse source . . OUT

   SRC = strip( strip( strip( arg( 1 )),, '"' ))
   if SRC = '*'   then  do
      say OUT 'self test:'    ;  return XLAT.9()
   end
   if SRC = '' | sign( verify( SRC, '?*', 'M' ))   then  do
      say 'usage:' OUT 'FILE[.EXT]'
      say
      say 'creates UTF-4 FILE.BAK if the source FILE.EXT is'
      say 'UTF-8, UTF-16, or UTF-32 determined by the "BOM"'
      say 'signature or a quick plausibility check.'
      say
      say 'creates UTF-8 FILE.BAK if the source FILE.EXT is'
      say 'UTF-4.  Please note that UTF-4 makes only sense'
      say 'if the source is mostly Latin-1, where a legacy'
      say 'application might work better than for UTF-8.'
      say
      say 'For a self test run' OUT '*'
      exit 1
   end

   BUF = charin( SRC, /**/, min( 512, chars( SRC )))
   L.1 = XLAT.1( BUF )        ;  L.4 = abs( L.1 ) % 8
   if L.4 < 1  then  do /* stupid L.? names for the XLAT.9() test */
      if L.1 = 0  then  say OUT 'unidentified encoding'
      if L.1 = 1  then  say OUT 'does not support UTF-1'
      if L.1 = -1 then  say OUT 'does not support UTF-EBCDIC'
      if L.1 = 3  then  say OUT 'does not support BOCU-1'
      if L.1 = -3 then  say OUT 'does not support SCSU'
      if L.1 <> 4 then  exit 1
   end

   LEN = lastpos( '.', SRC )  ;  DST = SRC || '.bak'
   if LEN > 0  then  DST = left( SRC, LEN ) || 'bak'
   if stream( DST, 'c', 'q size' ) > 0 then  do
      say 'error:' OUT '"' || SRC || '"'
      say 'target "' || DST || '" already exists,'
      say 'erase or rename "' || DST || '" first.'
      exit 1
   end

   if L.4 > 1  then  do /* for UTF-16 and UTF-32 use binary input */
      L.0 = x2c( '00' )          ;  L.3 = -1
      L.2 = xrange( d2c( 160 ), d2c( 255 ))
      L.2 = xrange( L.0, d2c( 127 )) || L.2

      do until BUF == ''
         OUT = XLAT.0( BUF )
         LEN = charout( DST, OUT )
         BUF = charin( SRC, /**/, min( 512, chars( SRC )))
      end

      say L.3 'source characters were not Latin-1'
      return charout( DST )
   end

   call charout SRC     /* close input, use line mode for UTF-8   */
   select               /* (sorry, I am lazy and use what I have) */
      when  L.1 = 8  then  do while sign( lines( SRC ))
         BUF = linein( SRC )
         BUF = UTF32O( BUF )
         BUF = UTF4.O( BUF )
         call lineout DST, BUF
      end
      when  L.1 = 4  then  do while sign( lines( SRC ))
         BUF = linein( SRC )
         BUF = UTF4.I( BUF )
         BUF = UTF32I( BUF )
         call lineout DST, BUF
      end
   end

   say 'created UTF-' || L.1 DST
   return charout( DST )

XLAT..:
   say condition( 'c' ) condition( 'd' ) 'in line' sigl || ':'
   say sourceline( sigl )
   exit 1

XLAT.0:  procedure expose L.
   parse arg BUF           ;  OUT = ''

   do while BUF \== ''
      TOP = left( BUF, L.4 )
      BUF = substr( BUF, L.4 + 1 )
      if L.1 < 0  then  TOP = reverse( TOP )
      TOP = strip( TOP, 'L', L.0 )
      LEN = length( TOP ) * 2
      if L.3 = -1 then  do
         L.3 = 0           ;  OUT = x2c( 'FEFF' )
         if TOP == OUT  then  OUT = ''
                        else  OUT = x2c( '849F9E9F9F' )
      end
      if LEN = 2  then  do
         LEN = 0
         if sign( pos( TOP, L.2 ))
            then  OUT = OUT || TOP
            else  LEN = 2
      end
      if LEN > 0  then  do
         L.3 = L.3 + 1
         OUT = OUT || d2c( 128 + LEN )
         TOP = c2x( TOP )
         do X = 1 to LEN
            OUT = OUT || d2c( 144 + x2d( substr( TOP, X, 1 )))
         end
      end
   end
   return OUT

XLAT.1:  procedure      /* use signature (BOM) or a "best guess": */
   parse arg BUF
   select
      when  abbrev( BUF, x2c( '849F9E9F9F' ))   then  return 4
      when  abbrev( BUF, x2c( 'EFBBBF' ))       then  return 8
      when  abbrev( BUF, x2c( '0000FEFF' ))     then  return +32
      when  abbrev( BUF, x2c( 'FFFE0000' ))     then  return -32
      when  abbrev( BUF, x2c( 'FFFE' ))         then  return -16
      when  abbrev( BUF, x2c( 'FEFF' ))         then  return +16
      when  abbrev( BUF, x2c( 'F7644C' ))       then  return +1
      when  abbrev( BUF, x2c( 'DD736673' ))     then  return -1
      when  abbrev( BUF, x2c( 'FBEE28' ))       then  return +3
      when  abbrev( BUF, x2c( '0EFEFF' ))       then  return -3
      otherwise nop                             /* (try to) guess */
   end

   LEN = length( BUF )        ;  S.1 = x2d( 'D800' )
   ZER = x2c( '0000' )        ;  S.2 = x2d( 'DFFF' )

   if LEN // 4 == 0  then  do
      CHK = BUF         /* assume that 0000???? could be UTF-32BE */
      do until CHK == ''
         TOP = left( CHK, 4 ) ;  CHK = substr( CHK, 5 )
         if left(  TOP, 2 ) <> ZER  then  leave /* outside of BMP */
         if right( TOP, 2 ) == ZER  then  leave /* too many nulls */
      end
      if CHK == ''   then  return +32

      CHK = BUF         /* assume that ????0000 could be UTF-32LE */
      do until CHK == ''
         TOP = left( CHK, 4 ) ;  CHK = substr( CHK, 5 )
         if left(  TOP, 2 ) == ZER  then  leave /* too many nulls */
         if right( TOP, 2 ) <> ZER  then  leave /* outside of BMP */
      end
      if CHK == ''   then  return -32
   end
   if LEN // 2 == 0  then  do
      CHK = BUF         /* accept 75% visible Latin-1 as UTF-16LE */
      LAT = 0           /* but reject NUL, surrogates, and 0xFFFF */
      do until CHK == ''
         TOP = left( CHK, 2 ) ;  CHK = substr( CHK, 3 )
         C = c2d( reverse( TOP ))
         if C = 0 | C = 65535       then  leave /* nulls or FFFF  */
         if S.1 <= C & C <= S.2     then  leave /* outside of BMP */
         LAT = LAT + (( 31 < C & C < 128 ) | ( 159 < C & C < 256 ))
      end
      if ( CHK == '' ) & ( 3 * LEN <= 8 * LAT ) then  return -16

      CHK = BUF         /* accept 75% visible Latin-1 as UTF-16BE */
      LAT = 0           /* but reject NUL, surrogates, and 0xFFFF */
      do until CHK == ''
         TOP = left( CHK, 2 ) ;  CHK = substr( CHK, 3 )
         C = c2d( TOP )
         if C = 0 | C = 65535       then  leave /* nulls or FFFF  */
         if S.1 <= C & C <= S.2     then  leave /* outside of BMP */
         LAT = LAT + (( 31 < C & C < 128 ) | ( 159 < C & C < 256 ))
      end
      if ( CHK == '' ) & ( 3 * LEN <= 8 * LAT )  then  return +16
   end

   /* At this point we are done with the multibyte guesswork, and */
   /* can assume that any NUL or similar indicates binary garbage */

   CHK = BUF                  ;  BUF = ''
   do until CHK == ''
      TOP = left( CHK, 1 )    ;  CHK = substr( CHK, 2 )
      CHR = c2d( TOP )

      if 128 <= CHR  then  BUF = BUF || TOP     /* note non-ASCII */
      if  32 <= CHR  then  iterate              /* DEL (127) okay */
      if  28 <= CHR  then  return 0             /* reject control */
      if  26 <= CHR  then  iterate              /* SUB or ESC ok. */
      if  15 <= CHR  then  return 0             /* reject control */
      if   7 <= CHR  then  iterate              /* BEL..CR is ok. */
      return 0                                  /* reject control */
   end

   if BUF == ''      then  return 8             /* ASCII is UTF-8 */
   S.1 = XLAT.8( BUF )                          /* could be UTF-8 */
   S.2 = XLAT.4( BUF )                          /* could be UTF-4 */
   if S.1 = 0        then  return 4 * S.2       /* it is no UTF-8 */
   if S.2 = 0        then  return 8 * S.1       /* it is no UTF-4 */
   if S.1            then  return 8             /* could be UTF-8 */
   if S.2            then  return 4             /* could be UTF-4 */
   return 0                                     /* (windows-1252) */

XLAT.8:  procedure      /* return 0 if BUF is definitely no UTF-8 */
   parse arg BUF        /* or contains no UTF-8 lead byte, else 1 */
   S.2 = x2c( 'C0C1F5F6F7F8F9FAFBFCFDFEFF' )    /* UTF-8 illegal  */
   if sign( verify( BUF, S.2, 'M' ))   then  return 0

   S.1 = xrange( x2c( 'C2' ), x2c( 'F4' ))      /* UTF-8 leading  */
   S.2 = xrange( x2c( '80' ), x2c( 'BF' ))      /* UTF-8 trailing */
   POS = 1           ;  TOP = verify( BUF, S.1, 'M', POS )
   do while TOP > 0
      POS = TOP + 1  ;  CHR = substr( BUF, POS, 1 )
      if pos( CHR, S.2 ) = 0  then  return 0    /* it is no UTF-8 */
      POS = TOP + 1  ;  TOP = verify( BUF, S.1, 'M', POS )
   end
   return sign( verify( BUF, S.1, 'M' ))        /* could be UTF-8 */

XLAT.4:  procedure      /* return 0 if BUF is definitely no UTF-4 */
   parse arg BUF        /* or contains no UTF-4 lead byte, else 1 */
   S.2 = x2c( '80818788898A8B8C8D8E8F' )        /* UTF-4 illegal  */
   if sign( verify( BUF, S.2, 'M' ))   then  return 0

   S.1 = xrange( x2c( '82' ), x2c( '86' ))      /* UTF-4 leading  */
   S.2 = xrange( x2c( '91' ), x2c( '9F' ))      /* UTF-4 trailing */
   POS = 1           ;  TOP = verify( BUF, S.1, 'M', POS )
   do while TOP > 0
      POS = TOP + 1  ;  CHR = substr( BUF, POS, 1 )
      if pos( CHR, S.2 ) = 0  then  return 0    /* it is no UTF-4 */
      POS = TOP + 1  ;  TOP = verify( BUF, S.1, 'M', POS )
   end
   return sign( verify( BUF, S.1, 'M' ))        /* could be UTF-4 */

XLAT.9:  procedure      /* some hardwired XLAT plausibility tests */

   X.1 = x2c( '0041004F0055002400E400F600FC20AC' ) /* is UTF-16BE */
   X.2 = x2c( '41004F0055002400E400F600FC00AC20' ) /* is UTF-16LE */
   do N = 1 to 2
      Y = N + 2   ;  X.Y = '' ;  Z = x2c( '0000' )
      do L = 1 to length( X.N ) % 2
         W = substr( X.N, 2 * L - 1, 2 )
         if N // 2   then  W = Z || W        /*   X.3 is UTF-32BE */
                     else  W = W || Z        /*   X.4 is UTF-32LE */
         X.Y = X.Y || W
      end L
   end N
   X.5 = x2c( '414F5524C3A4C3B6C3BCE282AC' )       /* is UTF-8    */
   X.6 = x2c( '414F5524E4F6FC8492909A9C' )         /* is UTF-4    */
   X.7 = x2c( '414F5524A0E4A0F6A0FCCBC2' )         /* is UTF-1    */
   X.8 = x2c( '919FA574D071C6CCF166' )             /* is BOCU-1   */
   X.9 = x2c( '414F5524E4F6FC80' )                 /* is cp 1252  */
   X.0 = x2c( '414F5524849481D5' )                 /* is cp  858  */

   X.. = '0 16 -16 32 -32 8 4 0 0 0'

   do N = 0 to 9
      W = word( X.., N + 1 )  ;  B = ( XLAT.1( X.N ) <> W )

      if B  then  say 'XLAT test' N 'fail (' W ')'
            else  say 'XLAT test' N 'okay (' W ')'
      if B  then  return 1
   end

   L = x2c( '849F9E9F9F' ) || X.6            /* test UTF-4 + BOM  */

   L.0 = x2c( '00' )
   L.2 = xrange( d2c( 160 ), d2c( 255 ))
   L.2 = xrange( L.0, d2c( 127 )) || L.2

   do N = 1 to 4        /* emulate an ordinary L.? pre-processing */
      L.1 = XLAT.1( X.N )     ;  W = word( X.., N + 1 )
      L.4 = abs( L.1 ) % 8    ;  Y = d2x( N + 9 )
      L.3 = -1                ;  B = ( XLAT.0( X.N ) <> L )

      if B  then  say 'XLAT test' Y 'fail (' W ')'
            else  say 'XLAT test' Y 'okay (' W ')'
      if B  then  return 1
   end

   do N = 5 to 6        /* sanity, for a better test see BOCU.CMD */
      W = word( X.., N + 1 )  ;  Y = d2x( N + 9 )

      if N = 5 then  B = ( X.6 <> UTF4.O( UTF32O( X.5 )))
               else  B = ( X.5 <> UTF32I( UTF4.I( X.6 )))

      if B  then  say 'XLAT test' Y 'fail (' W ')'
            else  say 'XLAT test' Y 'okay (' W ')'
      if B  then  return 1
   end

   return 0

/* -------------------------------------------------------------- */
/* use known to be good UTF-8 and UTF-4 procedures from BOCU.CMD, */
/* see <URL:http://purl.net/xyzzy/src/bocu.cmd>, (c) F. Ellermann */

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

