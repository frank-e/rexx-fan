# rexx-fan
*Stand-alone Rexx tools: ooRexx or Regina not limited to Windows NT*

[Rexx](https://en.wikipedia.org/wiki/Rexx) is a script language used by IBM operating systems and related products, e.g., [XEDIT](https://en.wikipedia.org/wiki/XEDIT), PC DOS and OS/2. Rexx has been ported to other platforms including Windows and Linux. Rexx is used as a macro language in, e.g., the XEDIT clones Kedit and [THE](https://en.wikipedia.org/wiki/The_Hessling_Editor).

As a macro language Rexx could be compared with [Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language)) or [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)), and as a programming language Rexx could be compared with [AWK](https://en.wikipedia.org/wiki/AWK) or [Python](https://en.wikipedia.org/wiki/Python_(programming_language)). Classic Rexx influenced [NetRexx](https://en.wikipedia.org/wiki/NetRexx), a dialect for the Java virtual machine, and [ooRexx](https://en.wikipedia.org/wiki/Object_REXX), an object oriented extension.

The scripts in this repo are supposed to work in command line windows (`cmd.exe` shells) on Windows 2000 or later with *[ooRexx](https://www.oorexx.org/about.html)* or *[Regina](https://sourceforge.net/projects/regina-rexx/)*, and as long as they do not use special features such as hardlinks they could still/also work on OS/2 or Linux. Please check the usual suspects such as backslashes or semicolons instead of slashes or colons on Linux.

1. **cmpdel** and **cmplink**: Compare directory trees SRC and DST, **del**ete or hard**link** identical SRC files.
2. **ff**: *FileFind*, slow as the Windows search unless directories are cached. [PC DOS 7](https://en.wikipedia.org/wiki/IBM_PC_DOS#7.00) [Norton](https://en.wikipedia.org/wiki/Norton_Utilities#Version_2.0) nostalgy.
2. **imm** and **say**: Emulate KEDIT command `imm` or Rexx instruction `say` for one-line scripts/expressions.
2. **md5**: [MD5](https://en.wikipedia.org/wiki/MD5) test suite 2.1 for test vectors in various IETF RFCs, replacing WayBack [2.0](https://web.archive.org/web/20120918193421/http://omniplex.om.funpic.de/src/md5.cmd), cf. [RFC 6151](https://tools.ietf.org/html/rfc6151).
2. **rexxfat**: Create [FAT12/16/32](https://en.wikipedia.org/wiki/File_Allocation_Table#Development) superfloppy ([no MBR](https://en.wikipedia.org/wiki/Master_boot_record)) or [VHD](https://en.wikipedia.org/wiki/VHD_(file_format)) (MBR) image files, supports [512e](https://en.wikipedia.org/wiki/Advanced_Format#512e).
2. **rxclip**: Copy to or paste from the clipboard, requires *ooRexx* with *RxWinSys.dll* `WSClipBoard()`.
2. **rxshell** and the required **-rxshell** constants: *RxShell 3.3* with a vintage 2010 [manual](https://web.archive.org/web/20130730232350/http://omniplex.om.funpic.de/src/rxshell.htm) on WayBack.
2. **rxtime**: Measure the runtime of a specified command. 
2. **sparsify**: NTFS sparse files with `fsutil.exe` require admin rights (incl. self test).
2. **stackget**: Emulate Quercus [REXX/Personal](http://www.edm2.com/index.php/Personal_REXX) `stackget.exe` (only *ooRexx*, not yet ready for *Regina*).
2. **svg2tiny** and **svg2true**: Try to convert [SVG](https://commons.wikimedia.org/wiki/Help:SVG) to valid [SVG tiny or basic 1.1](https://www.w3.org/TR/2003/REC-SVGMobile-20030114/) with [rsvg-convert.exe](https://sourceforge.net/projects/tumagcc/).
2. **utf-8**: [UTF-8](https://en.wikipedia.org/wiki/UTF-8) de-/en-coders of OEM codepages [437](https://en.wikipedia.org/wiki/Code_page_437), [819](https://en.wikipedia.org/wiki/ISO/IEC_8859-1), [858](https://web.archive.org/web/20130522131229/http://omniplex.om.funpic.de/ibm850.htm#skipxml), [878](KOI8-R), [923](https://en.wikipedia.org/wiki/ISO/IEC_8859-15), and [1252](https://web.archive.org/web/20130522131229/http://omniplex.om.funpic.de/ibm850.htm#cp1004) (incl. test suite).
2. **utf-tab**: Show magic codepoints for [UTF-16BE](https://en.wikipedia.org/wiki/UTF-16), UTF-16[LE](https://en.wikipedia.org/wiki/Endianness#Big-endian), [UTF-8](https://en.wikipedia.org/wiki/UTF-8), [UTF-4](https://web.archive.org/web/20110813010254/http://omniplex.om.funpic.de/home/test/utf-4.xml), and [UTF-1](https://en.wikipedia.org/wiki/UTF-1).
2. **which**: Oddly on Windows an ordinary **.bat** or rather **.cmd** script would be seriously tricky.
2. **xlat**: Convert [UTF-32](https://en.wikipedia.org/wiki/UTF-32), [UTF-16](https://en.wikipedia.org/wiki/UTF-16), or [UTF-8](https://en.wikipedia.org/wiki/UTF-8) to [UTF-4](https://web.archive.org/web/20110813010254/http://omniplex.om.funpic.de/home/test/utf-4.xml), or convert UTF-4 to UTF-8. Other UTFs rejected.
2. **xmlceck**: Check that an XML file is well-formed, report nesting level, ignore DTD subset details. 
2. **ygrep**: A `findstr.exe` wrapper for NT, the author is used to `fgrep` or a lost OS/2 `ygrep.cmd`.

The name of this repo matches [rexx-fan](https://sourceforge.net/u/rexx-fan/profile) on [SourceForge](https://en.wikipedia.org/wiki/SourceForge). For older versions of these scripts check out [WayBack 2005](https://web.archive.org/web/20050505221501/http://frank.ellermann.bei.t-online.de/sources.htm#General), [2011](https://web.archive.org/web/20110102232137/http://home.claranet.de/xyzzy/sources.htm#General), and [2013](https://web.archive.org/web/20130522122606/http://omniplex.om.funpic.de/sources.htm#General).
