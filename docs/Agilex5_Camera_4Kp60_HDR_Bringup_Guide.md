# Agilex 5 Camera 4Kp60 HDR — Lab Bring-up Guide

| Field | Value |
|-------|-------|
| Design | 4Kp60 Multi-Sensor HDR Camera Solution System Example Design |
| Release | Use a matching pre-built QSPI + microSD pair; 25.1 and 26.1 are both documented |
| Hardware | Agilex 5 FPGA E-Series **065B Modular Development Kit** |
| Cameras | Framos FSM:GO **IMX678** (1 or 2 modules) |
| Audience | Lab / engineering team |
| Doc status | Team bring-up procedure with Ethernet validation and board-triage guidance |

---

## 1. Purpose

This document tells a teammate how to **boot and run** the pre-built Altera camera design on the Modular Development Kit, open the web GUI, and get camera video on DisplayPort.

It has two layers:

1. **Official Altera flow** (from the design documentation)
2. **Lab-specific notes** discovered during bring-up, including Ethernet validation and board triage

---

## 2. Customer demo fast start (pre-provisioned kit)

Use this section when the kit has already been prepared and you need to bring it up in front of a customer. It is deliberately short; use the detailed procedure in Section 7 if a step fails.

### What must already be ready

| Item | Required state |
|------|----------------|
| QSPI | `top.core.jic` was programmed once successfully |
| microSD card | Contains the matching `hps-first-vvp-isp-demo-image-agilex5_mk_a5e065bb32aes1.wic` image |
| Boot switches | SOM SW1 is **ON-ON** (QSPI / AS×4 boot) |
| Camera | Framos IMX678 connected to MIPI0 or MIPI1, with pin 1 aligned |
| Display | Carrier **DisplayPort TX** connected to the selected monitor |
| Host connections | Board J6 Ethernet and SOM J2 USB connected to the host PC |
| Host network | Board and host are on the same Ethernet network; VPN is disabled if it interferes |

> A prepared microSD card alone is not enough. QSPI must already contain the matching `top.core.jic` boot image.

### Demo sequence

**1. Power on**  
Verify the connections above, insert the microSD card, and power on the board.

**2. Wait for application startup**  
Wait about two minutes for Linux and the camera application to start.

**3. Open the HPS serial console**  
Use 115200 8N1, press Enter, and log in as `root`:

```bash
sudo minicom -D /dev/ttyUSB6 -b 115200
```

`ttyUSB6` is the usual lab mapping; if it is blank, use the serial-port guidance in Section 7.3.

**4. Get the board address**

```bash
ip -4 addr show eth0
```

**5. Open the GUI on the host PC**

```text
http://<board-ip>/
```

**6. Select the camera input**  
In the web GUI, select **Input Config → Input Source → Camera**.

**7. Confirm video**  
Confirm camera video appears on the DisplayPort monitor.

### If the GUI does not open

First test normal Ethernet operation:

```bash
ping -c 2 -M do -s 1472 <board-ip>
```

- If this succeeds, keep the default MTU 1500 and continue with the GUI.
- If this fails, **do not lower MTU**. Follow the Ethernet validation and board-triage process in Section 8 before using the kit for a customer demonstration.

### If the monitor has no video

In the GUI select **Input TPG** first. If the test pattern appears, switch back to **Camera**. For the MIPI1 single-camera known issue, toggle **Camera → Input TPG → Camera**.

---

## 3. Official references

| Resource | Link |
|----------|------|
| Design overview | https://altera-fpga.github.io/rel-26.1/embedded-designs/agilex-5/e-series/modular/camera/camera_4k/camera_4k/ |
| Detailed guide | https://github.com/altera-fpga/agilex5-ed-camera/blob/rel/26.1/docs/es/camera/camera_4k/camera_4k.md |
| Repository | https://github.com/altera-fpga/agilex5-ed-camera/tree/rel/26.1 |
| Pre-built binaries | https://github.com/altera-fpga/agilex5-ed-camera/releases/tag/rel-26.1-isp_hdr-MDK_RevB_GrpB |
| 25.1 test documentation | https://altera-fpga.github.io/rel-25.3/embedded-designs/agilex-5/e-series/modular/camera/camera_4k/camera_4k/ |
| 25.1 pre-built binaries | https://github.com/altera-fpga/agilex5-ed-camera/releases/tag/rel-25.1 |
| Repo quick start | https://github.com/altera-fpga/agilex5-ed-camera/blob/rel/26.1/AGX_5E_Altera_Modular_Dk_ISP_designs/HDR_CAMERA.md |
| Known issues | https://github.com/altera-fpga/agilex5-ed-camera/blob/rel/26.1/docs/es/camera/camera_4k/known_issues.md |

---

## 4. Does the official design require setting MTU?

**No.** Altera’s official camera 4K documentation does **not** ask you to change Ethernet MTU.

Official network guidance is only:

- Connect board **J6** Ethernet to the same network as the host PC (direct cable, switch, or router)
- Disable VPN on the host if it interferes
- Get the board IP with `ifconfig` / `ip a` after login as `root`
- Open `http://<board-ip>/` in a browser

### Lab conclusion: keep MTU at 1500

On a **healthy** Ethernet path (normal 1500-byte frames work):

- You do **nothing** with MTU
- GUI and board work at default MTU 1500

During the initial lab bring-up, one board showed a size-dependent Ethernet failure:

- Frames larger than roughly 400 bytes were dropped
- Symptoms at MTU 1500 were:
  - `ping` small packets OK
  - `ping -M do -s 1472` fails
  - Browser page hangs / blank
  - `curl` may show `200 OK` but receive **0 bytes** of the HTML body before timing out
  - SSH key exchange can stall

Using MTU 400 only hid the fault: 400-byte packets were still intermittently lost and the GUI greyed out. It is **not** an approved team workaround.

The same 25.1 image, host PC, and default MTU 1500 passed the full-size ping and GUI download after replacing the board. This isolates the incident to the original board's J6/HPS Ethernet path or associated board hardware; it is not an Ubuntu, browser, IP-version, or camera-design release issue.

**Team rule:** Keep MTU at 1500. First test full-size ping. If it fails, quarantine the board for Ethernet triage rather than reducing MTU.

```bash
# Replace BOARD_IP with the board address
ping -c 2 -M do -s 1472 BOARD_IP
```

| Result | Action |
|--------|--------|
| Large ping succeeds | Keep default MTU 1500 (official / preferred) |
| Large ping fails | Follow Ethernet validation and board triage (Section 8); do not lower MTU |

---

## 5. One-time programming (select a matching release pair)

Repeat only if microSD or QSPI is wiped.

### Release pairing rule

Never mix a QSPI `.jic` file from one release with a microSD `.wic` image from another release. Keep each pair in a separate host directory.

| Release | Matching source | Lab status |
|---------|-----------------|------------|
| 25.1 | Release tag `rel-25.1` | Validated on replacement board at MTU 1500 |
| 26.1 | Release tag `rel-26.1-isp_hdr-MDK_RevB_GrpB` | Current documented release; do not pair with 25.1 assets |

Both release pairs use these filenames:

| File | Purpose |
|------|---------|
| `top.core.jic` | QSPI boot image |
| `hps-first-vvp-isp-demo-image-agilex5_mk_a5e065bb32aes1.wic.gz` | microSD Linux + app image |

### Burn microSD

```bash
gunzip -k hps-first-vvp-isp-demo-image-agilex5_mk_a5e065bb32aes1.wic.gz
# Identify the whole-disk device carefully (e.g. /dev/sdX), not a partition
sudo dd if=hps-first-vvp-isp-demo-image-agilex5_mk_a5e065bb32aes1.wic \
  of=/dev/sdX bs=1M status=progress conv=fsync
sync
sudo eject /dev/sdX
```

Insert the card in the **SOM** microSD slot.

### Program QSPI once

1. Power **off**
2. SOM **SW1 = OFF-OFF** (MSEL = JTAG)
3. Power **on**
4. Program:

```bash
jtagconfig
quartus_pgm -c 1 -m jtag -o "pvi;top.core.jic"
```

5. Power **off**
6. SOM **SW1 = ON-ON** (MSEL = AS×4 / QSPI boot)

---

## 6. Hardware checklist (every session)

| Item | Setting / connection |
|------|----------------------|
| Boot mode | SOM **SW1 = ON-ON** |
| microSD | Inserted in **SOM** slot |
| Ethernet | Board **J6** → host PC Ethernet (lab preferred: direct shared link) |
| USB | SOM **J2** + Carrier **J35** both to PC |
| Cameras | Framos IMX678 on MIPI0 and/or MIPI1, pin 1 aligned |
| Display | Carrier **DisplayPort TX** → 4K-capable monitor (prefer native DP cable) |

> USB serial devices (`/dev/ttyUSB*`) appear only when the board is powered on.

---

## 7. Every-boot procedure (lab recommended)

### 7.1 Boot the host PC first

Configure Wired Ethernet as **Shared to other computers**.

```bash
ip -4 addr show enp3s0
# Expected on this lab PC: inet 10.42.0.1/24
```

If sharing is not active (connection name on this PC is `netplan-enp3s0`):

```bash
sudo nmcli connection modify "netplan-enp3s0" ipv4.method shared
sudo nmcli connection up "netplan-enp3s0"
ip -4 addr show enp3s0
```

### 7.2 Power on the board

Wait about **2 minutes** for Linux and `VvpIspDemo` to start.

### 7.3 Open HPS serial console

With **J2 + J35** connected you typically get **8** USB serial ports.

```bash
ls -l /dev/ttyUSB*

gnome-terminal --title="HPS" -- bash -c \
  "sudo minicom -D /dev/ttyUSB6 -b 115200; exec bash"
```

- Settings: **115200 8N1**, hardware flow control **OFF**
- Press **Enter**
- Login: `root` (no password)

#### Serial port map (important)

| Port group (typical) | Role |
|----------------------|------|
| `ttyUSB0`–`ttyUSB3` | JTAG / Nios group |
| `ttyUSB2` | Often **Nios** (“WELCOME TO INTEL NIOS SYSTEM”) — not Linux |
| `ttyUSB4`–`ttyUSB7` | HPS UART group |
| `ttyUSB6` | Often **HPS Linux** (3rd port of HPS group) |

`ttyUSB` numbers can change after reboot. If `ttyUSB6` is blank, try `ttyUSB4` / `5` / `7`, or open all four and power-cycle once with minicom already open.

### 7.4 Read board IP

```bash
ip -4 addr show eth0
# Typical on shared link: 10.42.0.212 (can change)
```

If no IPv4 address:

```bash
udhcpc -i eth0
ip -4 addr show eth0
```

> Always re-read the IP. Do not assume it stays `.212`.

### 7.5 Network health check (validate Ethernet)

On the host:

```bash
BOARD_IP=10.42.0.212   # replace with actual eth0 IP

ping -c 2 $BOARD_IP
ping -c 2 -M do -s 1472 $BOARD_IP
```

- If **1472 succeeds** → continue at MTU 1500  
- If **1472 fails** → stop GUI testing and follow Section 8; do **not** lower MTU

### 7.6 Open the web GUI

```bash
curl -sS --max-time 10 http://$BOARD_IP/ | wc -c
# Healthy response: nonzero HTML (about 1035 bytes for 25.1; about 1112 bytes for 26.1)

google-chrome-stable http://$BOARD_IP/
```

You should see the Altera splash, then the camera GUI.

### 7.7 Select camera input

In the GUI:

1. Open **Input Config**
2. Set **Input Source** → **Camera**
3. If video is missing (especially single camera on MIPI1): toggle  
   **Camera → Input TPG → Camera**  
   (official known-issue workaround)

Optional board log check:

```bash
grep -iE 'Found camera|Active input|GMSL' /tmp/vvp-isp-demo.log | head -n 30
```

Healthy example:

- `Found camera: FSM-IMX678` as Cam 0 / Cam 1  
- `Active input: Camera 0`  
- `3840x2160p @60`

---

## 8. Ethernet validation and board triage

Use this section if small pings work but `ping -M do -s 1472` fails, or if the GUI is blank despite a working camera/DisplayPort pipeline.

### Required normal configuration

- Board `eth0`: MTU **1500**
- Host Ethernet: MTU **1500**
- Host and board: same IPv4 network
- Host VPN/proxy: disabled if it interferes

### 1. Confirm the board application works locally

```bash
wget -S -O /tmp/gui-local.html -T 5 http://127.0.0.1/
wc -c /tmp/gui-local.html
```

If this returns nonzero HTML but the host browser is blank, continue below.

### 2. Validate the host-to-board Ethernet path

```bash
ping -c 2 $BOARD_IP
ping -c 2 -M do -s 1472 $BOARD_IP
curl -sS --max-time 10 http://$BOARD_IP/ | wc -c
```

Expected result: the full-size ping succeeds and `curl` receives nonzero HTML.

### 3. If full-size traffic fails

1. Keep MTU 1500; do not use a smaller MTU as a permanent workaround.
2. Replace the Ethernet cable with a known-good Cat5e/Cat6 cable.
3. Test directly against a second host PC with a normal 1500-MTU Ethernet connection.
4. If the failure follows the board, remove it from customer/demo use and open a board support case.

### Known lab incident and resolution

- **Original board:** Failed full-size IPv4 and IPv6 traffic on Ubuntu and Windows, directly and through different network paths. Camera output and local web GUI were working. Packet loss began near 400 bytes.
- **Replacement board:** Using the same 25.1 QSPI/microSD pair and Ubuntu host, full-size ping passed and the web GUI returned a 1035-byte HTML response at MTU 1500.

The evidence identifies the original board's Ethernet/J6/HPS network path as faulty, though it does not identify the exact component.

---

## 9. DisplayPort blank / “please load image”

Cameras can be detected in software while the monitor stays blank. That is usually a **DisplayPort link** issue, not a sensor detect failure.

1. In GUI, set **Input Source = Input TPG**
   - If TPG appears → DP works; switch back to **Camera**
   - If still blank → check cable / TX connector / monitor input
2. Prefer native **DP→DP**; cheap DP→HDMI adapters often fail at 4Kp60
3. Use carrier **DisplayPort TX**
4. Reseat cable; power-cycle monitor
5. Optional: watch Nios console (`ttyUSB2`) while replugging DP for link messages

---

## 10. Useful board commands

```bash
ps | grep VvpIspDemo
tail -n 50 /tmp/vvp-isp-demo.log

# Confirm embedded web server responds locally
wget -S -O /tmp/local.html -T 5 http://127.0.0.1/
wc -c /tmp/local.html

# Restart application if needed
killall VvpIspDemo
cd /home/root && ./start.sh
```

App location: `/home/root/VvpIspDemo` (started by `/home/root/start.sh`).

---

## 11. What not to redo every boot

- Do **not** rewrite the microSD image
- Do **not** reprogram QSPI (`top.core.jic`) unless flash was erased or boot is broken

---

## 12. Troubleshooting quick table

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| No `/dev/ttyUSB*` | Board off / USB unplugged | Power on; connect J2 and J35 |
| Only 4 ttyUSB ports | One USB cable missing | Connect both J2 and J35 |
| Only Nios banner | Wrong serial port | Use HPS group’s 3rd port (often `ttyUSB6`) |
| Small ping works but browser blank / curl body = 0 | Large-frame Ethernet failure | Run the 1472 ping test and follow Section 8; do not lower MTU |
| IP not `.212` | DHCP lease changed | Re-read `ip -4 addr show eth0` |
| Cameras found, monitor blank | DP link | Try Input TPG; check DP cable/TX |
| GUI greys out every few seconds | Intermittent Ethernet transport fault | Validate full-size ping at MTU 1500; compare with a known-good board |
| VPN connected | Host network interference | Disable VPN (official guidance) |

---

## 13. One-page cheat sheet

```text
1. PC Wired = Shared                -> 10.42.0.1
2. Power board                      -> SW1 ON-ON
3. minicom /dev/ttyUSB6 115200      -> root
4. Board: ip -4 addr show eth0
5. Host:  ping -M do -s 1472 BOARD_IP
   - fail  -> do not lower MTU; follow board Ethernet triage
   - pass  -> keep MTU 1500 and open GUI
6. Chrome http://BOARD_IP/
7. GUI Input Config -> Camera
   (if needed: Camera <-> TPG <-> Camera)
```

---

## 14. Document history

| Version | Notes |
|---------|-------|
| 1.0 | Initial lab bring-up capture |
| 1.1 | Reformatted for team use; clarified that MTU is **not** an official Altera requirement and is a lab-path workaround only |
| 1.2 | Added customer demo fast-start section for a pre-provisioned board and microSD card |
| 1.3 | Replaced the MTU-400 recommendation with validated Ethernet triage after a replacement board passed full-size traffic and stable GUI operation at MTU 1500 |
