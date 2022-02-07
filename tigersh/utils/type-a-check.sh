#!/bin/bash

set -e -o pipefail

grep 'type -a' *.sh | grep -v '/dev/null'
