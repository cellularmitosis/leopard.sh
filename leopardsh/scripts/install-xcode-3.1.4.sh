#!/bin/bash

# Install Xcode 3.1.4 on OS X Leopard / PowerPC.

set -e

leopard.sh --unpack-dist xcode-3.1.4
open /tmp/xcode-3.1.4/XcodeTools.mpkg
echo "Please use the on-screen dialog to install Xcode." >&2
echo "Afterwards, try running your tiger.sh command again." >&2
exit 1
