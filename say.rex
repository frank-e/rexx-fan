/* Classic REXX 5.00 (Regina) or 6.03+ (ooRexx) with RexxUtil     */

   signal on novalue  name ERROR ;  parse version UTIL REXX .
   if ( 0 <> x2c( 30 )) | ( REXX <> 5 & REXX < 6.03 )
      then  exit ERROR( 'untested' UTIL REXX )
   if 6 <= REXX   then  interpret  'signal on nostring   name ERROR'
   if 5 <= REXX   then  interpret  'signal on lostdigits name ERROR'
   signal on halt     name ERROR ;  signal on failure    name ERROR
   signal on notready name ERROR ;  signal on error      name ERROR
   numeric digits 20             ;  UTIL = REGUTIL()

/* -------------------------------------------------------------- */

   if arg() > 1      then  return USAGE()
   if arg( 1 ) = '?' then  return FUNCS()
   TEMP = left( strip( arg( 1 )), 2 )
   TEMP = wordpos( TEMP , '-? /? /h -h' )
   if TEMP > 0       then  return USAGE()

   interpret 'say' arg( 1 )
   return 0

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'LINE'
   say                           /* suited for REXXC tokenization */
   say " REXX  interpret 'say' LINE  for quick command line tests."
   say ' On a Windows command line < & ^ | > have to be escaped as'
   say ' ^< ^& ^^ ^| ^> ONLY outside of DQUOTEd strings.  Example:'
   say USE 'c2d( "&" ) ^> c2d( ''^"'' )'
   say
   say 'Usage:' USE '?'
   say ' Shows a list of the implemented functions in addition to '
   say ' REXX built-in functions.                                 '
   return 1

FUNCS:   procedure
   if arg() then  do             /* Skip ERROR() trace in SAY.REX */
      say 'Error:' arg( 1 )      ;  say 'Usage:'
   end
   say '    exp( x )    = pow( e, x )              for e = exp(1) '
   say '     ln( x )    = log( x, e )              for x > 0      '
   say '    log( x )    = ln( x ) / ln( 2 )        for x > 0      '
   say '    log( x, y ) = ln( x ) / ln( y )                       '
   say '    pow( x, y ) = exp( ln( x ) * y )       for x > 0      '
   return 1

/* -------------------------------------------------------------- */

POW:     procedure               /* FIXME: more math from RxShell */
   arg X, Y                      ;  D = digits()
   if D > 60 | X <= 0   then  exit FUNCS( 'pow(' X ',' Y ')' )
   numeric digits 60             ;  Y = EXP( Y * LN( X ))
   numeric digits D              ;  return format( Y )

LOG:     procedure               /* REXX math copied from RxShell */
   arg X, Y                      ;  D = digits()
   if Y = ''   then  Y = 2       ;  Z = min( X, Y )
   if D > 60 | Z <= 0   then  exit FUNCS( 'log(' X ',' Y ')' )
   numeric digits 60             ;  Y = LN( X ) / LN( Y )
   numeric digits D              ;  return format( Y )

EXP:     procedure               /* REXX math copied from RxShell */
   arg X                         ;  D = digits()
   if D > 60            then  exit FUNCS( 'exp(' X ')' )
   E = 2.71828182845904523536028747135266249775724709369995957496697
   numeric digits 60
   select
      when  X < 0    then  Y = 1 / EXP( 0 - X )
      when  X > 2    then  do
         N = trunc( X )          ;  Y = E ** N
         Y = Y * EXP( X - N )
      end
   otherwise
      P = 1                      ;  Y = 1
      do N = 1 until R = Y
         R = Y
         P = P * X / N           ;  Y = Y + P
      end N
   end
   numeric digits D              ;  return format( Y )

LN:      procedure               /* REXX math copied from RxShell */
   arg X                         ;  D = digits()
   if D > 60 | X <= 0   then  exit FUNCS( 'ln(' X ')' )
   E = 2.71828182845904523536028747135266249775724709369995957496697
   numeric digits 60             ;  Y = 0
   if X > E then  do
      do while X > E
         Q = 1
         do N = 1 until X <= R
            R = E ** Q           ;  Q = Q + Q
         end N
         N = 2 ** ( N - 2 )      ;  R = E ** N
         do while X > R
            Y = Y + N            ;  X = X / R
         end
      end
      Y = Y + LN( X )
   end
   else  do
      X = ( X - 1 ) / ( X + 1 )  ;  Q = X * X
      do N = 1 by 2 until R = Y
         R = Y                   ;  Y = Y + 2 * X / N
         X = X * Q
      end N
   end
   numeric digits D              ;  return format( Y )

/* ----------------------------- (Regina SysLoadFuncs 2015-12-06) */

REGUTIL: procedure               /* Not needed for ooRexx > 6.03  */
   if RxFuncQuery( 'SysLoadFuncs' ) then  do
      ERR = RxFuncAdd( 'SysLoadFuncs', 'RexxUtil' )
      if ERR <> 0 then  exit ERROR( 'RexxUtil load error' ERR )
   end                           /* static Regina has no RexxUtil */
   ERR = SysLoadFuncs()          ;  return SysUtilVersion()

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

