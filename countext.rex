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

   parse arg E..                 ;  if E.. = '' then  exit USAGE()
   T.1 = directory( . )          ;  T.. = qualify( E.. )
   T.2 = directory( T.. )        ;  T.1 = directory( T.1 )
   if T.2 <> T..  then  exit USAGE( 'found no' E.. )

   E.  = 0                       ;  E.. = '\'
   T.0 = 0

   if    right( T.., 1 ) <> E..  then  T.. = T.. || E..

   do N = 1 to DIRTREE( T.. || '*', 'S.', 'DOS' )
      if right( S.N, 1 ) <> E..  then  S.N = S.N || E..
      call ERROUT left( S.N, 78 ) || x2c( 0D )

      do F = 1 to DIRTREE( S.N || '*.*', 'F.', 'FO' )
         L = lastpos( '.', F.F )
         if L > 0 then  do
            X = translate( substr( F.F, L ))
            E.X = E.X + 1

            do T = 1 to T.0 until X = T.T ;  end T
            if T.0 = T - 1 then  do
               T.0 = T           ;  T.T = X
            end
         end
         else  call SysSleep 1
      end F
   end N

   do N = 1 to T.0
      X = T.N                    ;  T.N = right( E.X, 6 ) X
   end N

   call PERROR left( '', 78 )    ;  say
   call KWIK 'T.'
   do N = 1 to T.0
      say T.N
   end N
   say right( T.0, 6 ) '.*'      ;  return 0

/* ----------------------------- (REXX USAGE template 2016-03-06) */

USAGE:   procedure               /* show (error +) usage message: */
   parse source . . USE          ;  USE = filespec( 'name', USE )
   say x2c( right( 7, arg()))    /* terminate line (BEL if error) */
   if arg() then  say 'Error:' arg( 1 )
   say 'Usage:' USE 'directory'
   say                           /* suited for REXXC tokenization */
   say 'Count file extensions in tha given sub-directory tree.'
   return 1                      /* exit code 1, nothing happened */

/* ----------------------------- (rexxsort.rex WSORT, 2006-07-28) */
/* Quick sort, partition keys P selected as the middle of 3 keys. */
/* Only partitions with more than 3 keys are still handled in the */
/* inmost loop, therefore the pushed bigger part consists of more */
/* than 1 key without "L < R" tests.                              */

KWIK:                            /* quick sort: call KWIK 'stem.' */
   if arg() <> 1  then  return abs( /* REXX error 40 */ )
   THIS... = arg( 1 )            /* abuse global THIS... as stem  */
   if right( THIS... , 1 ) <> .  then  THIS... = THIS... || .
   return KWIK.Y( THIS... )      /* expose THIS... stem           */

KWIK.Y:  procedure expose ( THIS... )
   S = 1 ;  SL.1 = 1 ;  SR.1 = value( THIS... || 0 )

   do until S = 0
      L = SL.S ;  R = SR.S ;  S = S - 1                  /* pop   */

      do while L < R
         I = ( L + R ) % 2 ;  P = value( THIS... || L )

         XR = value( THIS... || R )
         if XR << P then do                              /* R...L */
            call value THIS... || R, P
            call value THIS... || L, XR   ;  P = XR
         end                                             /* L...R */
         XI = value( THIS... || I )
         XR = value( THIS... || R )
         select
            when XI << P then do                         /* I L R */
               call value THIS... || I, P
               call value THIS... || L, XI
            end                                          /* L I R */
            when XI >> XR then do                        /* L R I */
               call value THIS... || R, XI
               call value THIS... || I, XR   ;  P = XR
            end                                          /* L I R */
            otherwise   P = XI                           /* L I R */
         end

         I = L + 1   ;  J = R - 1                        /* I...J */
         if J <= I then leave                            /* ready */

         do until I > J
            do while value( THIS... || I ) << P ;  I = I+1  ;  end
            do while value( THIS... || J ) >> P ;  J = J-1  ;  end

            if I <= J then do
               XI = value( THIS... || I )
               call value  THIS... || I, value( THIS... || J, XI )
               I = I + 1   ;  J = J - 1
            end
         end /* I  > J */

         if J - L < R - I then do               /* less left keys */
            S = S + 1   ;  SL.S = I ;  SR.S = R ;  R = J
         end               /* pushed old R - I > 1 keys, now do L */
         else do                                /* more left keys */
            S = S + 1   ;  SL.S = L ;  SR.S = J ;  L = I
         end               /* pushed J - old L > 1 keys, now do R */
      end    /* R <= L */
   end       /* S == 0 */
   return value( THIS... || 0 )

/* ----------------------------- (SysFileTree wrapper 2017-05-12) */
/* Treat SysFileTree errors as fatal, otherwise return the number */
/* of found files stored in stem.0 for the stem specified as 2nd  */
/* argument.  Attributes (4th + 5th SysFileTree argument) are not */
/* supported; the first three SysFileTree arguments are required. */
/* Clobbers DIRTREE.. in the scope of the caller.                 */

DIRTREE:                         /* return number of found files: */
   if right( arg( 2 ), 1 ) = '.' then  DIRTREE.. = arg( 2 )
                                 else  DIRTREE.. = arg( 2 ) || '.'
   if SysFileTree( arg( 1 ), DIRTREE.., arg( 3 )) = 0
      then  return value( DIRTREE.. || 0 )
      else  exit ERROR( 'SysFileTree failed near line' sigl )

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
