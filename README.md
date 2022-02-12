# `tiger.sh` and `leopard.sh`

Package managers for PowerPC Macs running OS X Tiger (10.4) and Leopard (10.5), written in Bash 😱

See [tigersh/README.md](tigersh/README.md) and [leopardsh/README.md](leopardsh/README.md).


## Binary package support

I build pre-compiled binary packages optimized for the following platforms:

|         | G3  | G4  | G4e | G5 (32-bit) | G5 (64-bit) |
| ------- |:---:|:---:|:---:|:---:        |:---:        |
| Tiger   | ✅  | ✅  |  ✅  | ✅          | ✅          |
| Leopard |     |     |  ✅  | ✅          | ✅          |

The above processors can be understood as the following gcc flags:

- G3: `-mcpu=750`
- G4: `-mcpu=7400`
- G4e: `-mcpu=7450`
- G5 (32-bit): `-mcpu=970 -m32`
- G5 (64-bit): `-mcpu=970 -m64`


## Project goals

- Simplicity / hackability / conceptual flatness.

The problem with most package managers is that they have a very high learning curve for contributing / hacking.

Tiger.sh and Leopard.sh will take the opposite approach: the installation of a package is encompassed entirely by two Bash scripts:
- the orchestrator script: `tiger.sh` or `leopard.sh`
- the package-specific script: `install-foo-1.0.sh`

Tiger.sh and Leopard.sh are spritual brethren to the [Linux From Scratch](https://www.linuxfromscratch.org/) project.

Would you like to hack on some of the installer scripts yourself?  It is as simple as:

```
$ cd
$ curl -L https://github.com/cellularmitosis/leopard.sh/archive/refs/heads/main.tar.gz | gunzip | tar x
$ export TIGERSH_MIRROR=file://$HOME/leopard.sh-main/tigersh
$ # or, for leopard:
$ export LEOPARDSH_MIRROR=file://$HOME/leopard.sh-main/leopardsh
```

Bam, you're now running entirely from your self-contained copy of the project.

In fact, as long as you drop any needed source tarballs into `~/Downloads` before running `tiger.sh`,
you're now also completely offline-capable.


## Non-goals

- Supporting Intel Macs


## Possible future work

### 10.3 / 10.2

If I really get serious with this rabbit-hole, I might look at seeing what will port to Panther (10.3) and even Jaguar (10.2).

In a [blog post](https://gist.github.com/cellularmitosis/c56bb91d0b1ad0cd785ccd302abbba7c) I looked at data from [Everymac.com](https://everymac.com/systems/by_capability/maximum-macos-supported.html) to see which Macs are stuck on 10.3 and 10.2:

There are 9 Macs stuck on 10.3:

```
['iBook', 'G3/300_(Original/Clamshell)', 'X_10.3.9']
['iBook_G3/366_SE_(Original/Clamshell)', 'X', '10.3.9']
['iMac_G3_233_Original_-_Bondi_(Rev._A_&_B)', 'X_10.3.9']
['iMac_G3_266_(Fruit', 'Colors)', 'X_10.3.9']
['iMac_G3_333_(Fruit_Colors)', 'X_10.3.9']
['iMac_G3_350_(Slot', 'Loading_-_Blueberry)', 'X_10.3.9']
['iMac_G3_350_(Summer', '2000_-_Indigo)', 'X_10.3.9']
['PowerBook_G3_333_(Bronze_KB/Lombard)', 'X_10.3.9']
['PowerBook', 'G3_400_(Bronze_KB/Lombard)', 'X_10.3.9']
```

There are 19 Macs stuck on 10.2:

```
['Mac_Server_G3_233_Minitower', 'X', '10.2.8']
['Mac_Server_G3_266_Minitower', 'X_10.2.8']
['Mac_Server_G3_300_Minitower', 'X_10.2.8']
['Mac_Server_G3_333_Minitower', 'X_10.2.8']
['PowerBook_G3_233_', '(Wallstreet)', 'X_10.2.8']
['PowerBook_G3_250_(Wallstreet)', 'X_10.2.8']
['PowerBook', 'G3_292_(Wallstreet)', 'X_10.2.8']
['PowerBook_G3_233_(PDQ_-_Late_1998)', 'X_10.2.8']
['PowerBook_G3_266_(PDQ_-_Late_1998)', 'X_10.2.8']
['PowerBook_G3_300_(PDQ_-_Late', '1998)', 'X_10.2.8']
['Power', 'Macintosh_G3_233_Desktop', 'X_10.2.8']
['Power_Macintosh_G3_233_Minitower', 'X_10.2.8']
['Power_Macintosh_G3_266_Desktop', 'X_10.2.8']
['Power_Macintosh_G3_266_Minitower', 'X_10.2.8']
['Power_Macintosh_G3_300_Desktop', 'X_10.2.8']
['Power_Macintosh_G3_300', 'Minitower', 'X_10.2.8']
['Power_Macintosh_G3_333_Minitower', 'X_10.2.8']
['Power', 'Macintosh_G3_233_All-in-One', 'X_10.2.8']
['Power_Macintosh_G3_266_All-in-One', 'X', '10.2.8']
```


## Other options

If Tiger.sh and Leopard.sh aren't for you, checkout these other package managers:
- [MacPorts](https://www.macports.org/)
- [Tigerbrew](https://github.com/mistydemeo/tigerbrew)
- [Fink](https://www.finkproject.org/) _(looks like they only support 10.6 and up these days)_


## Useful links for OS X PowerPC users

- [_Last versions of applications for Mac OS X on PowerPC_](http://matejhorvat.si/en/mac/osxppcsw/)
- [_The Tiger Thread (Mac OS X 10.4)_](https://forums.macrumors.com/threads/the-tiger-thread-mac-os-x-10-4.2134451/)
- [_The Leopard Thread_](https://forums.macrumors.com/threads/the-leopard-thread.2120703/)
