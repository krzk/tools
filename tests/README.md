Testsuite for Linux kernel, Exynos SoC and Exynos-based boards.

It is being run on https://krzk.eu on my boards for testing current Linux
kernel development.

# Usage

Just run each script independently or entire test suite as root:

	sudo ./all-odroidhc1.sh
	sudo ./audio.sh`

# Requirements

Mostly the tests use standard Linux kernel interfaces (/sys, /proc
and /sys/kernel/debug), but some scripts call external programs.

List of requirements (Arch Linux packages):

* alsa-utils
* coreutils
* cryptsetup
* gzip
* iputils
* kmod
* net-tools
* udev
* usbutils
* util-linux

Tested on Arch ARM Linux but should be distro-independent.
