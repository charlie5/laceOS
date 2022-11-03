# laceOS

An Archlinux operating system tailored for developing software in the Ada and SPARK languages.


_______________
## Requirements

|               |             | 
|---------------|:-----------:|
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
| BIOS:         | UEFI        |
| Architecture: | x86_64      |
| RAM:          |  4+ GiB     |
| Disk:         | 32+ GiB     |


________________
## OS Components

|               |                | 
|---------------|:--------------:|
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
| Display Server:      | X.Org   |
| Desktop Environment: | XFCE4   |
| Window Manager:      | XFWM    |
| Display Manager:     | LightDM |


_______________
## Ada Projects

- adacurses
- ada_language_server
- ada-libfswatch
- ada_spawn
- ada-web-server
- ahven
- alire
- aunit
- florist
- gcc-ada       (v12.2.0)
- gcc-ada-debug (v12.2.0)
- gnatcoll-core
- gnatcoll-db2ada
- gnatcoll-gmp
- gnatcoll-gnatinspect
- gnatcoll-iconv
- gnatcoll-lzma
- gnatcoll-omp
- gnatcoll-postgres
- gnatcoll-python2
- gnatcoll-readline
- gnatcoll-sql
- gnatcoll-sqlite
- gnatcoll-syslog
- gnatcoll-xref
- gnatcoll-zlib
- gnatdoc
- gnatstudio
- gnatsymbolize
- gprbuild
- gtkada
- ini_file_manager
- inotify-ada
- langkit
- libadalang
- libadalang-tools
- libgpr
- libvss
- polyorb
- sdlada
- sphinxcontrib-adadomain
- xmlada


_____________
## Installing

Download a pre-built 
[ISO](https://github.com/charlie5/laceOS/raw/master/laceOS-0.0-x86_64.iso.torrent) using a bittorrent client.

As the current initial version is an alpha, please test/trial in a virtual machine until a stable version is released.

### Depends on:

- Qemu
- Virt-Manager

The installer is currently console based, albeit in a graphical desktop environment (Xfce4). A graphical installer is pending.

- Create a Qemu virtual machine via virt-manager.
- Configure the machine to boot via UEFI 
  (see [here](https://ostechnix.com/enable-uefi-support-for-kvm-virtual-machines-in-linux/#boot-virtual-machines-with-uefi)).
- Attach the laceOS ISO file to the virtual machines cdrom.
- Start the virtual machine.
- Double click on the 'Install laceOS' desktop icon.

The installer will only accept legal hostnames, usernames and passwords. The user will be prompted again if any are illegal. 
The installer will use an entire disk as the installation target.


_______________
## Post-Install

To use a Nvidia GPU:

$ pikaur -S nvidia-dkms
$ sudo reboot

If any problems result, try using 'nvidia-xconfig' to generate an X11 configuration file.

$ sudo nvidia-xconfig


___________
## Feedback

Comments, suggestions and critiques are very welcome, either via the github project 'Issues' section or IRC to 'charlie5' on #ada channel
 at 'irc.libera.chat'.


___________
## Building

Currently the ISO build system uses several hard-coded folder paths. This will be corrected in the next release. For the moment please use
the pre-built install ISO.


### Depends on:

- Archlinux
- Ada 2012
- [Lace Project](https://github.com/charlie5/lace)
- [aShell Project](https://github.com/charlie5/aShell)
- An Internet Connection

Install the dependencies and then ...


$ cd laceOS/applet/lace-live<br>
$ ./build_iso.sh


The resulting ISO will be created in 'laceOS/applet/lace-live/out'.

Should the build fail (due to a slow internet connnection) or is otherwise interrupted, simply restart the build. Do ***not*** use the
'rid_build.sh" script until after the build completes successfully (see [here](https://wiki.archlinux.org/title/Archiso#Removal_of_work_directory)).
