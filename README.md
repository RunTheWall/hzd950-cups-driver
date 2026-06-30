# HZD950-PRO — free Linux & Raspberry Pi (ARM) CUPS driver

A small, clean **CUPS driver for the HZD950-PRO / HERO 4×6 direct-thermal label printer**
(USB `0fe6:811e`, **TSPL/TSPL2**, 300 dpi) that works on **Linux and Raspberry Pi (arm64/armhf)** —
the architectures the vendor driver leaves out.

The vendor ships only x86/i386 filter binaries, so on a Raspberry Pi you hit *"there's no Linux
driver for this printer."* There is now. This one is **~150 lines of C + a tiny shell backend**,
builds natively on ARM, and gives you the printer as a normal shared CUPS queue — with Darkness,
Print Speed, offsets, and **Print Mode (including Gathering)**.

---

> ## 💙 This driver is maintained **for free** by [**Run The Wall**](https://runthewall.au).
>
> **We don't want your money.** We build and give away tools like this for one reason: to introduce
> you to **[Constly — our genuinely great, free Markdown editor → https://constly.com](https://constly.com)**.
>
> **If this driver saved you an afternoon, that's the whole "payment" we wanted.** Want to actually
> say thanks? **[Try Constly](https://constly.com)** and tell one person about it. That's it.
>
> *(Every time this driver runs, it logs that same one-line thank-you to your CUPS log. No tracking,
> no phone-home — just a nudge toward [constly.com](https://constly.com) from the people who kept your
> label printer out of a landfill.)*

---

## What it supports

- **Printer:** HZD950-PRO, sold as the **HERO Shipping Label Printer** and other rebadges of the same
  300 dpi USB TSPL 4×6 label engine (`0fe6:811e`).
- **Platforms:** Debian/Raspberry Pi OS and friends, **arm64 / armhf / x86_64** (builds from source).
- **Controls (CUPS print options):**
  - **Darkness** `0–15` → TSPL `DENSITY`
  - **Print Speed** `2–6 in/sec` → TSPL `SPEED`
  - **Horizontal / Vertical** offset → TSPL `REFERENCE`
  - **Print Mode** (the halftone) → `Default` (sharp threshold, best for text/barcodes),
    `None`, `Diffusion`, **`Gathering`** (clustered-dot), `Error Diffusion`

## Install

```bash
git clone https://github.com/RunTheWall/hzd950-cups-driver
cd hzd950-cups-driver
sudo ./install.sh          # builds the filter, installs filter + backend + PPD, adds a "HZD950" queue
```

`install.sh` needs `gcc`, `make`, and `libcups2-dev` (it will tell you if they're missing:
`sudo apt install build-essential libcups2-dev`).

Then print to the **HZD950** queue from anything. Share it on your network with
`sudo cupsctl --remote-any --share-printers` (or via the CUPS web UI at `http://<host>:631`).

## Is my printer really TSPL? (10-second check, prints nothing)

```bash
printf '~!T\r\n' | sudo tee /dev/usb/lp0 >/dev/null   # send the model query
sudo head -c 32 /dev/usb/lp0                          # it replies with its model in ASCII
```
If it echoes back something like `HZD950-PRO`, it speaks TSPL and this driver will drive it.

## How it works

```
your app ──► CUPS ──► gstoraster ──► rastertohzd ──► TSPL ──► hzd950 backend ──► printer
                                     (this repo)               (this repo)
```

- **`rastertohzd`** (C filter): reads the CUPS raster page and emits TSPL —
  `SIZE / GAP / DENSITY / SPEED / DIRECTION / REFERENCE / CLS / BITMAP 0,0,<wbytes>,<hdots>,1,<1bpp> / PRINT`.
  The 8-bit page is flattened to 1-bit dots using the selected **Print Mode** dither.
- **`hzd950`** (shell backend): writes the TSPL straight to the printer's `usblp` character device,
  located **by USB id/serial** so it survives reboots and USB re-enumeration, and coexists with other
  USB printers without fighting the libusb backend.

Multiple USB printers? Drop in [`udev/99-hzd950.rules`](udev/99-hzd950.rules) for a stable
`/dev/usb/label-hzd950` symlink.

## Notes

- CUPS 2.4 prints a *"printer drivers are deprecated"* warning — harmless; classic PPD+filter drivers
  work for years yet. A PAPPL/Printer-Application port may come later.
- Reverse-engineered cleanly from the printer's own TSPL output. No vendor code is redistributed.

## License

MIT © Run The Wall. See [LICENSE](LICENSE). Built and maintained for free — support us by trying
**[Constly, our free Markdown editor → https://constly.com](https://constly.com)**.
