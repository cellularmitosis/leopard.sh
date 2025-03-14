#!/bin/bash

# sync up all of the hosts in the build farm (the "cat farm").

set -e

mkdir -p ~/.ssh/sockets

# hosts:
# imacg3, ibookg3, graphite, emac, emac2, emac3, pbookg4, pbookg42, imacg5, imacg52, imacg53, pmacg5

# map:
# tiger g3:    ibookg3, imacg3
# tiger g4:    graphite
# tiger g4e:   emac2
# tiger g5:    imacg52, imacg53
# leopard g4e: pbookg4, pbookg42, emac, emac3
# leopard g5:  imacg5, pmacg5

if test "$1" = "--minimal" ; then
    minimal=1
    shift 1
fi

if test -n "$1" ; then
    hosts="$1"
    shift 1
else
    hosts="pmacg5 imacg5 imacg52 imacg53 emac emac2 emac3 pbookg4 pbookg42 graphite ibookg3 imacg3"
fi

uphosts=""
echo "👉 ping"
# make two passes, because sometimes the .local hosts resolve after a ping.
for host in $hosts ; do
    ping -o -t 1 $host >/dev/null 2>&1 &
done
sleep 0.25
for host in $hosts ; do
    if ping -o -t 1 $host >/dev/null 2>&1 ; then
        uphosts="$uphosts $host"
        echo " ✅ $host is up"
    else
        echo " ❌ $host is down"
    fi
done

cd ~/catfarm

if test "$1" = "--root" ; then
    echo
    echo "👉 root's files"
    #for host in $uphosts ; do
    for host in $uphosts ; do
        echo "  🖥  $host"
        ssh root@$host mkdir -p /var/root/.ssh
        rsync -ai host_files/_all_/root/ root@$host:/var/root/
        ssh root@$host rm -f /var/root/.profile
        ssh root@$host chmod go-r /var/root/.ssh/id_rsa
    done

    echo
    echo "👉 system files"
    for host in $uphosts ; do
        echo "  🖥  $host"
        rsync -ai host_files/$host/etc/ssh_host_* root@$host:/etc/
    done
fi

echo
echo "👉 user files"
for host in $uphosts ; do
    echo "  🖥  $host"
    (
        ssh $host mkdir -p \
            /Users/macuser/.ssh/sockets \
            /Users/macuser/Downloads \
            /Users/macuser/bin \
            /Users/macuser/tmp
        rsync -ai host_files/_all_/macuser/ $host:/Users/macuser/
        ssh $host rm -f /Users/macuser/.profile
        ssh $host chmod go-r /Users/macuser/.ssh/id_rsa
        if test -e host_files/$host/Users/macuser ; then
            rsync -ai host_files/$host/Users/macuser/ $host:/Users/macuser/
        fi
    ) &
done
wait

if test -n "$minimal" ; then
    exit 0
fi

echo
echo "👉 pull binpkgs"
for host in $uphosts ; do
    echo "  🖥  $host"
    (
        ssh $host mkdir -p /Users/macuser/Desktop/binpkgs
        rsync -ai --update $host:/Users/macuser/Desktop/binpkgs/ ~/leopard.sh/binpkgs
        ssh $host rm -f '/Users/macuser/Desktop/binpkgs/*'
    ) &
done
wait

echo
echo "👉 push leopard.sh"
for host in $uphosts ; do
    echo "  🖥  $host"
    (
        rsync -ai \
            ~/leopard.sh/leopardsh/leopard.sh \
            ~/leopard.sh/tigersh/tiger.sh \
            $host:/usr/local/bin/
        rsync -ai \
            ~/leopard.sh/leopardsh/utils/ \
            ~/leopard.sh/tigersh/utils/ \
            ~/leopard.sh/utils/ \
            $host:/Users/macuser/bin/
        ssh $host "rm -f /opt/leopard.sh/share/leopard.sh/config.cache/leopard.cache \
            /opt/tiger.sh/share/tiger.sh/config.cache/tiger.cache \
            /opt/tiger.sh/share/tiger.sh/config.cache/disabled.cache"
    ) &
done
wait

#echo
#echo "👉 push distfiles"
#for host in $uphosts ; do
#    echo "  🖥  $host"
#    cd ~/dist
#    rsync -ai --delete *.tar.gz *.tgz *.tar.bz2 *.tar.xz *.dmg *.zip *.pem $host:/Users/macuser/Downloads/
#done

exit 0

echo
echo "👉 [tiger|leopard].sh --setup"
for host in $uphosts ; do
    echo "  🖥  $host"
    (
        ssh $host 'test "$(uname -r | cut -d. -f1)" = "8" && tiger.sh --setup || true'
        ssh $host 'test "$(uname -r | cut -d. -f1)" = "9" && leopard.sh --setup || true'
    ) &
done
wait
