# tiger.sh and leopard.sh

Package managers for PowerPC Macs running OS X Leopard (10.5) and Tiger (10.4), written in Bash 😱

See [tigersh/README.md](tigersh/README.md) and [leopardsh/README.md](leopardsh/README.md).


## Binary package support

I build pre-compiled binary packages optimized for the following platforms:

|         | G3  | G4  | G4e | G5 (32-bit) | G5 (64-bit) |
| ------- |:---:|:---:|:---:|:---:        |:---:        |
| Tiger   | ✅  | ✅  |  ✅  | ✅          | ✅          |
| Leopard |     |     |  ✅  | ✅          | ✅          |

The above processors map to the following gcc flags:

- G3: `-mcpu=750`
- G4: `-mcpu=7400`
- G4e: `-mcpu=7450`
- G5 (32-bit): `-mcpu=970 -m32`
- G5 (64-bit): `-mcpu=970 -m64`
