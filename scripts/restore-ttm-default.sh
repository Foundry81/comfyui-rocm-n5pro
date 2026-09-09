#!/bin/bash
#
# restore-ttm-default.sh
#
# Remove the custom TTM pages_limit kernel parameter from TrueNAS.
#
# Original/default observed configuration:
#   TTM pages_limit: 7923500 pages
#   GTT total:       ~30.23 GiB
#
# Custom test configuration:
#   ttm.pages_limit=12582912
#   TTM/GTT target:  48 GiB
#
# NOTE:
# This restores the TrueNAS kernel_extra_options setting to empty.
# A reboot is required for TTM/amdgpu to initialize with the default
# memory limit again.

set -e

echo "Restoring TrueNAS default kernel options..."

midclt call system.advanced.update \
    '{"kernel_extra_options":""}'

echo
echo "Current configuration:"
midclt call system.advanced.config | grep kernel_extra_options

echo
echo "The custom TTM setting has been removed from the persistent"
echo "TrueNAS configuration."
echo
echo "REBOOT REQUIRED."
echo
echo "After reboot, verify:"
echo
echo "  cat /sys/module/ttm/parameters/pages_limit"
echo "  cat /sys/class/drm/card0/device/mem_info_gtt_total"
echo
echo "Expected TTM pages_limit:"
echo "  7923500"
echo
echo "Expected GTT total:"
echo "  ~32454656000 bytes (~30.23 GiB)"

