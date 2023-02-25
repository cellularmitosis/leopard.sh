# Tips


## Apple's open source code.

- https://opensource.apple.com/releases/
- https://github.com/opensource-apple
  - e.g. https://github.com/opensource-apple/cctools
- https://github.com/mattl/opensource.apple.com/blob/master/files.txt


## Debugging a misbehaving Makefile

```
make SHELL='sh -x'
```


## Locating the libgcc used by a particular compiler:

```
$ gcc -m32 -print-libgcc-file-name
/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/libgcc.a
$ gcc -m64 -print-libgcc-file-name
/usr/lib/gcc/powerpc-apple-darwin9/4.0.1/ppc64/libgcc.a
```


## Looking for symbols within libgcc:

```
nm `gcc -m64 -print-libgcc-file-name` | grep ___muldi3
```


## Forcing gcc to use an alternate ld:

```
CC='gcc-4.2 -B/opt/ld64-97.17-tigerbrew/bin'
CXX='g++-4.2 -B/opt/ld64-97.17-tigerbrew/bin'
```


## `gcc -rdynamic`

This gcc option only applies to ELF executables.

If you find it being used in a Makefile, you can just remove it.

https://stackoverflow.com/a/29535789


## ssh'ing from modern machines

see https://askubuntu.com/questions/836048/ssh-returns-no-matching-host-key-type-found-their-offer-ssh-dss

```
ssh -oHostKeyAlgorithms=+ssh-dss macuser@pbookg42
```


## Enabling key-based root ssh access

Hmm, apparently you still have to enable the root account by sudo'ind to root and running `passwd`?  Still having trouble getting passwordless root ssh to work.

### Tiger

- Set up /var/root/.ssh/authorized_keys

### Leopard

- Set up /var/root/.ssh/authorized_keys
- In System Preferences -> Sharing -> Remote Login, you must add "Administrators" to the list of "Only these users".  Selecting "All users" will not work.


## PowerPC assembler, calling conventions, etc.

https://www.mono-project.com/docs/about-mono/supported-platforms/powerpc/


## Making a bootable USB installer

Often, disk utility seemed to fail due to permissions.

This appears to be the underlying command it was trying to run (replace `disk4s1` with what is appropriate for your system):

```
sudo /usr/sbin/asr restore --source /Volumes/Mac\ OS\ X\ Install\ Disc\ 1 --target /dev/disk4s1 --erase
```


## Resetting a user password

First, boot into single-user mode.  Reboot and hold CMD-s.

### Tiger

To reset `bob`'s password:

```
sh /etc/rc
passwd bob
```

(Note: after running `sh /etc/rc`, text will continue to print to the console even after the prompt returns.
Run `passwd bob` after the prompt returns, before waiting for all output to stop printing.

### Leopard

To reset `bob`'s password to `hackme`:

```
mount -uw /
launchctl load /System/Library/LaunchDaemons/com.apple.DirectoryServices.plist
dscl . -passwd /Users/bob hackme
```

## Misc

- https://www.seriss.com/people/erco/osx/
