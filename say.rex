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

   parse upper source . . SAYS   ;  signal on syntax name ERROR

   if arg( 1 ) = '?' then  return FUNCS()
   SAYS = filespec( 'name', SAYS )
   HELP = left( strip( arg( 1 )), 2 )
   HELP = wordpos( HELP , '-? /? /h -h' )

   if abbrev( SAYS, 'SAY.' )  then  do
      if arg() <> 1 | HELP <> 0  then  return USAGE()
      interpret 'say' arg( 1 )
   end
   else  do
      if arg() <> 1 | HELP <> 0  then  return NOSAY()
      interpret arg( 1 )
   end

   return 0

/* -------------------------------------------------------------- */

NOSAY:   procedure
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say                           ;  say 'Usage:' USE 'LINE'
   say                           /* suited for REXXC tokenization */
   say  USE 'emulates Kedit command IMM and runs a one-LINE script'
   say ' as a Rexx  interpret LINE  command.  On a Windows command'
   say ' line < & ^ " | > have to be escaped as ^< ^& ^^ ^" ^| ^> '
   say ' ONLY outside of DQUOTed strings.  Example:               '
   say '       ' USE 'say c2d( "&" ) ^> c2d( ''^"'' )             '
   say
   say 'Usage:' USE '?'
   say ' Shows a list of the implemented functions in addition to '
   say ' REXX built-in functions.                                 '
   return 1

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

/* -------------------------------------------------------------- */

FUNCS:   procedure
   if arg() then  do             /* Report a math. error in FUNCS */
      say 'Error:' arg( 1 )      ;  say 'Usage:'
   end
   say '    exp( x )    = pow( e, x )              for e = exp(1) '
   say '     ln( x )    = log( x, e )              for x > 0      '
   say '    log( x )    = ln( x ) / ln( 2 )        for x > 0      '
   say '    log( x, y ) = ln( x ) / ln( y )                       '
   say '    pow( x, y ) = exp( ln( x ) * y )       for x > 0      '
   return 1

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

/* ----------------------------- (STDERR: unification 2020-03-14) */
/* PERROR() emulates lineout( 'STDERR:', emsg ) with ERROUT().    */
/* ERROUT() emulates charout( 'STDERR:', emsg ).                  */

/* ERROR() shows an error message and the source line number sigl */
/* on stderr.  Examples:   if 0 = 1 then  exit ERROR( 'oops' )    */
/*                         call ERROR 'interactive debug here'    */

/* ERROR() can also catch exceptions (REXX conditions), examples: */
/* SIGNAL ON ERROR               non-zero rc or unhandled FAILURE */
/* SIGNAL ON NOVALUE NAME ERROR  uninitialized variable           */
/* CALL ON NOTREADY NAME ERROR   blocked I/O (incl. EOF on input) */

/* ERROR() uses ERROR. in the context of its caller and returns 1 */
/* for explicit calls or CALL ON conditions.  For a SIGNAL ON ... */
/* condition ERROR() ends with exit 1.                            */

PERROR:  return sign( ERROUT( arg( 1 ) || x2c( 0D0A )))
ERROUT:  procedure
   parse version S V .           ;  signal off notready
   select
      when  6 <= V & V < 7 then  S = 'STDERR:'        /* (o)oRexx */
      when  S == 'REXXSAA' then  S = 'STDERR:'        /* IBM Rexx */
      when  V == 5.00      then  S = '<STDERR>'       /* Regina   */
      otherwise                  S = '/dev/con'       /* Quercus  */
   end                           /* Kedit KEXX 5.xy not supported */
   return charout( S, arg( 1 ))

ERROR:                           /* trace off, save result + sigl */
   ERROR.3 = trace( 'o' )        ;  ERROR.1 = value( 'result' )
   ERROR.2 = sigl                ;  call PERROR
   ERROR.3 = right( ERROR.2 '*-*', 10 )
   if ERROR.2 <= sourceline()
      then  call PERROR ERROR.3 strip( sourceline( ERROR.2 ))
      else  call PERROR ERROR.3 '(source line unavailable)'

   ERROR.3 = right( '+++', 10 ) condition( 'c' ) condition( 'd' )
   if condition() = ''  then  ERROR.3 = right( '>>>', 10 ) arg( 1 )
   call PERROR ERROR.3
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
   if ERROR.3 <> ''  then  call PERROR right( '>>>', 10 ) ERROR.3
   parse value ERROR.2 ERROR.1 with sigl result
   if ERROR.1 == 'RESULT'  then  drop result
   trace ?L                      /* -- interactive label trace -- */
ERROR:   if condition() = 'SIGNAL'  then  exit 1
                                    else  return 1
