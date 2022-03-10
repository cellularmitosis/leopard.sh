#!/opt/tigersh-deps-0.1/bin/bash

# Install Xcode 2.5 on OS X Tiger / PowerPC.

set -e -o pipefail

tiger.sh --unpack-dist xcode-2.5
open /tmp/xcode-2.5/Installers/Xcode\ Installer\ Launcher.app
echo "Please use the on-screen dialog to install Xcode." >&2
echo "Afterwards, try running your tiger.sh command again." >&2
exit 1
