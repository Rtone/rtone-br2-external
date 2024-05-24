#!/bin/bash
#
# Copyright 2023-2024 Gaël PORTAY
#           2023-2024 Rtone
#
# SPDX-License-Identifier: LGPL-2.1-only
#

# An implementation of a RAUC custom bootloader backend for the Raspberry Pi
# firmware.
#
# https://rauc.readthedocs.io/en/latest/integration.html#custom
#
# It uses the optional configuration file autoboot.txt in conjonction with the
# feature tryboot to follow the update flow for A/B booting example defined in
# the online documentation.
#
# https://www.raspberrypi.com/documentation/computers/config_txt.html#autoboot-txt
# https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#fail-safe-os-updates-tryboot
# https://www.raspberrypi.com/documentation/computers/config_txt.html#example-update-flow-for-ab-booting

set -e

warning() {
	echo "Warning: $*" >&2
}

error() {
	echo "Error: $*" >&2
}

# Trivial .ini-like syntax parser.
#
#	[section]
#	key=value
#	...
#
# Parse the given file and set every section's key-value pairs to variables.
# It sets bash arrays to list sections and every section's keys.
#
# See:
#  - The bash array INI holds the sections defined in the file.
#  - The bash array INI__<section> holds the <key>s defined in the <section>.
#  - The variable INI__<section>__<key> holds the <key>'s <value>.
#
# Example:
#
#	$ cat /boot/autoboot.txt
# 	[all]
# 	tryboot_a_b=1
# 	boot_partition=2
# 	[tryboot]
# 	boot_partition=3
#
#	$ source_file /boot/autoboot.txt
#
#	$ echo "${INI[@]}"
#	all tryboot
#
#	$ echo "${INI__ALL[@]}"
#	btryboot_a_b boot_partition
#
#	$ echo "${INI__TRYBOOT[@]}"
#	boot_partition
#
#	$ echo "$INI__ALL__TRYBOOT_A_B"
#	1
#
#	$ echo "$INI__ALL__BOOT_PARTITION"
#	2
#
#	$ echo "$INI__TRYBOOT__BOOT_PARTITION"
#	3
#
source_file() {
	local __s
	local __p
	local __v

	unset INI "${!INI@}"
	mapfile -t lines <"$1"
	for line in "${lines[@]}"
	do
		if [[ "$line" =~ ^\[(.*)\]$ ]]
		then
			__s="${BASH_REMATCH[1]}"
			__s="${__s//./_}"
			__s="${__s//-/_}"
			eval "INI+=('${BASH_REMATCH[1]}')"
		elif [[ "$line" =~ ^([A-Za-z0-9_-]+)=(.*)$ ]]
		then
			__p="${BASH_REMATCH[1]}"
			__p="${__p//./_}"
			__p="${__p//-/_}"
			__v="${BASH_REMATCH[2]}"
			eval "INI__${__s^^}__${__p^^}='$__v'"
			eval "INI__${__s^^}+=('${BASH_REMATCH[1]}')"
		fi
	done
}

# Output the device's partition number of the given device using the sysfs.
#
# Examples:
#
#	$ device_partition /dev/sda1
#	1
#
#	$ device_partition /dev/mmcblk0p2
#	2
#
device_partition() {
	local dev

	dev="$(readlink -f "$1")"
	cat "/sys/class/block/${dev##*/}/partition"
}

# Output the bootname's slot of the given boot partition number using the RAUC
# system.conf file.
#
# Examples:
#
#	$ cat /etc/rauc/system.conf
#	(...)
# 	[slot.boot.0]
# 	device=/dev/mmcblk0p2
# 	parent=A
#	(...)
#
# 	[slot.boot.1]
# 	device=/dev/mmcblk0p3
# 	parent=B
#	(...)
#
# 	[slot.rootfs.0]
# 	device=/dev/mmcblk0p5
# 	bootname=A
#	(...)
#
# 	[slot.rootfs.1]
# 	device=/dev/mmcblk0p6
# 	bootname=B
#	(...)
#
#	$ get_slot 1
#	/etc/rauc/system.conf: 1: No such boot_partition
#
#	$ get_slot 2
#	A
#
#	$ get_slot 3
#	B
#
get_slot() {
	local i

	source_file /etc/rauc/system.conf
	for i in "${INI[@]}"
	do
		local partition
		local bootname
		local v

		if ! [[ "$i" =~ ^slot\. ]]
		then
			continue
		fi

		v="$i"
		v="${v//./_}"
		v="${v//-/_}"
		eval "device=\$INI__${v^^}__DEVICE"
		eval "parent=\$INI__${v^^}__PARENT"

		if ! partition="$(device_partition "$device")" ||
		   [[ "$partition" != "$1" ]] ||
		   [[ ! "$parent" ]]
		then
			continue
		fi

		v="slot.$parent"
		v="${v//./_}"
		v="${v//-/_}"
		eval "bootname=\$INI__${v^^}__BOOTNAME"
		if [[ ! "$bootname" ]]
		then
			warning "$parent: bootname: No such property"
			continue
		fi

		echo "$bootname"
		unset INI "${!INI@}"
		return
	done

	error "/etc/rauc/system.conf: $1: No such boot_partition"
	unset INI "${!INI@}"
	return 1
}

# Set the oneshot reboot flag to cause the firmware to run tryboot at next
# reboot.
#
# The firmware uses the boot_partition defined in the [tryboot] section and it
# loads the alternate configuration file tryboot.txt instead of config.txt at
# next boot.
#
# https://www.raspberrypi.com/documentation/computers/config_txt.html#the-tryboot-filter
#
# Note: It is equivalent to run `sudo reboot "0 tryboot"` at the exception the
# system does not reboot.
#
# https://github.com/raspberrypi/linux/commit/777a6a08bcf8f5f0a0086358dc66d8918a0e1c57
#
# Example:
#
#	$ set_primary_temporary
# 	0x0000001c 0x80000000 0x00038064 0x00000004 0x80000004 0x00000000 0x00000000
#
# 	$ vcmailbox 0x00030064 4 0 0
# 	0x0000001c 0x80000000 0x00030064 0x00000004 0x80000004 0x00000001 0x00000000
#
set_primary_temporary() {
	vcmailbox 0x00038064 4 0 1
}

# Swap the boot_partition configurations in autoboot.txt to cause the firmware
# to use the boot_partition that is defined in the [tryboot] section as the
# default boot_partition.
#
# https://www.raspberrypi.com/documentation/computers/config_txt.html#example-update-flow-for-ab-booting
#
# Example:
#
#	$ cat /boot/autoboot.txt
# 	[all]
# 	tryboot_a_b=1
# 	boot_partition=2
# 	[tryboot]
# 	boot_partition=3
#
#	$ set_primary_persistent
#
#	$ cat /boot/autoboot.txt
# 	[all]
# 	tryboot_a_b=1
# 	boot_partition=3
# 	[tryboot]
# 	boot_partition=2
#
set_primary_persistent() {
	local tryboot_boot_partition
	local all_boot_partition

	source_file /boot/autoboot.txt
	all_boot_partition="$INI__ALL__BOOT_PARTITION"
	tryboot_boot_partition="$INI__TRYBOOT__BOOT_PARTITION"

	sed -e "/^boot_partition=$all_boot_partition/s,=.*,_tmp=$tryboot_boot_partition," \
	    -e "/^boot_partition=$tryboot_boot_partition/s,=.*,_tmp=$all_boot_partition," \
	    -e "s,boot_partition_tmp=,boot_partition=," \
	    /boot/autoboot.txt >/boot/autoboot.txt.tmp

	mv /boot/autoboot.txt{.tmp,}
}

# RAUC custom bootloader backend interface
#
# https://rauc.readthedocs.io/en/latest/integration.html#custom-bootloader-backend-interface

# Output "good":
#  - if the given slot is the primary slot, or
#  - if the given slot is **NOT** the primary slot **AND** the reboot flag is
#    set.
#
# Output "bad" otherwise (i.e. if the given slot is **NOT** the primary slot
# **AND** the reboot flag is unset).
#
# Note: The other slot (i.e. the non-boot'ed slot) is marked as "bad" since its
# status is unknown and no persistent marker is used. However, it is considered
# "good" if the oneshot reboot flag is set.
#
# Note 2: The file tryboot.txt is **NOT** used as the persistent status marker
# for the slot. Its presence (or its absence) would indicate the slot is "bad"
# (or "good") in the future; deeper testing is needed to rule this behaviour.
#
# Note 3: The boot partitions are untouched for safety reasons even though they
# would not if the kernel is updated; the kernel is part of the boot partition,
# and its modules are part of the root filesystem. As a consequence, a kernel
# update implies to update the kernel image in the boot partition to keep it
# synced with its modules in the root partition.
#
get_state() {
	local slot

	if ! partition="$(fdtget /sys/firmware/fdt /chosen/bootloader partition)"
	then
		error "partition: Cannot get boot partition"
		return 1
	fi

	if ! slot="$(get_slot "$partition")"
	then
		error "Cannot get booted slot"
		return 1
	fi

	if [[ "$1" == "$slot" ]]
	then
		echo good
		return
	fi

	if ! tryboot="$(fdtget /sys/firmware/fdt /chosen/bootloader tryboot)"
	then
		error "tryboot: Cannot get reboot flag"
		return 1
	fi

	if [[ "$tryboot" -eq 1 ]]
	then
		echo good
		return
	fi

	# status is unknwon
	echo bad
}

# Set the other slot as primary:
#  - if the given slot is the primary slot and the given state is "bad", or
#  - if the given slot is **NOT** the primary slot **AND** the state is "good".
#
# Do nothing otherwise.
set_state() {
	local primary
	local tryboot

	if ! primary="$(get_primary)"
	then
		error "Cannot get primary slot"
		return 1
	fi

	# Mark the primary slot as bad: set the other slot as primary.
	if [[ "$1" == "$primary" ]] && [[ "$2" == bad ]]
	then
		# Commit [tryboot] boot_partition to [all]
		set_primary_persistent
		return
	fi

	# Mark the other slot as good: set the other slot as primary.
	if [[ "$1" != "$primary" ]] && [[ "$2" == good ]]
	then
		# Commit [tryboot] boot_partition to [all]
		set_primary_persistent
		return
	fi
}

# Output the parent bootname's slot of the boot_partition set in the section
# [all] of the file autoboot.txt.
#
# Note: The boot_partition device **MUST** be defined in system.conf and it
# **MUST** be part of the slot group; the slot for the boot partition is not
# bootname'd but it is parent'ed to the slot for the root partition instead.
#
# https://rauc.readthedocs.io/en/latest/integration.html#grouping-slots
#
# Important: the Raspberry Pi firmware tells the boot'ed partition number but
# it says no word about the boot'ed device (i.e. it says ~~/dev/mmcblk0p~~1).
get_primary() {
	local boot_partition
	local partition
	local bootname
	local device
	local i
	local v

	source_file /boot/autoboot.txt
	boot_partition="$INI__ALL__BOOT_PARTITION"

	source_file /etc/rauc/system.conf
	for i in "${INI[@]}"
	do
		if ! [[ "$i" =~ ^slot\. ]]
		then
			continue
		fi

		v="$i"
		v="${v//./_}"
		v="${v//-/_}"
		eval "device=\$INI__${v^^}__DEVICE"
		eval "parent=\$INI__${v^^}__PARENT"

		if ! partition="$(device_partition "$device")" ||
		   [[ "$partition" != "$boot_partition" ]] ||
		   [[ ! "$parent" ]]
		then
			continue
		fi

		v="slot.$parent"
		v="${v//./_}"
		v="${v//-/_}"
		eval "bootname=\$INI__${v^^}__BOOTNAME"
		if [[ ! "$bootname" ]]
		then
			warning "$parent: bootname: No such property"
			continue
		fi

		echo "$bootname"
		return
	done

	error "/etc/rauc/system.conf: $boot_partition: No such boot_partition"
	return 1
}

# Set the primary slot either persistently in the static file autoboot.txt if
# it is the boot'ed slot or temporarily via the tryboot reboot flag otherwise.
set_primary() {
	local tryboot

	if ! primary="$(get_primary)"
	then
		error "Cannot get primary slot"
		return 1
	fi

	if [[ "$1" != "$primary" ]]
	then
		set_primary_temporary
		return
	fi

	# Set the other slot as primary slot.
	if ! tryboot="$(fdtget /sys/firmware/fdt /chosen/bootloader tryboot)"
	then
		error "tryboot: Cannot get reboot flag"
		return 1
	fi

	if [[ "$tryboot" -eq 1 ]]
	then
		# Commit [tryboot] boot_partition to [all]
		set_primary_persistent
		return
	fi
}

if [ "$1" = "get-state" ]
then
	shift
	get_state "$@"
elif [ "$1" = "set-state" ]
then
	shift
	set_state "$@"
elif [ "$1" = "get-primary" ]
then
	shift
	get_primary "$@"
elif [ "$1" = "set-primary" ]
then
	shift
	set_primary "$@"
elif [ "$1" = "get-current" ]
then
	shift
	get_current "$@"
fi
