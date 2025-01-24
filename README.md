# Famicom Disk BASIC

https://github.com/TakuikaNinja/FC-DiskBASIC

This is an unofficial Famicom Disk System (FDS) port of Family BASIC v2.1A, originally documented as a manual process in magazines such as バックアップ活用テクニック (Backup Utilization Techniques) and ファミコン改造マニュアル (Famicom Hacking/Modding Manual). I2 would later release the Disk BASIC Generator Kit for their Souseiki Fammy to automate the process and provide additional features.

The original process involved:
1. Dumping Family BASIC to cassette tape using a custom BASIC program
2. Loading the cassette tape data and saving it to disk using a custom disk program
3. Editing the program data on the disk using Tonkachi Editor

The specifics of this process, such as the custom BASIC & disk programs, are yet to be documented.

This repository simplifies and automates the recreation process on modern computers by directly modifying an existing ROM dump and constructing an FDS disk image from it.

## Features

### Pros

- Boots straight into Game BASIC, as long as the keyboard is connected (no need to hold the T key on reset)
- 8126 bytes of program memory (almost double that of v3.0!)
- New `BGTOOL` command to instantly enter the graphics editor (replaces `SYSTEM` command, press `ESC -> STOP` to return to BASIC)
- CHR data can be edited on the disk (typically using I2's Hokusai or Jingorou)
- CHR-RAM can potentially be edited in real-time (e.g. within machine code programs)
- Cassette tape I/O should still work
- The novelty of Disk BASIC (on par with other computers of the era)

### Cons

- No disk I/O (only added in later magazine issues + I2 version, yet to be documented)
- Limited to v2.1A feature set

## Building

The Makefile builds `fcbasic.fds` using the [CC65 suite](https://cc65.github.io/). The following files must be supplied by the user: 
- Dump of Family BASIC v2.1A, with iNES/NES2.0 header. (see below)
- FDS BIOS license screen message. (`kyodaku.bin`)

These files are not provided by this repo for obvious legal reasons. The required dump of Family BASIC v2.1A is the following: 

```
Database match: Family BASIC (Japan) (Rev 2)
Database: No-Intro: Nintendo Entertainment System (v. 20210216-231042)
File SHA-1: 0E3C374E7185067A1EBB4422CC12CF08C8D8C2D6
File CRC32: 4E3A38EA
ROM SHA-1: 8E90D9A6A6090307A7E408D1C1704D09BA8F94FC
ROM CRC32: 895037BC
```

Notes:
- `prg.bin` is the intermediary patched program code.
- Older versions of this repository used [Flips](https://github.com/Alcaro/Flips) (to modify the program data with a BPS file) and [ASM6f](https://github.com/freem/asm6f) (to assemble the disk image). In this case, `fcbasic.nes` is the intermediary patched file used to construct the CHR & PRG files on the disk image instead. It is not intended nor expected to execute correctly on Famicom or NES hardware/emulators.

## Screenshots

![Startup screen](/img/fcbasic_000.png)
![Example program](/img/fcbasic_001.png)

## Acknowledgements

Family BASIC/NS-HUBASIC (C) 1984 Nintendo/Sharp/Hudson
This project is purely for preservation, demonstration, and educational purposes.

- Kudos to the magazine contributors, editors, and publishers who originally created the port and documented the process.
- This project was made possible by Enri, who provided Japanese documentation for the recreation process: http://cmpslv3.stars.ne.jp/Konjo/027/027.htm
- Forum discussion: https://forums.nesdev.org/viewtopic.php?t=25171
- Mesen (https://www.mesen.ca/) was used for testing.

