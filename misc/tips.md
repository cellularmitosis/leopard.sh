# Tips

Locating the libgcc used by a particular compiler:

```
$ gcc -m32 -print-libgcc-file-name
/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/libgcc.a
$ gcc -m64 -print-libgcc-file-name
/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/ppc64/libgcc.a
```

Looking for symbols within libgcc:

```
nm `gcc -m64 -print-libgcc-file-name` | grep ___muldi3
```

Forcing gcc to use an alternate ld:

```
CC='gcc-4.2 -B/opt/ld64-97.17-tigerbrew/bin'
CXX='g++-4.2 -B/opt/ld64-97.17-tigerbrew/bin'
```

