# Famicom Disk BASIC

https://github.com/TakuikaNinja/FC-DiskBASIC

For the older version without disk saving, see the `vol2` branch: https://github.com/TakuikaNinja/FC-DiskBASIC/tree/vol2

This is an unofficial Famicom Disk System (FDS) port of Family BASIC v2.1A, originally documented as a manual process in magazines such as バックアップ活用テクニック (Backup Utilization Techniques) Part 8 and ファミコン改造マニュアル (Famicom Hacking/Modding Manual) Vol. 2 & 3. I2 would later release the Disk BASIC Generator Kit for their Souseiki Fammy to automate the process and provide additional features.

The original process listed in バックアップ活用テクニック Part 8 involved:
1. Constructing custom hardware to interface between the Family BASIC cartridge, the FDS, and a PC6601SR
2. Dumping Family BASIC to disk using custom programs (PC & FDS)
3. Editing the program data on the disk using the PC

Due to the specific hardware requirements, this method is currently considered as impractical to replicate. In fact, ファミコン改造マニュアル cites this as the reason for creating the newer process. The process listed in ファミコン改造マニュアル Vol. 2 & 3 involved:
1. Dumping Family BASIC to cassette tape using custom BASIC programs
2. Loading the cassette tape data and saving it to disk using a custom disk program
3. Editing the program data on the disk using Tonkachi Editor

This is currently considered to be the more practical method to replicate, since only Famicom software/peripherals are required. Modern devices can replace the physical cassette tape and disks. The BASIC listings and disk programs used for this process have been obtained and will eventually be archived separately from this repository.

This repository simplifies and automates the recreation process on modern computers by directly modifying an existing ROM dump and constructing an FDS disk image from it.

## Features

### Pros

- Boots straight into Game BASIC, as long as the keyboard is connected (no need to hold the T key on reset)
- 8126 bytes of program memory (almost double that of v3.0!)
- New `BGTOOL` command to instantly enter the graphics editor (replaces `SYSTEM` command, press `ESC -> STOP` to return to BASIC)
- Disk saving via the included save utility. (see instructions below)
- CHR data can be edited on the disk (typically using I2's Hokusai or Jingorou)
- CHR-RAM can potentially be edited in real-time (e.g. within machine code programs)
- Cassette tape I/O should still work
- The novelty of Disk BASIC (on par with other computers of the era)

### Cons

- Limited to v2.1A feature set

## Building

The Makefile in this root directory builds `fcbasic.fds` using the [CC65 suite](https://cc65.github.io/). The following files must be supplied by the user: 
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
- In older versions, `prg.bin` is the intermediary patched program code.
- Even older versions of this repository used [Flips](https://github.com/Alcaro/Flips) (to modify the program data with a BPS file) and [ASM6f](https://github.com/freem/asm6f) (to assemble the disk image). In this case, `fcbasic.nes` is the intermediary patched file used to construct the CHR & PRG files on the disk image instead. It is not intended nor expected to execute correctly on Famicom or NES hardware/emulators.

### Save Utility

The required save utility has been provided as a disassembly in the `save_utility` directory. The Makefile there will build `save_utility.fds`. The FDS BIOS license screen message (`kyodaku.bin`) used for Disk BASIC is also required to build this program - it will reuse the file placed in the root directory.

## Disk Saving

Note: If an emulator does not support switching arbitrary disks without power-cycling, concatenate Disk BASIC and the save utility to form a two-sided disk.

The following steps are used to save BASIC programs to disk:
1. Create a program in Disk BASIC. 
    1. Entering `NEW` will *erase* the current program, which allows save data to be wiped.
2. Soft-reset the system by pressing the console's reset button, or by entering `CALL &HEE24` (the FDS BIOS reset handler).
3. Enter `POKE &H102,0`, then swap to the save utility.
4. Soft-reset the system a second time. This will load the save utility while preserving the data to be saved.
5. Following the prompts in the save utility, eject the disk, then swap back to Disk BASIC. Wait while the data is saved onto disk.
6. Once the eject prompt reappears, you may now eject the disk and power off the system.
    1. For drive emulators such as the [FDSKey](https://github.com/ClusterM/fdskey), ensure the disk image has finished saving to the microSD card before ejecting the disk or powering off the system.
7. The saved program will now be automatically be loaded into Disk BASIC on future startups.

## Screenshots

![Startup screen](/img/fcbasic_000.png)
![Example program](/img/fcbasic_001.png)

## Attributions

Family BASIC/NS-HUBASIC (C) 1984 Nintendo/Sharp/Hudson. 

ファミコン改造マニュアル Vol.2 & 3 Disk BASIC
- Article Author: 熊沢文幸 (Fumiyuki Kumazawa)
- Editor: 丹治佐一 (Saichi Tanji)
- Published: 1988-02, 1988-07
- Publisher: 三才ブックス (Sansai Books)

This project is purely for preservation, demonstration, and educational purposes.

## Acknowledgements

- Thanks to Enri, who provided Japanese documentation for the recreation process: http://cmpslv3.stars.ne.jp/Konjo/027/027.htm
- Forum discussion: https://forums.nesdev.org/viewtopic.php?t=25171
- Mesen2 (https://www.mesen.ca/) was used for testing.

