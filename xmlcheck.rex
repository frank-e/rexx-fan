/* Usage:         XMLCHECK file                                   */
/* Purpose:       Check that the given file is well formed XML.   */
/*                The file is not modified.  XMLCHECK finds tag   */
/*                nesting errors, syntactically invalid NMTOKENs, */
/*                syntactically invalid attributes (assuming type */
/*                CDATA for attribute values), erroneous numeric  */
/*                character references (NCRs), any "&" outside of */
/*                entities, and similar issues.                   */
/* Caveats:       HTML is not XML, do not use XMLCHECK for HTML.  */
/*                The handling of "<!DOCTYPE ... >" even without  */
/*                DTD subset is incomplete.  "<![CDATA[ ... ]]>"  */
/*                and "<!-- ... -->" comments work as expected.   */
/*                For end tags "</xyz>" white space after "</" is */
/*                not yet supported and could be in fact invalid. */
/*                White space including line breaks after "<" or  */
/*                before ">" is ignored.  This might be invalid   */
/*                within "<!", "<?", or "?>".                     */
/* Unsupported:   "<![IGNORE[ ... ]]>" and "<![INCLUDE ... ]]>"   */
/*                are only used in DTDs or DTD subsets.  XMLCHECK */
/*                does not check the syntax of "<!ATTLIST ... >", */
/*                "<!ELEMENT ... >", or "<!ENTITY ... >" in DTDs. */
/* Procedures:       BOMB     accepts u+FEFF at begin of 1st line */
/*                   CDATA    checks all NCRs, '&', and '<'       */
/*                   CONTROL  accepts '09'x, '0A'x, and '0D'x     */
/*                   NMTOKEN  accepts letters, ':_', digits, '-.' */
/*                   PARAM    checks DTD parameter entity names   */
/*                   SUBSET   checks "<! ... >" in DTD subsets    */
/*                   UNWELL   reports missing closing tag source  */
/*                   GARBAGE  reports unexpected input data       */
/*                   FINDME   matches wanted string (or next '>') */
/*                   NICE     progress indicator up to 4 MB input */
/* See also:      <URL:http://purl.net/xyzzy/kex/xmlcheck.kex>    */
/*                <URL:http://purl.net/xyzzy/src/xmlcheck.rex>    */
/* Requires:      Classic or object REXX  (Frank Ellermann, 2008) */

   signal on novalue                ;  signal on notready

   FILE = strip( strip( strip( arg( 1 )),, '"' ))
   if FILE <> ''  then  FILE = stream( FILE, 'c', 'q exists' )
   if FILE =  ''  then  do
      if arg( 1 ) <> '' then  say 'not found:' arg( 1 )
      parse source . . X            ;  say
      say 'Usage:' X 'file'         ;  say
      say 'to check that the given file is well-formed XML.'
      exit 1
   end

   XCTL = xrange( x2c( 0E ), x2c( 1F )) || x2c( 7F )
   XCTL = xrange( x2c( 0B ), x2c( 0C )) || XCTL
   XCTL = xrange( x2c( 00 ), x2c( 08 )) || XCTL
   D.0 = 0                             /* number of open D.N tags */
   L.0 = 0                             /* max. tag nesting level  */
   ETAG = 0                         ;  ROOT = ''
   WANT = '<'                       ;  NEXT = ''
   EXPO = 'XCTL LINE'                  /* expose global variables */

   do LINE = 1 while sign( chars( FILE ))
      DATA = linein( FILE )         ;  call NICE length( DATA )

      N = words( NEXT )             ;  MORE = ''
      if N > 0 then  do
         N = wordindex( NEXT, N )   ;  MORE = substr( NEXT, N )
         NEXT = left( NEXT, N - 1 )
      end
      do until DATA = ''               /* remove spaces after '<' */
         parse var DATA WORD DATA      /* '[', or before '>', ']' */
         X = pos( right( MORE, 1 ), '<[' )
         N = pos(  left( WORD, 1 ), '>]' )
         if sign( X + N )  then  MORE = MORE || WORD
                           else  MORE = strip( MORE WORD )
      end

      if NEXT <> ''  then  do          /* get rid of old NEXT for */
         if WANT = '<'     then  do    /* comments or text nodes  */
            if       D.0 > 0        then  call CDATA NEXT
            else  if ROOT = '.DTD'  then  call PARAM NEXT
            else  if BOMB( NEXT )   then  nop
            else  exit GARBAGE( NEXT 'garbage outside of element' )
            NEXT = ''                  /* text node must be CDATA */
         end
         else  if WANT = '-->'               then  do
            if pos( '--', NEXT ) > 0   then  exit GARBAGE( '--' )
            NEXT = ''                  /* no '--' in XML comments */
         end
         else  if WANT = ']]>' | WANT = '?>' then  do
            call CONTROL NEXT       ;  NEXT = ''
         end                           /*  preserve anything else */
      end                              /* until WANT string found */

      NEXT = NEXT || MORE
      parse value FINDME( WANT, NEXT ) with STOP DOCT ',' WANT

      do while sign( STOP )            /* found next WANT string: */
         parse var NEXT DATA (WANT) NEXT
         DATA = strip( DATA )       ;  NEXT = strip( NEXT )

         if DATA <> '' & WANT = '<' then  do
            if       D.0 > 0        then  call CDATA DATA
            else  if ROOT = '.DTD'  then  call PARAM DATA
            else  if BOMB( DATA )   then  nop
            else  exit GARBAGE( DATA 'garbage outside of element' )
         end
         if       WANT = '<'  then  select
            when  NEXT = '!' | NEXT = '!['   then  do
               NEXT = '<' || NEXT   ;  leave
            end                        /* very dubious line break */
            when  abbrev( NEXT, '![CDATA[' ) then  WANT = ']]>'
            when  abbrev( NEXT, '!--' )      then  do
               NEXT = substr( NEXT, 4 )      ;     WANT = '-->'
            end
            when  abbrev( NEXT, '!DOCTYPE' ) then  do
               if substr( NEXT, 9, 1 ) <> ' '
                  then  exit GARBAGE( '<' || NEXT )
               if L.0 = 0 & ROOT <> '.DTD'
                  then  L.0 = -1       /* if unexpected <!DOCTYPE */
                  else  exit GARBAGE( '<' || NEXT '- dupe' )
               NEXT = substr( NEXT, 9 )      ;     WANT = ' ['
            end
            when  abbrev( NEXT, '!' )        then  do
               if L.0 = 0  then  ROOT = '.DTD'  ;  WANT = '>'
               if L.0 > 0  then  exit GARBAGE( '<' || NEXT )
               N = word( NEXT, 1 )  ;  D.1 = '<' || N
               N = wordpos( N, '!ATTLIST !ELEMENT !ENTITY' )
               if N = 0    then  exit GARBAGE( '<' || NEXT )
            end
            when  abbrev( NEXT, '?' )        then  WANT = '?>'
            when  NEXT = ''                  then  do
               NEXT = '<'           ;  leave
            end                        /* fetches the missing tag */
            when  ROOT = '.DTD'        /* cannot mix DTD and XML: */
            then  exit GARBAGE( '<' || NEXT 'after' D.1 )
            /* else expecting ordinary XML <tag>, <tag />, </tag> */
            when  D.0 = 0 & L.0 > 0    /* too many root elements: */
            then  exit GARBAGE( '<' || NEXT '- got already' D.1 )
            when  abbrev( NEXT, '/' ) = 0    then  do
               N = D.0 + 1          ;  D.N = NMTOKEN( NEXT )
               D.0 = N              ;  L.0 = max( D.0, L.0 )
               L.N = LINE           ;              WANT = '='
               NEXT = substr( NEXT, 1 + length( D.N ))
            end                        /* got NMTOKEN of open tag */
            when  D.0 = 0              /* missing a root element: */
            then  exit GARBAGE( '<' || NEXT '- missing root' )
            otherwise                  /* match the last open tag */
               N = D.0              ;  D.0 = N - 1
               ETAG = 1             ;              WANT = '>'
               if abbrev( NEXT, '/' || D.N ) = 0
                  then  exit UNWELL( D.N, L.N )
               NEXT = substr( NEXT, 2 + length( D.N ))
         end
         else  if WANT <> '>' then  select
            when  WANT = '"' | WANT = "'"    then  do
                  call CDATA DATA   ;              WANT = '='
            end
            when  WANT = '='                 then  do
               if NMTOKEN( DATA ) <> DATA
                  then  exit GARBAGE( DATA || '=' || NEXT )
               if NEXT = ''   then  do
                  NEXT = DATA '='   ;  leave
               end                     /* fetches attribute value */
               WANT = left( NEXT, 1 )
               if WANT = '"' | WANT = "'"
                  then  NEXT = substr( NEXT, 2 )
                  else  exit GARBAGE( DATA || '=' || NEXT )
            end
            when  WANT = ']>'                then  do
               call SUBSET DATA              ;     WANT = '<'
            end
            when  CONTROL( DATA )            then  OOPS = 0 / 0
            when  WANT = ' ['                then  do
               ROOT = word( DATA, 1 )        ;     WANT = ']>'
            end
            when  WANT = '-->'               then  do
               if pos( '--', DATA ) = 0      then  WANT = '<'
                  else  exit GARBAGE( '--' )
            end
            when  WANT = ']]>'               then  WANT = '<'
            when  WANT = '?>'                then  WANT = '<'
         end
         else  do                   ;              WANT = '<'
            select                     /* after old WANT was '>'  */
               when  ETAG        then  do
                  if DATA <> ''  then  exit GARBAGE( DATA || '>' )
                  ETAG = 0             /* end tag has to be empty */
               end
               when  DOCT | ROOT = '.DTD' then  do
                  if DOCT  then  ROOT = word( DATA, 1 )
                  call CDATA DATA
               end
               when  DATA = '/'  then  D.0 = D.0 - 1
               when  DATA <> ''  then  exit GARBAGE( DATA || '>' )
               otherwise   nop
            end
         end
         parse value FINDME( WANT, NEXT ) with STOP DOCT ',' WANT
      end
   end LINE

   N = D.0                          ;  LINE = LINE '(EOF)'
   select
      when  N > 0       then  exit UNWELL( D.N. L.N )
      when  WANT <> '<' then  exit GARBAGE( ': missing' WANT )
      when  L.0 = 0     then  if ROOT = '.DTD'  then  nop
                        else  exit GARBAGE( ': no XML elements' )
      when  ROOT = ''   then  ROOT = 'XML'
      when  L.0 < 0     then  exit GARBAGE( ': found no' ROOT )
      when  ROOT <> D.1 then  exit GARBAGE( D.1 '- expected' ROOT )
      otherwise   nop
   end

   if ROOT <> '.DTD'                   /* intentional dot in .DTD */
      then  N = 'max.' || right( L.0, 3 ) 'nested tags in'
      else  N = 'apparently well-formed'
   say strip( N ROOT ) 'file' FILE  ;  exit lineout( FILE )

/* -------------------------------------------------------------- */

NOTREADY:   say 'cannot open' FILE  ;  exit 1
NOVALUE:    say 'no value trap near line' sigl || ':'
            say sourceline( sigl )  ;  exit 1

NICE:    procedure expose (EXPO) NICE
   if symbol( 'NICE' ) <> 'VAR'  then  NICE = 0
   OLD = NICE % 40000               ;  NICE = NICE + arg( 1 )
   NEW = NICE % 40000               ;  if OLD = NEW   then  return
   OLD = x2c( 0D )                     /* up to 4 MB % 79 = 39819 */
   NEW = left( copies( '.', NEW // 80 ), 79 ) || OLD
   signal on syntax name NICE.TRAP  ;  call SysSleep 0
NICE.TRAP:                             /* ignore missing SysSleep */
   return charout( /**/, OLD || NEW )  /* show progress indicator */

/* -------------------------------------------------------------- */

BOMB:    procedure expose (EXPO)       /* accept BOM u+FEFF if in */
   if LINE > 1                         then  return 0 /* 1st line */
   if arg( 1 ) = x2c( 'EFBBBF' )       then  return 1 /* if UTF-8 */
   if arg( 1 ) = x2c( '849F9E9F9F' )   then  return 1 /* if UTF-4 */
   return 0                            /* other UTFs fail anyway  */

CDATA:   procedure expose (EXPO)       /* check entities and '<': */
   parse arg DATA                   ;  POS = pos( '&', DATA ) + 1
   do while POS > 1
      DATA = substr( DATA, POS )    ;  POS = pos( ';', DATA ) + 1
      if POS > 1  then  ENT = left( DATA, POS - 2 )
                  else  ENT = ''       /* missing ';' fails below */
      DATA = substr( DATA, POS )    ;  POS = pos( '&', DATA ) + 1

      select                           /* get number of hex. NCR: */
         when  abbrev( ENT, '#x' )  then  do
            T = translate( substr( ENT, 3 ), '.', ' ' )
            if datatype( T, 'x' )   then  T = x2d( T )
                                    else  T = 0
         end                           /* get number of dec. NCR: */
         when  abbrev( ENT, '#'  )  then  do
            T = translate( substr( ENT, 2 ), '..', '+-' )
            if datatype( T, 'w' )   then  T = T + 0
                                    else  T = 0
         end                           /* otherwise test NMTOKEN: */
         otherwise   T = 10 * ( ENT = NMTOKEN( ENT ))
      end                              /* 0: bad token, 10: valid */
      if wordpos( T, '0 9 10 13 133' ) = 0   then  select
         when  T < 32               then  T = 0    /* 0000...001F */
         when  T < 127              then  nop
         when  T < 160              then  T = 0    /* 007F...009F */
         when  T < 55296            then  nop
         when  T < 57344            then  T = 0    /* D800...DFFF */
         when  T < 64976            then  nop
         when  T < 65008            then  T = 0    /* FDD0...FDFF */
         when  T // 65536 > 65533   then  T = 0    /* FFFE...FFFF */
         when  T <= 1114111         then  nop
         otherwise                        T = 0    /* if > 10FFFF */
      end
      if T = 0 then  exit GARBAGE( '&' || ENT )
   end

   DATA = arg( 1 )                  ;  POS = pos( '<', DATA )
   if POS = 0  then  return CONTROL( DATA )
               else  exit GARBAGE( DATA )

CONTROL: procedure expose (EXPO)       /* reject US-ASCII control */
   parse arg DATA
   N = verify( DATA, XCTL, 'M' )    ;  if N = 0 then  return 0
   N = c2x( substr( DATA, N, 1 ))   ;  exit GARBAGE( '0x' || N )

GARBAGE: procedure expose (EXPO)       /* report any other error: */
   say 'unexpected' arg( 1 ) 'near line' LINE
   return 1

UNWELL:  procedure expose (EXPO)       /* report invalid nesting: */
   X = 'unnmatched <' || arg( 1 ) || '> from line' arg( 2 )
   say X 'near line' LINE           ;  return 1

SUBSET:  procedure expose (EXPO)       /* check given DTD subset: */
   parse arg SRC                    ;  POS = pos( '<!', SRC )
   do while POS > 0
      TOP = left( SRC, POS - 1 )    ;  SRC = substr( SRC, POS + 2 )
      if TOP <> ''   then  call PARAM TOP

      if abbrev( SRC, '--' )  then  do
         parse var SRC '--' TOP '--' SRC
         POS = pos( '>', SRC )
         if POS = 0  then  exit GARBAGE( '<!--' TOP '--' SRC )
         call CONTROL TOP           ;  TOP = left( SRC, POS - 1 )
         if TOP <> ''   then  exit GARBAGE( '--' TOP '>' )
         SRC = substr( SRC, POS + 1 )
         POS = pos( '<!', SRC )     ;  iterate
      end

      parse var SRC TOP ' ' SRC
      if wordpos( TOP, 'ATTLIST ELEMENT ENTITY' ) > 0 then  do
         POS = pos( '>', SRC )
         if POS = 0  then  exit GARBAGE( '<!' || TOP SRC )
         TOP = left( SRC, POS - 1 ) ;  SRC = substr( SRC, POS + 1 )
         call CDATA TOP             ;  POS = pos( '<!', SRC )
      end
      else  exit GARBAGE( '<!' || TOP '(not implemented)' )
   end
   if SRC = '' then  return         ;  else  return PARAM SRC

PARAM:   procedure expose (EXPO)       /* accept parameter entity */
   parse arg DATA                   ;  DATA = strip( DATA )
   do forever
      parse var DATA X 2 P DATA     ;  N = length( P )
      if X <> '%' | N < 2                 then  leave
      X = right( P, 1 )             ;  P = left( P, N - 1 )
      if X <> ';' | ( P <> NMTOKEN( P ))  then  leave
      if DATA = ''                        then  return
   end
   exit GARBAGE( arg( 1 ) 'is no parameter entity' )

NMTOKEN: procedure expose (EXPO)       /* assume tags are tokens: */
   WORD = translate( arg( 1 ), 'XX99', ':_-.' )
   if datatype( left( WORD, 1 ), 'M' ) = 0
      then  exit GARBAGE( arg( 1 ) '- expected NMTOKEN' )

   do N = 2 to length( WORD )          /* letters, digits, ':_-.' */
      if datatype( substr( WORD, N, 1 ), 'A' ) = 0 then  leave N
   end N
   return left( arg( 1 ), N - 1 )

FINDME:  procedure expose (EXPO)       /* find next wanted string */
   parse arg WANT, TEXT             ;  WPOS = pos( WANT, TEXT )
   DOCT = ( WANT = ' [' )           ;  DPOS = 0
   if WANT = '=' | DOCT then  DPOS = pos( '>' , TEXT )
   select
      when  DPOS = 0    then  return WPOS DOCT || ',' || WANT
      when  WPOS = 0    then  return DPOS DOCT || ',' || '>'
      when  WPOS < DPOS then  return WPOS DOCT || ',' || WANT
      otherwise               return DPOS DOCT || ',' || '>'
   end
