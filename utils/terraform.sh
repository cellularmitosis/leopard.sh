#!/bin/bash

# sync up all of the hosts in the build farm (the "cat farm").

set -e

mkdir -p ~/.ssh/sockets

# hosts:
# ibookg3, graphite, emac2, emac3, pbookg42, imacg5 imacg52

# map:
# tiger g3:    ibookg3
# tiger g4:    graphite
# tiger g4e:   emac3
# tiger g5:    imacg52
# leopard g4e: emac3
# leopard g5:  imacg5

if test "$1" = "--minimal" ; then
    minimal=1
    shift 1
fi

hosts=${1:-"imacg5 imacg52 emac3 emac2 pbookg42 graphite ibookg3"}

uphosts=""
echo "👉 ping"
# make two passes, because sometimes the .local hosts resolve after a ping.
for host in $hosts ; do
    ping -o -t 1 $host.local >/dev/null 2>&1 || true
done
for host in $hosts ; do
    if ping -o -t 1 $host.local >/dev/null 2>&1 ; then
        uphosts="$uphosts $host"
        echo " ✅ $host is up"
    else
        echo " ❌ $host is down"
    fi
done

cd ~/catfarm

# echo
# echo "👉 root's files"
# for host in $uphosts ; do
#     echo "  🖥  $host"
#     ssh root@$host mkdir -p /var/root/.ssh
#     rsync -ai host_files/all/ $host:/var/root/
#     ssh $host rm -f /var/root/.profile
# done

# echo
# echo "👉 system files"
# for host in $uphosts ; do
#     echo "  🖥  $host"
#     rsync -ai host_files/$host/ssh_host_* root@$host:/etc/
# done

echo
echo "👉 user files"
for host in $uphosts ; do
    echo "  🖥  $host"
    ssh $host mkdir -p \
        /Users/macuser/.ssh/sockets \
        /Users/macuser/Downloads \
        /Users/macuser/bin \
        /Users/macuser/tmp
    rsync -ai host_files/all/ $host:/Users/macuser/
    rsync -ai tmp/ $host:/Users/macuser/tmp/
    ssh $host rm -f /Users/macuser/.profile
done

if test -n "$minimal" ; then
    exit 0
fi

echo
echo "👉 pull binpkgs"
for host in $uphosts ; do
    echo "  🖥  $host"
    ssh $host mkdir -p \
        /Users/macuser/Desktop/tigersh/binpkgs \
        /Users/macuser/Desktop/leopardsh/binpkgs
    rsync -ai --update $host:/Users/macuser/Desktop/tigersh/binpkgs/ ~/tigersh/binpkgs
    rsync -ai --update $host:/Users/macuser/Desktop/leopardsh/binpkgs/ ~/leopardsh/binpkgs
done

echo
echo "👉 push tiger.sh"
for host in $uphosts ; do
    echo "  🖥  $host"
    cd ~/tigersh
    rsync -ai --delete * $host:/Users/macuser/Desktop/tigersh/
    ssh $host "cd /Users/macuser/bin \
        && ln -sf /Users/macuser/Desktop/tigersh/tiger.sh . \
        && ln -sf /Users/macuser/Desktop/tigersh/utils/make-tigersh-binpkg.sh . \
        && ln -sf /Users/macuser/Desktop/tigersh/utils/rebuild-tigersh-stales.sh . \
        && ln -sf /Users/macuser/Desktop/tigersh/utils/rebuild-tigersh-all.sh . \
        && rm -f /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache \
        && rm -f /opt/tiger.sh/share/tiger.sh/config.cache/disabled.cache"
done

echo
echo "👉 push leopard.sh"
for host in $uphosts ; do
    echo "  🖥  $host"
    cd ~/leopardsh
    rsync -ai --delete * $host:/Users/macuser/Desktop/leopardsh/
    ssh $host "cd /Users/macuser/bin \
        && ln -sf /Users/macuser/Desktop/leopardsh/leopard.sh . \
        && ln -sf /Users/macuser/Desktop/leopardsh/utils/make-leopardsh-binpkg.sh . \
        && ln -sf /Users/macuser/Desktop/leopardsh/utils/rebuild-leopardsh-stales.sh . \
        && ln -sf /Users/macuser/Desktop/leopardsh/utils/rebuild-leopardsh-all.sh . \
        && rm -f /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache \
        && rm -f /opt/leopard.sh/share/leopard.sh/config.cache/disabled.cache"
done

echo
echo "👉 push distfiles"
for host in $uphosts ; do
    echo "  🖥  $host"
    cd ~/dist
    rsync -ai --delete *.tar.gz *.tgz *.tar.bz2 *.tar.xz *.dmg *.zip $host:/Users/macuser/Downloads/
done

exit 0

echo
echo "👉 [tiger|leopard].sh --setup"
for host in $uphosts ; do
    echo "  🖥  $host"
    ssh $host 'test "$(uname -r | cut -d. -f1)" = "8" && tiger.sh --setup || true'
    ssh $host 'test "$(uname -r | cut -d. -f1)" = "9" && leopard.sh --setup || true'
done
