# rexx-fan
*Stand-alone Rexx tools: ooRexx or Regina not limited to Windows NT*

[Rexx][R] is a script language used under IBM operating systems and by related products, e.g., [XEDIT](https://en.wikipedia.org/wiki/XEDIT), PC DOS and OS/2. Rexx has been ported to other platforms including Windows and Linux. Rexx is used as a macro language in, e.g., the XEDIT clones Kedit and [THE](https://en.wikipedia.org/wiki/The_Hessling_Editor).

As a macro language Rexx could be compared with [Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language)) or [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)), and as a programming language Rexx could be compared with [AWK](https://en.wikipedia.org/wiki/AWK) or [Python](https://en.wikipedia.org/wiki/Python_(programming_language)). Classic Rexx influenced [NetRexx](https://en.wikipedia.org/wiki/NetRexx), a dialect for the Java Virtual Machine, and [ooRexx](https://en.wikipedia.org/wiki/Object_REXX), an object oriented extension.

The programs in this repo are supposed to work in command line windows (`cmd.exe` shells) on Windows 2000 or later with *[ooRexx](https://www.oorexx.org/about.html)* or *[Regina](https://sourceforge.net/projects/regina-rexx/)*, and as long as they do not use special features such as hardlinks they could still/also work on OS/2 or Linux. Please check the usual suspects such as backslashes or semicolons instead of slashes or colons on Linux.

1. **[7b](https://github.com/frank-e/rexx-fan/blob/master/7b.rex)**: binary to 7b-format (7-bit) codec and spec., claiming to *better* than B64, for giggles.
2. **[checkmbr](https://github.com/frank-e/rexx-fan/blob/master/checkmbr.rex)**: `\\.\PHYSICALDRIVE`n, disk image ([MBR][M]), or unpartitioned [VBR](https://en.wikipedia.org/wiki/Volume_boot_record) floppy image.
2. **[cmpdel)](https://github.com/frank-e/rexx-fan/blob/master/cmpdel.rex)** and **[cmplink](https://github.com/frank-e/rexx-fan/blob/master/cmplink.rex)**: Compare directory trees SRC and DST, **del**ete or hard**link** identical SRC files.
2. **[ff)](https://github.com/frank-e/rexx-fan/blob/master/ff.rex)**: *FileFind*, slow as the Windows search unless directories are cached. [PC DOS 7](https://en.wikipedia.org/wiki/IBM_PC_DOS#7.00) [Norton](https://en.wikipedia.org/wiki/Norton_Utilities#Version_2.0) nostalgy.
2. **[imm](https://github.com/frank-e/rexx-fan/blob/master/imm.rex)** and **[say](https://github.com/frank-e/rexx-fan/blob/master/say.rex)**: Emulate KEDIT command `imm` or [Rexx][R] `say` for one-line scripts or expressions.
2. **[md5](https://github.com/frank-e/rexx-fan/blob/master/md5.rex)**: [MD5](https://en.wikipedia.org/wiki/MD5) test suite 2.1 for test vectors in various IETF RFCs, replacing WayBack [2.0][5], cf. [RFC 6151](https://tools.ietf.org/html/rfc6151).
2. **[rexxfat](https://github.com/frank-e/rexx-fan/blob/master/rexxfat.rex)**: Create [FAT12/16/32](https://en.wikipedia.org/wiki/File_Allocation_Table#Development) superfloppy ([no MBR][M])) or [VHD][V] (MBR) image files, supports [512e](https://en.wikipedia.org/wiki/Advanced_Format#512e).
2. **[rexxsort](https://github.com/frank-e/rexx-fan/blob/master/rexxsort.rex)**: See [manual][3] on *xyzzy*. The `KWIK` in [ygrep.rex](../master/ygrep.rex) etc. is a copy of the *treble QSort* here.
2. **[rxclip](https://github.com/frank-e/rexx-fan/blob/master/rxclip.rex)**: Copy to or paste from the clipboard, requires *ooRexx* with *RxWinSys.dll* `WSClipBoard()`.
2. **[rxshell](https://github.com/frank-e/rexx-fan/blob/master/rxshell.rex)** and the required **-rxshell** constants: *RxShell 3.3* with a vintage 2010 [manual][6] on *xyzzy*.
2. **[rxtime](https://github.com/frank-e/rexx-fan/blob/master/rxtime.rex)**: Measure the runtime of a specified command.
2. **[sparsify](https://github.com/frank-e/rexx-fan/blob/master/sparsify.rex)**: NTFS sparse files with `fsutil.exe` require admin rights (incl. self test).
2. **[stackget](https://github.com/frank-e/rexx-fan/blob/master/stackget.rex)**: Emulate Quercus [REXX/Personal](http://www.edm2.com/index.php/Personal_REXX) `stackget.exe` (only *ooRexx*, not yet ready for *Regina*).
2. **[svg2tiny](https://github.com/frank-e/rexx-fan/blob/master/svg2tiny.rex)** and **[svg2true](https://github.com/frank-e/rexx-fan/blob/master/svg2true.rex)**: Try to convert [SVG](https://commons.wikimedia.org/wiki/Help:SVG) to valid [SVG tiny or basic 1.1](https://www.w3.org/TR/2003/REC-SVGMobile-20030114/) with [rsvg-convert.exe](https://sourceforge.net/projects/tumagcc/).
2. **[today](https://github.com/frank-e/rexx-fan/blob/master/today.rex)**: List all files changed today `1 *`, *tomorrow* `0 *`, new videos this week `7 *.webm`, etc.
2. **[utf-8](https://github.com/frank-e/rexx-fan/blob/master/utf-8.rex)**: [UTF-8][U] de-/en-coders of OEM codepages [437](https://en.wikipedia.org/wiki/Code_page_437 "DOS US"), [819](https://en.wikipedia.org/wiki/ISO/IEC_8859-1 "Latin-1"), [858][8], [878](https://en.wikipedia.org/wiki/KOI8-R "KOI8-R"), [923](https://en.wikipedia.org/wiki/ISO/IEC_8859-15 "Latin-9"), and [1252][9] (incl. test suite).
2. **[utf-tab](https://github.com/frank-e/rexx-fan/blob/master/utf-tab.rex)**: Show magic codepoints for [UTF-16BE][B], UTF-16[LE](https://en.wikipedia.org/wiki/Endianness#Big-endian), [UTF-8][U], [UTF-4][4], and [UTF-1](https://en.wikipedia.org/wiki/UTF-1).
2. **[VHDclone](https://github.com/frank-e/rexx-fan/blob/master/VHDclone.rex)**: Copy static [VHD][V] with new UUID, timestamp, and creator, faster than `diskpart.exe`.
2. **[which](https://github.com/frank-e/rexx-fan/blob/master/which.rex)**: Oddly on Windows an ordinary **.bat** or rather **.cmd** script would be seriously tricky.
2. **[xlat](https://github.com/frank-e/rexx-fan/blob/master/xlat.rex)**: Convert [UTF-32](https://en.wikipedia.org/wiki/UTF-32), [UTF-16][B], or [UTF-8][U] to [UTF-4][4], or convert UTF-4 to UTF-8. Other UTFs rejected.
2. **[xmlcheck](https://github.com/frank-e/rexx-fan/blob/master/xmlcheck.rex)**: Check that an XML file is well-formed, report nesting level, ignore DTD subset details.
2. **[ygrep](https://github.com/frank-e/rexx-fan/blob/master/ygrep.rex)**: A `findstr.exe` wrapper for NT, the author is used to `fgrep` or an old OS/2 `ygrep.cmd`.

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
