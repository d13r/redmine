#!/bin/bash
set -o errexit -o nounset -o pipefail
cd "$(dirname "$0")/.."

################################################################################
# Restart Redmine (when running under Phusion Passenger).
################################################################################

exec touch redmine/tmp/restart.txt
