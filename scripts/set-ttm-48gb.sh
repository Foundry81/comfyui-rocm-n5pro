#!/bin/bash
#
# set-ttm-48gb.sh
#
# Configure the TrueNAS TTM memory limit for a 48 GiB GPU/GTT pool.
#
# Target:
#   AMD Ryzen AI 9 HX PRO 370 / Radeon 890M
#
# 48 GiB / 4096-byte pages = 12,582,912 pages
#
# Original/default observed configuration:
#   TTM pages_limit: 7923500 pages
#   GTT total:       ~30.23 GiB
#
# Experimental configuration:
#   ttm.pages_limit=12582912
#   GTT total:       51,539,607,552 bytes
#   ComfyUI reports: 49,152 MB / 48 GiB
#
# NOTE:
# The TTM limit is initialized during boot. A reboot is required
# before the new GTT pool size becomes active.

set -e

TTM_PAGES=12582912

echo "Setting TrueNAS TTM memory limit to 48 GiB..."
echo
echo "TTM pages: ${TTM_PAGES}"
echo "GTT target: 51,539,607,552 bytes"
echo

midclt call system.advanced.update \
    "{\"kernel_extra_options\":\"ttm.pages_limit=${TTM_PAGES}\"}"

echo
echo "Current configuration:"
midclt call system.advanced.config | grep kernel_extra_options

echo
echo "The 48 GiB TTM setting has been saved to the TrueNAS configuration."
echo
echo "REBOOT REQUIRED."
echo
echo "After reboot, verify:"
echo
echo "  cat /sys/module/ttm/parameters/pages_limit"
echo "  cat /sys/class/drm/card0/device/mem_info_gtt_total"
echo
echo "Expected TTM pages_limit:"
echo "  ${TTM_PAGES}"
echo
echo "Expected GTT total:"
echo "  51539607552 bytes (~48 GiB)"

