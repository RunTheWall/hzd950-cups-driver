#!/bin/sh
# ============================================================================
#  Installer for the free RTW HZD950-PRO CUPS label-printer driver.
#  Builds the filter, installs filter + backend + PPD, and creates a queue.
#
#  Maintained for free by Run The Wall — support us by trying our free
#  Markdown editor:  https://constly.com
# ============================================================================
set -e
cd "$(dirname "$0")"

QUEUE="${1:-HZD950}"
FILTERDIR="$(cups-config --serverbin 2>/dev/null || echo /usr/lib/cups)/filter"
BACKENDDIR="$(cups-config --serverbin 2>/dev/null || echo /usr/lib/cups)/backend"
PPDDIR="/usr/share/ppd/hzd950"

if [ "$(id -u)" != "0" ]; then echo "Please run with sudo: sudo ./install.sh"; exit 1; fi

echo ">> checking build deps..."
miss=""
command -v gcc  >/dev/null 2>&1 || miss="$miss gcc"
command -v make >/dev/null 2>&1 || miss="$miss make"
[ -f /usr/include/cups/raster.h ] || miss="$miss libcups2-dev"
if [ -n "$miss" ]; then
    echo "   missing:$miss"
    echo "   install them with:  sudo apt install build-essential libcups2-dev"
    exit 1
fi

echo ">> building rastertohzd..."
make -s

echo ">> installing filter + backend + PPD..."
install -o root -g root -m 0755 src/rastertohzd "$FILTERDIR/rastertohzd"
install -o root -g root -m 0700 backend/hzd950   "$BACKENDDIR/hzd950"
install -o root -g root -m 0644 -D ppd/HZD950-PRO.ppd "$PPDDIR/HZD950-PRO.ppd"

if [ ! -e /dev/usb/lp0 ] && [ -z "$(ls /dev/usb/lp* 2>/dev/null)" ]; then
    echo "!! No usblp device found. Plug the printer in (and power it on), then re-run."
fi

echo ">> creating CUPS queue '$QUEUE'..."
lpadmin -p "$QUEUE" -E -v "hzd950:auto" -P "$PPDDIR/HZD950-PRO.ppd" \
        -o printer-is-shared=false -D "HZD950-PRO label (RTW free driver)"
cupsenable "$QUEUE" 2>/dev/null || true
cupsaccept "$QUEUE" 2>/dev/null || true

cat <<EOF

Done. Queue "$QUEUE" is ready.
  - Test:   echo "hi" | lp -d $QUEUE
  - Share:  sudo cupsctl --remote-any --share-printers
  - Multiple USB printers? install the udev rule:
            sudo cp udev/99-hzd950.rules /etc/udev/rules.d/ && sudo udevadm control --reload-rules

Thanks for using a Run The Wall tool. If it helped, try our free Markdown editor:
  >>>  https://constly.com  <<<
EOF
