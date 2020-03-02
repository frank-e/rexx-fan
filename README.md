# rexx-fan
*Stand-alone Rexx tools: ooRexx or Regina not limited to Windows NT*

[Rexx][R] is a script language used under IBM operating systems and by related products, e.g., [XEDIT](https://en.wikipedia.org/wiki/XEDIT), PC DOS and OS/2. Rexx has been ported to other platforms including Windows and Linux. Rexx is used as a macro language in, e.g., the XEDIT clones Kedit and [THE](https://en.wikipedia.org/wiki/The_Hessling_Editor).

As a macro language Rexx could be compared with [Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language)) or [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)), and as a programming language Rexx could be compared with [AWK](https://en.wikipedia.org/wiki/AWK) or [Python](https://en.wikipedia.org/wiki/Python_(programming_language)). Classic Rexx influenced [NetRexx](https://en.wikipedia.org/wiki/NetRexx), a dialect for the Java Virtual Machine, and [ooRexx](https://en.wikipedia.org/wiki/Object_REXX), an object oriented extension.

The programs in this repo are supposed to work in command line windows (`cmd.exe` shells) on Windows 2000 or later with *[ooRexx](https://www.oorexx.org/about.html)* or *[Regina](https://sourceforge.net/projects/regina-rexx/)*, and as long as they do not use special features such as hardlinks they could still/also work on OS/2 or Linux. Please check the usual suspects such as backslashes or semicolons instead of slashes or colons on Linux.

1. **checkmbr**: `\\.\PHYSICALDRIVE`n, disk image ([MBR][M]), or unpartitioned [VBR](https://en.wikipedia.org/wiki/Volume_boot_record) floppy image.
2. **cmpdel** and **cmplink**: Compare directory trees SRC and DST, **del**ete or hard**link** identical SRC files.
2. **ff**: *FileFind*, slow as the Windows search unless directories are cached. [PC DOS 7](https://en.wikipedia.org/wiki/IBM_PC_DOS#7.00) [Norton](https://en.wikipedia.org/wiki/Norton_Utilities#Version_2.0) nostalgy.
2. **imm** and **say**: Emulate KEDIT command `imm` or [Rexx][R] `say` for one-line scripts or expressions.
2. **md5**: [MD5](https://en.wikipedia.org/wiki/MD5) test suite 2.1 for test vectors in various IETF RFCs, replacing WayBack [2.0][5], cf. [RFC 6151](https://tools.ietf.org/html/rfc6151).
2. **rexxfat**: Create [FAT12/16/32](https://en.wikipedia.org/wiki/File_Allocation_Table#Development) superfloppy ([no MBR][M])) or [VHD][V] (MBR) image files, supports [512e](https://en.wikipedia.org/wiki/Advanced_Format#512e).
2. **rexxsort**: See [manual][3] on *xyzzy*. The `KWIK` in [ygrep.rex](../master/ygrep.rex) etc. is a copy of the *treble QSort* here.
2. **rxclip**: Copy to or paste from the clipboard, requires *ooRexx* with *RxWinSys.dll* `WSClipBoard()`.
2. **rxshell** and the required **-rxshell** constants: *RxShell 3.3* with a vintage 2010 [manual][6] on *xyzzy*.
2. **rxtime**: Measure the runtime of a specified command. 
2. **sparsify**: NTFS sparse files with `fsutil.exe` require admin rights (incl. self test).
2. **stackget**: Emulate Quercus [REXX/Personal](http://www.edm2.com/index.php/Personal_REXX) `stackget.exe` (only *ooRexx*, not yet ready for *Regina*).
2. **svg2tiny** and **svg2true**: Try to convert [SVG](https://commons.wikimedia.org/wiki/Help:SVG) to valid [SVG tiny or basic 1.1](https://www.w3.org/TR/2003/REC-SVGMobile-20030114/) with [rsvg-convert.exe](https://sourceforge.net/projects/tumagcc/).
2. **today**: List all files changed today `1 *`, *tomorrow* `0 *`, new videos this week `7 *.webm`, etc.
2. **utf-8**: [UTF-8][U] de-/en-coders of OEM codepages [437](https://en.wikipedia.org/wiki/Code_page_437 "DOS US"), [819](https://en.wikipedia.org/wiki/ISO/IEC_8859-1 "Latin-1"), [858][8], [878](https://en.wikipedia.org/wiki/KOI8-R "KOI8-R"), [923](https://en.wikipedia.org/wiki/ISO/IEC_8859-15 "Latin-9"), and [1252][9] (incl. test suite).
2. **utf-tab**: Show magic codepoints for [UTF-16BE][B], UTF-16[LE](https://en.wikipedia.org/wiki/Endianness#Big-endian), [UTF-8][U], [UTF-4][4], and [UTF-1](https://en.wikipedia.org/wiki/UTF-1).
2. **VHDclone**: Copy static [VHD][V] with new UUID, timestamp, and creator, faster than `diskpart.exe`. 
2. **which**: Oddly on Windows an ordinary **.bat** or rather **.cmd** script would be seriously tricky.
2. **xlat**: Convert [UTF-32](https://en.wikipedia.org/wiki/UTF-32), [UTF-16][B], or [UTF-8][U] to [UTF-4][4], or convert UTF-4 to UTF-8. Other UTFs rejected.
2. **xmlcheck**: Check that an XML file is well-formed, report nesting level, ignore DTD subset details. 
2. **ygrep**: A `findstr.exe` wrapper for NT, the author is used to `fgrep` or an old OS/2 `ygrep.cmd`.

The name of this repo matches [rexx-fan](https://sourceforge.net/u/rexx-fan/profile) on [SF](https://en.wikipedia.org/wiki/SourceForge "SourceForge"). For older versions of these programs try *xyzzy* [2005][0], [2011][1], or [2013][2].

[M]: https://en.wikipedia.org/wiki/Master_boot_record (Master Boot Record)
[B]: https://en.wikipedia.org/wiki/UTF-16
[R]: https://en.wikipedia.org/wiki/Rexx
[U]: https://en.wikipedia.org/wiki/UTF-8 
[V]: https://en.wikipedia.org/wiki/VHD_(file_format) (Virtual Hard Disk)
[0]: https://web.archive.org/web/20050505221501/http://frank.ellermann.bei.t-online.de/sources.htm#General (purl.net/xyzzy/sources.htm)
[1]: https://web.archive.org/web/20110102232137/http://home.claranet.de/xyzzy/sources.htm#General (purl.net/xyzzy/sources.htm)
[2]: https://purl.net/xyzzy/sources.htm#General
[3]: https://purl.net/xyzzy/rexxsort.htm
[4]: https://purl.net/xyzzy/home/test/utf-4.xml
[5]: https://purl.net/xyzzy/src/md5.cmd
[6]: https://purl.net/xyzzy/src/rxshell.htm
[8]: https://purl.net/xyzzy/ibm850.htm#skipxml (PC-Multilingual-850+euro)
[9]: https://purl.net/xyzzy/ibm850.htm#cp1004 (windows-1252)
