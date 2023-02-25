#!/usr/bin/python
# Note: written for Python 2.3 (Tiger) / Python 2.5 (Leopard).

# Prototype of a bare-bones DIY distcc implementation.

# The basic idea:
# Many C-based projects are built as individual files, then linked together.
# These individual compiled ".o" files could be distributed and built across
# a cluster of machines.
# By leveraging "gcc -E", a single source file can be copied to the remote
# host, compiled, and the resulting ".o" copied back, and later linked.

# To use this, run configure with "real" gcc but run make with the rcc.py symlink shims in $PATH:
#   ./configure CC=gcc-4.9
#   env PATH=/Users/macuser/opt/rcc/bin:$PATH RCC_SSH_HOSTS="ibookg3 ibookg32" make -j2

import sys
import os
import random

CC_EXTS = [".c", ".cc", ".cpp"]

# Return a copy of the list.
def copy_list(l):
    return l[:]

# Find the index of the "-o" option.
# Returns int or None.
def index_of_dash_o(argv):
    for (i, arg) in enumerate(argv):
        if arg == "-o":
            return i
    return None

# Try to determine the output file of this compilation command (e.g. "-o foo.o").
# Returns (int, str) or None.
def outfile(argv):
    i = index_of_dash_o(argv)
    if i is None:
        return None
    if (i+1) >= len(argv):
        return None
    return (i+1, argv[i+1])

# Is the output file a ".o" file?
# Returns bool.
def outfile_is_dot_o(argv):
    ret = outfile(argv)
    if ret is None:
        return False
    (_, outf) = ret
    return outf[-2:] == ".o"

# Which source file is being compiled?
# Returns (i, str) or None.
def subject_file(argv):
    # The "good enough for now" approach.
    argv = copy_list(argv)
    argv.reverse()
    for (i, arg) in enumerate(argv):
        if arg[-2:] in CC_EXTS:
            real_i = len(argv) - i - 1
            return (real_i, arg)
    return None

# Is the source file being compiled a ".c" file?
# Returns bool.
def subject_file_is_supported(argv):
    ret = subject_file(argv)
    if ret is None:
        return False
    (_, sfile) = ret
    return sfile[-2:] in CC_EXTS

# Currently we only distribute "-o foo.o" commands.
# Returns bool.
def cmd_is_distributable(argv):
    if not outfile_is_dot_o(argv):
        sys.stderr.write("rcc: outfile is not \".o\", running locally.\n")
        return False
    if not subject_file_is_supported(argv):
        sys.stderr.write("rcc: subject file is not one of %s, running locally.\n" % CC_EXTS)
        return False
    if not os.environ.has_key("RCC_RSH_HOSTS") and not os.environ.has_key("RCC_SSH_HOSTS"):
        sys.stderr.write("rcc: RCC_RSH_HOSTS and RCC_SSH_HOSTS not set, running locally.\n")
        return False
    return True

# This script will be named / symlinked the same as gcc, gcc-4.2, etc.  Thus,
# this script shadows the real compiler commands.
# Based on the name / symlink of this script, return the full path to
# the corresponding "real" gcc command (e.g. "/usr/bin/gcc-4.2").
# Returns str or throws.
def real_cc(argv):
    table = {
        "gcc": "/usr/bin/gcc",
        "g++": "/usr/bin/g++",
        "gcc-4.2": "/usr/bin/gcc-4.2",
        "g++-4.2": "/usr/bin/g++-4.2",
        "gcc-4.9": "/opt/gcc-4.9.4/bin/gcc-4.9",
        "g++-4.9": "/opt/gcc-4.9.4/bin/g++-4.9",
        "gcc-10.3": "/opt/gcc-10.3.0/bin/gcc-10.3",
        "g++-10.3": "/opt/gcc-10.3.0/bin/g++-10.3",
    }
    arg0 = os.path.split(argv[0])[1]
    if table.has_key(arg0):
        return table[arg0]
    else:
        raise Exception("don't know what the real CC is for %s" % arg0)

# Transform "gcc -o foo.o -c foo.c" into "gcc -E -o foo.i -c foo.c"
# Returns str or None.
def make_E_cmd(argv):
    # Insert a "-E" flag.
    # Returns [str].
    def insert_E(argv):
        argv.insert(1, "-E")
        return argv

    # Replace "-o foo.o" with "-o foo.i".
    # Returns [str] or None.
    def outfile_o_to_i(argv):
        ret = outfile(argv)
        if ret is None:
            return None
        (i, ofile) = ret
        if ofile[-2:] != ".o":
            return None
        argv[i] = ofile[:-2] + ".i"
        return argv

    argv = copy_list(argv)
    argv[0] = real_cc(argv)
    argv = insert_E(argv)
    argv = outfile_o_to_i(argv)
    if argv is None:
        return None
    return " ".join(argv)

# Generate the command to copy the .i file to the build machine.
# Returns str or throws.
def make_rcp_i_cmd(argv, host, rsh="ssh", rcp="scp"):
    # TODO handle spaces in filename.
    # TODO use a unique tmpdir.
    ret = subject_file(argv)
    assert ret is not None
    (_, sfile) = ret
    assert sfile[-2:] in CC_EXTS
    remote_ifile = sfile[:-2] + ".i"
    fname = os.path.split(remote_ifile)[1]
    dest = "%s:/tmp/rcc/%s" % (host, fname)

    ret = outfile(argv)
    assert ret is not None
    (_, ofile) = ret
    assert ofile[-2:] == ".o"
    src = ofile[:-2] + ".i"

    dir = os.path.split(remote_ifile)[0]
    pwd = os.getcwd()
    cmd = "%s %s mkdir -p /tmp/rcc && %s %s %s" % (rsh, host, rcp, src, dest)
    return cmd

# Generate the command to ssh into the build machine and compile the .i file.
# Returns str or throws.
def make_rsh_cc_i_cmd(argv, host, rsh="ssh"):
    argv = copy_list(argv)
    argv[0] = real_cc(argv)

    ret = subject_file(argv)
    assert ret is not None
    (i, sfile) = ret
    assert sfile[-2:] in CC_EXTS
    ifile = sfile[:-2] + ".i"
    ifile = os.path.split(ifile)[1]
    argv[i] = ifile

    ret = outfile(argv)
    assert ret is not None
    (i, ofile) = ret
    assert ofile[-2:] == ".o"
    ofile = os.path.split(ofile)[1]
    argv[i] = ofile

    cc_cmd = " ".join(argv)

    # ARGGGH the exit status of rsh does not reflect the exit status of the command!!!
    # This was an insanely poor design decision!  Bad UNIX greybeards, no cookie!
    # To indicate success, we move the file into 'out/' after compilation.
    cmd_parts = [
        "%s %s" % (rsh, host),
        "mkdir -p /tmp/rcc/out \&\& cd /tmp/rcc",
        "\&\& %s \&\& mv %s out/%s" % (cc_cmd, ofile, ofile),
        "\&\& rm -f %s \|\| rm -f %s" % (ifile, ifile)
    ]
    cmd = " ".join(cmd_parts)
    return cmd

# Generate the command to copy the .o file from the build machine.
# Returns str or throws.
def make_rcp_o_cmd(argv, host, rcp="scp"):
    # TODO handle spaces in filename.
    ret = outfile(argv)
    assert ret is not None
    (_, ofile) = ret
    (odir, ofname) = os.path.split(ofile)
    pwd = os.getcwd()
    cmd_parts = [
        "mkdir -p ./%s" % odir,
        "&& %s %s:/tmp/rcc/out/%s %s/%s" % (rcp, host, ofname, pwd, ofile),
        "&& rsh %s rm -f /tmp/rcc/out/%s" % (host, ofname)
    ]
    cmd = " ".join(cmd_parts)
    return cmd

# Choose a remote build machine.
# Returns str or throws.
def pick_a_host():
    if os.environ.has_key("RCC_RSH_HOSTS"):
        hosts = os.environ["RCC_RSH_HOSTS"].split()
    elif os.environ.has_key("RCC_SSH_HOSTS"):
        hosts = os.environ["RCC_SSH_HOSTS"].split()
    else:
        raise Exception("No remote hosts available!")
    # TODO: this is the simplest thing which could possibly work, but could
    # overload a slow host.  Implement job / host tracking.
    return random.choice(hosts)

# Execute the compilation on a remote build machine, using ssh.
# Throws on error.
def run_remotely(argv, rsh="ssh", rcp="scp"):
    host = pick_a_host()
    if host == "localhost":
        run_locally(argv)
        return

    cmd = make_E_cmd(argv)
    sys.stderr.write("rcc[-E]: %s\n" % cmd)
    assert 0 == os.system(cmd)
    
    cmd = make_rcp_i_cmd(argv, host, rsh=rsh, rcp=rcp)
    sys.stderr.write("rcc[%s .i]: %s\n" % (rcp, cmd))
    assert 0 == os.system(cmd)

    cmd = make_rsh_cc_i_cmd(argv, host, rsh=rsh)
    sys.stderr.write("rcc[remote cc]: %s\n" % cmd)
    assert 0 == os.system(cmd)

    cmd = make_rcp_o_cmd(argv, host, rcp=rcp)
    sys.stderr.write("rcc[%s .o]: %s\n" % (rcp, cmd))
    assert 0 == os.system(cmd)

# Execute the compilation locally.
# Throws on error.
def run_locally(argv):
    argv = copy_list(argv)
    argv[0] = real_cc(argv)
    cmd = " ".join(argv)
    sys.stderr.write("rcc[local cc]: %s\n" % cmd)
    assert 0 == os.system(cmd)

if __name__ == "__main__":
    if cmd_is_distributable(sys.argv):
        if os.environ.has_key("RCC_RSH_HOSTS"):
            # Note: to enable rsh / rcp on Tiger, 'sudo service shell start',
            # and e.g. echo imacg3 > ~/.rhosts on each build machine.
            run_remotely(sys.argv, rsh="rsh", rcp="rcp")
        elif os.environ.has_key("RCC_SSH_HOSTS"):
            run_remotely(sys.argv, rsh="ssh", rcp="scp")
        else:
            assert False
    else:
        run_locally(sys.argv)
