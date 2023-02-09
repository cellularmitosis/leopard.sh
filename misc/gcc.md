# Notes on choosing which version of GCC to use.


## GCC 4.0.1

This is the default `gcc` on Tiger:

```
macuser@ibookg3(tiger)$ which gcc
/usr/bin/gcc
macuser@ibookg3(tiger)$ gcc --version
powerpc-apple-darwin8-gcc-4.0.1 (GCC) 4.0.1 (Apple Computer, Inc. build 5370)
Copyright (C) 2005 Free Software Foundation, Inc.
```

This is the default `gcc` on Leopard:

```
macuser@emac3(leopard)$ gcc --version
powerpc-apple-darwin9-gcc-4.0.1 (GCC) 4.0.1 (Apple Inc. build 5493)
Copyright (C) 2005 Free Software Foundation, Inc.
```

This version of GCC does not understand `-pthread`.

```
powerpc-apple-darwin8-gcc-4.0.1: unrecognized option '-pthread'
```


## GCC 4.2

GCC 4.2 is available by installing `gcc-4.2`.

This package is taken from Tigerbrew's `gcc-42-5553-darwin8-all.tar.gz`.

This version of GCC understands `-pthread`.


## GCC 4.9.4

GCC 4.9.4 is available by installing `gcc-4.9.4`.

This version of GCC supports thread-local storage.
