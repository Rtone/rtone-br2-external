# rtone-br2-external

rtone-br2-external is a Buildroot br2-external tree to generate embedded
Linux systems through cross-compilation.

## TL;DR;

This repository builds a firmware using [Buildroot] for the Raspberry Pi 4
Model B single-board computer (64-bit).

## REQUIREMENTS

Look at the [Buildroot user manual] System requirements chapter to install all
the bits required to use that repository.

## DOWNLOAD

Clone the tree:

	git clone https://github.com/Rtone/rtone-br2-external.git

And enter the sources:

	cd rtone-br2-external

## BUILD

Configure the firmware:

	make raspberrypi4_64_defconfig

And build it:

	make

It takes a while to cook the world, grab yourself a coffee or count the zeros
in `/dev/zero` until it finishes!

## TEST

Copy the firwmare to an SD-card:

	dd if=buildroot/output/images/sd-card.img of=/dev/mmcblk0

Insert the SD-card to the single-board computer, power it on, login as
**root**, run commands and poweroff the system, have fun!

## PATCHES

Sumbit patches at <https://github.com/Rtone/rtone-br2-external/pulls>

## BUGS

Report bugs at <https://github.com/Rtone/rtone-br2-external/issues>

## AUTHOR

Written by Gaël PORTAY *gael.portay@rtone.fr*

## COPYRIGHT

Copyright 2024 Gaël PORTAY

Copyright 2024 Rtone

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 2.1 of the License, or (at your option) any
later version.

[Buildroot user manual]: https://buildroot.org/downloads/manual/manual.html#requirement
[Buildroot]: https://buildroot.org/
