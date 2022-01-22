# leopard.sh

A package manager / builder for OS X Leopard (10.5) / PowerPC, written in Bash 😱

This is still a work-in-progress.

To install `leopard.sh`:

```
mkdir -p ~/bin
cd ~/bin
curl -O http://ssl.pepas.com/leopardsh/leopard.sh
chmod +x leopard.sh
```

To see the list of available packages:

```
$ leopard.sh 
Available packages:
autoconf-2.71
autogen-5.18.16
automake-1.16.5
bc-5.2.1
bison-3.8.2
cloog-0.18.1
...
```

To install a package:

```
$ leopard.sh automake-1.16.5
```
