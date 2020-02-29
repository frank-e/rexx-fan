/* OS/2 REXX:  Quercus REXX/Personal offers a simple STACKGET.exe */
/* to write the content of a REXX queue to standard output, which */
/* may be useful in unnamed pipes like STACKGET | SORT | MORE     */

/* Unfortunately STACKGET.exe requires a complete REXX/Personal   */
/* installation.  I prefer REXXSAA using REXX/Personal only when  */
/* needed - number crunching and similar applications, where the  */
/* superior performance of Quercus REXX outweighs minor problems. */

/* Usage: STACKGET [/Mn] [queue]                                  */
/* where n limits the number of lines taken from the queue, the   */
/* default is to get all lines.  The parameter queue specifies a  */
/* REXX queue created by RxQueue( 'Create' ).  The default name   */
/* is specified in environmental variable RXQUEUE, and without it */
/* the SESSION queue is used.  This syntax isn't what I like, but */
/* I wanted to emulate STACKGET.exe as far as possible.           */

/* Examples:                                                      */
/* DIR | RXQUEUE /LIFO & STACKGET            (reverse DIR output) */
/* DIR | RXQUEUE /LIFO & STACKGET /M1 & RXQUEUE /CLEAR (one line) */
/* 2>&1 ECHO queue NN alive | RXQUEUE NN /LIFO && STACKGET /M1 NN */

/* General RxQueue CAVEATs:                                       */
/* The last example is weird, but AFAIK the only way to check the */
/* existence of a queue is an attempt to write something into it. */
/* Replace NN by SESSION to see the difference, but don't try it  */
/* for any queue used by other running processes.                 */

/* The only way to create queues is to use RxQueue( 'Create' ) -  */
/* simply using another name in RXQUEUE.exe, variable RXQUEUE, or */
/* RxQueue( 'Set' ) does not work.  A SESSION queue always exists */
/* - you cannot delete it - and is shared within an OS/2 session. */

/* I have only vague ideas about OS/2 "sessions", probably it is  */
/* something like a POSIX screen group.  If that is correct, then */
/* different processes can use different SESSION queues depending */
/* on their (guess) session.  Check this with DETACHed processes, */
/* or processes STARTed before a restart of the workplace shell.  */

   signal on  novalue  name TRAP ;  signal on  syntax name TRAP
   signal on  failure  name TRAP ;  signal on  halt   name TRAP
   signal on  notready name TRAP ;  arg LIMIT QUEUE

   if sign( pos( '?', arg( 1 ))) then  exit USAGE()
   if abbrev( QUEUE, '/' )       then  arg QUEUE LIMIT
   select
      when abbrev( LIMIT, '/M' ) then  LIMIT = substr( LIMIT, 3 )
      when abbrev( LIMIT, '/'  ) then  exit USAGE( LIMIT )
      when abbrev( LIMIT, '-M' ) & QUEUE <> ''
                                 then  LIMIT = substr( LIMIT, 3 )
      otherwise arg QUEUE  ;           LIMIT = ''
   end
   select
      when LIMIT = ''            then  LIMIT = copies( 9, digits())
      when datatype( LIMIT,'w' ) then  nop
      otherwise                        exit USAGE( LIMIT )
   end

   QUEUE = strip( strip( strip( QUEUE ), /**/, '"' ))
   if QUEUE = ''  then  QUEUE = XENV( 'RXQUEUE' )
   if QUEUE = ''  then  QUEUE = 'SESSION'
   OLDQU = RxQueue( 'Set', QUEUE )
   if RxQueue( 'Get' ) <>  QUEUE then  exit USAGE( QUEUE )

   do LIMIT = LIMIT to 1 by -1 while sign( queued())
      parse pull LINE   ;  say LINE
   end LIMIT
   exit RxQueue( 'Set', OLDQU ) = QUEUE

USAGE:   procedure
   parse source . . USE ;  EOL = x2c( 0D0A )

   USE = 'usage:' USE '[/Mn] [queue]' EOL
   if arg() then  USE = 'error:' arg( 1 ) EOL EOL || USE
   USE = USE || 'where /Mn is the maximal number of lines n' EOL
   USE = USE || "and queue is a result of RxQueue('Create')" EOL EOL
   USE = USE || 'Defaults: all lines and a queue determined' EOL
   USE = USE || 'by any SET RXQUEUE, else the SESSION queue.'
   say USE  ;  return arg()

/* see <URL:http://purl.net/xyzzy/rexxtrap.htm>, (c) F. Ellermann */

XENV: procedure                  /* DOS REXX portable environment */
   parse version ENV . .
   if ENV = 'REXXSAA' then do
      parse source ENV . .       /* OS/2 REXXSAA:  os2environment */
      if ENV = 'OS/2'   then ENV = 'OS2ENVIRONMENT'
                        else ENV = ENV || 'ENVIRONMENT'
   end                           /* DOS  REXXSAA:  DOSENVIRONMENT */
   else  ENV = 'ENVIRONMENT'     /* REXX/Personal:    environment */
   select
      when arg() = 1 then  return value( arg( 1 ),/* get */, ENV )
      when arg() = 2 then  return value( arg( 1 ), arg( 2 ), ENV )
      otherwise            return abs( /* force REXX error 40 */ )
   end

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
