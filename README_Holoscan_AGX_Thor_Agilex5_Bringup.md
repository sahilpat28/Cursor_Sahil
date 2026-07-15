# Holoscan Sensor Bridge Bring-up Notes
## NVIDIA AGX Thor + Agilex 5 Modular Development Kit

This document records the bring-up steps, issues encountered, debug observations, and fixes used while running the Altera/NVIDIA Holoscan Sensor Bridge demo with NVIDIA AGX Thor as host and Agilex 5 Modular Development Kit as the FPGA platform.

---

## 1. Hardware and Software Setup

### Host

- NVIDIA Jetson AGX Thor Developer Kit
- JetPack 7.2 / L4T R39.2

Verify with:

```bash
cat /etc/nv_tegra_release
```

Expected:

```text
# R39 (release), REVISION: 2.0
```

### FPGA Boards / Designs Used

Two Agilex 5 designs were tested.

#### 10GbE Design

```text
AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE.sof
```

Repository path:

```text
fpga/altera/AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE
```

#### 25GbE Design

```text
AGX_5E_065A_Modular_DevKit_HSB_MIPI_25GbE.sof
```

Repository path:

```text
fpga/altera/AGX_5E_065A_Modular_DevKit_HSB_MIPI_25GbE
```

### Repository Used

```bash
git clone -b altera-release-2.6.0 https://github.com/altera-fpga/holoscan-sensor-bridge.git
cd holoscan-sensor-bridge
git lfs pull
```

---

## 2. Docker Build and Demo Container

On AGX Thor:

```bash
cd /home/alterademo/holoscandemo25G/holoscan-sensor-bridge
sh docker/build.sh --igpu
```

The first Docker build can take a significant amount of time.

After the image is built:

```bash
xhost +
sh docker/demo.sh
```

Inside the container, tools such as `hololink-enumerate` are installed in:

```bash
/usr/local/bin/hololink-enumerate
```

Use:

```bash
hololink-enumerate
```

Do not use this path inside the demo container:

```bash
./tools/enumerate/hololink-enumerate
```

---

## 3. 10GbE Bring-up

### 3.1 Program FPGA

Program the Group B / 10GbE SOF:

```text
AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE.sof
```

Example Quartus command:

```bash
quartus_pgm -c 1 -m jtag -o "p;AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE.sof"
```

### 3.2 Check Thor Ethernet Link

On AGX Thor host:

```bash
for i in 0 1 2 3; do
  echo "---- mgbe${i}_0 ----"
  sudo ethtool mgbe${i}_0 | grep -E "Speed|Link detected"
done
```

Expected for a working 10G setup:

```text
---- mgbe0_0 ----
Speed: 10000Mb/s
Link detected: yes
```

### 3.3 Configure Thor IP

```bash
EN0=mgbe0_0

sudo nmcli connection delete hololink-$EN0 2>/dev/null || true
sudo nmcli con add con-name hololink-$EN0 ifname $EN0 type ethernet ip4 192.168.0.101/24
sudo nmcli connection modify hololink-$EN0 +ipv4.routes 192.168.0.2/32
sudo nmcli connection up hololink-$EN0
```

Check route:

```bash
ip route | grep 192.168.0
```

Expected:

```text
192.168.0.0/24 dev mgbe0_0 ...
192.168.0.2 dev mgbe0_0 ...
```

Ping FPGA:

```bash
ping 192.168.0.2
```

Expected:

```text
64 bytes from 192.168.0.2
```

### 3.4 Enumerate HSB

Inside Docker:

```bash
hololink-enumerate
```

Successful output example:

```text
mac_id=CA:FE:C0:FF:EE:10
hsb_ip_version=0x2603
fpga_crc=0x0
ip_address=192.168.0.2
fpga_uuid=7b1fa8c7-31aa-44b6-abcc-eac134461fdc
serial_number=01000000000000
interface=mgbe0_0
board=N/A
```

This confirms:

```text
Ethernet link: OK
HSB enumeration: OK
FPGA reachable: OK
```

### 3.5 Run Camera Demo

Single camera:

```bash
python3 examples/linux_agx5_player.py --cam 0 --lines 1080 --frame-rate 30
```

Camera 1:

```bash
python3 examples/linux_agx5_player.py --cam 1 --lines 1080 --frame-rate 30
```

Stereo:

```bash
python3 examples/linux_agx5_player_stereo.py
```

Headless test:

```bash
python3 examples/linux_agx5_player.py --headless --frame-limit 100 --cam 0 --lines 1080 --frame-rate 30
```

---

## 4. Issues Encountered During 10G Bring-up

### Issue 1: No Ethernet Link / No Carrier

Observed:

```text
Speed: 10000Mb/s
Link detected: no
```

or:

```text
NO-CARRIER
Destination Host Unreachable
```

Ping output:

```text
From 192.168.0.101 icmp_seq=1 Destination Host Unreachable
```

Meaning:

- `192.168.0.101` is Thor's own IP.
- Thor is saying it cannot reach the FPGA at `192.168.0.2`.
- This is a physical/link issue, not Docker or Holoscan.

Resolution:

- Confirm correct FPGA SOF.
- Confirm correct SFP/QSFP cable.
- Confirm correct breakout leg.
- Confirm correct Thor interface.
- Use the 10G FPGA design when Thor is in default 10G mode.

### Issue 2: Wrong Tool Path

Command failed:

```bash
./tools/enumerate/hololink-enumerate
```

Error:

```text
No such file or directory
```

Resolution:

```bash
which hololink-enumerate
```

Output:

```text
/usr/local/bin/hololink-enumerate
```

Use:

```bash
hololink-enumerate
```

### Issue 3: Camera I2C Transaction Error

Observed:

```text
hololink._hololink.TransactionError: i2c_transaction i2c_address=0x37
```

and for camera 1:

```text
hololink._hololink.TransactionError: i2c_transaction i2c_address=0x1a
```

Meaning:

- FPGA/HSB path is working.
- Camera sensor is not responding over I2C.

Checks performed:

- Camera cable orientation.
- Pin 1 to pin 1 alignment.
- Correct MIPI connector.
- Camera power/reset sequencing.
- Reprogram FPGA after camera connection.

The camera I2C started working after reseating/rechecking the camera setup.

Successful camera configuration log:

```text
Configuring camera with frame format: Width=1920, Height=1080, Framerate=30, Pixel Format=PixelFormat.RAW_10
Starting camera
Stopping camera
```

### Issue 4: GUI / Holoviz Failure

Observed:

```text
Failed to initialize glfw
Authorization required, but no authorization protocol specified
XDG_RUNTIME_DIR is invalid or not set in the environment
```

Meaning:

- Camera and streaming path may be working.
- Display permission is failing.

Resolution on Thor host:

```bash
xhost +local:root
xhost +local:docker
xhost +
```

Restart Docker:

```bash
sh docker/demo.sh
```

Inside Docker:

```bash
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
```

Then run the demo again.

### Issue 5: Kernel Receiver Buffer Warning

Observed:

```text
Kernel receiver buffer size is too small; performance will be unreliable.
Resolve this with "echo 2621440 | sudo tee /proc/sys/net/core/rmem_max"
```

Resolution on Thor host:

```bash
echo 2621440 | sudo tee /proc/sys/net/core/rmem_max
```

For 4K mode, use a larger buffer:

```bash
echo 10420224 | sudo tee /proc/sys/net/core/rmem_max
```

---

## 5. 25GbE Bring-up

### 5.1 Initial 25G Problem

Initially the 25G design did not link.

Observed:

```text
Speed: 10000Mb/s
Link detected: no
```

Root cause:

- AGX Thor defaults to `10GbE x4` mode on the QSFP/MGBE ports.
- The 25G FPGA design requires `25GbE x4`.
- Thor does not support runtime switching between 10G and 25G using normal Linux network settings.
- `nmcli`, IP settings, Docker, and FPGA reprogramming alone cannot switch Thor to 25G.

### 5.2 25G Switching Method

Altera provided capsule files for switching Thor bootloader/QSPI configuration between 10G and 25G.

Required files:

```text
Tegra_Thor_BL_7.2_10G.Cap
Tegra_Thor_BL_7.2_25G.Cap
```

JetPack requirement:

```text
JetPack 7.2 / L4T R39.2
```

Verified using:

```bash
cat /etc/nv_tegra_release
```

Output:

```text
# R39 (release), REVISION: 2.0
```

### 5.3 Current Slot Before Switching

Before switching, check:

```bash
sudo nvbootctrl get-current-slot
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

Output before switching:

```text
1
10000
10000
10000
10000
```

Recorded:

```text
slot 1 = 10G
```

### 5.4 Apply 25G Capsule

Copy capsule files to Thor home directory:

```bash
cd ~
ls -lh *.Cap
```

Then apply the 25G capsule:

```bash
sudo nv_bootloader_capsule_updater.sh -q ./Tegra_Thor_BL_7.2_25G.Cap
sudo reboot
```

After reboot:

```bash
sudo nvbootctrl get-current-slot
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

Output:

```text
0
25000
25000
25000
25000
```

Recorded:

```text
slot 0 = 25G
slot 1 = 10G
```

### 5.5 Reverting Back to 10G

Since 10G is slot 1:

```bash
sudo nvbootctrl set-active-boot-slot 1
sudo reboot
```

Verify:

```bash
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

Expected:

```text
10000
10000
10000
10000
```

### 5.6 Switching Back to 25G

Since 25G is slot 0:

```bash
sudo nvbootctrl set-active-boot-slot 0
sudo reboot
```

Verify:

```bash
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

Expected:

```text
25000
25000
25000
25000
```

---

## 6. 25G FPGA Demo Flow

Once Thor is in 25G mode:

```text
slot 0 active
MGBE speeds = 25000
```

Program the 25G FPGA:

```text
AGX_5E_065A_Modular_DevKit_HSB_MIPI_25GbE.sof
```

Check link:

```bash
for i in 0 1 2 3; do
  echo "---- mgbe${i}_0 ----"
  sudo ethtool mgbe${i}_0 | grep -E "Speed|Link detected"
done
```

Expected:

```text
Speed: 25000Mb/s
Link detected: yes
```

Configure IP:

```bash
EN0=mgbe0_0

sudo nmcli connection delete hololink-$EN0 2>/dev/null || true
sudo nmcli con add con-name hololink-$EN0 ifname $EN0 type ethernet ip4 192.168.0.101/24
sudo nmcli connection modify hololink-$EN0 +ipv4.routes 192.168.0.2/32
sudo nmcli connection up hololink-$EN0
```

Ping:

```bash
ping 192.168.0.2
```

Enter container:

```bash
cd /home/alterademo/holoscandemo25G/holoscan-sensor-bridge
xhost +
sh docker/demo.sh
```

Inside container:

```bash
hololink-enumerate
```

Run demo:

```bash
python3 examples/linux_agx5_player.py --cam 0 --lines 1080 --frame-rate 30
```

Stereo:

```bash
python3 examples/linux_agx5_player_stereo.py
```

---

## 7. Current Known Good State

### 10G

```text
slot 1 = 10G
FPGA image = AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE.sof
MGBE speed = 10000
HSB enumerate = PASS
Camera I2C = PASS
Headless streaming = PASS
GUI requires xhost/XDG setup
```

### 25G

```text
slot 0 = 25G
FPGA image = AGX_5E_065A_Modular_DevKit_HSB_MIPI_25GbE.sof
MGBE speed = 25000
25G mode enabled successfully
```

---

## 8. Useful Debug Commands

### Check JetPack / L4T

```bash
cat /etc/nv_tegra_release
```

### Check MGBE Speeds

```bash
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

### Check Active Boot Slot

```bash
sudo nvbootctrl get-current-slot
```

### Check Link Status

```bash
for i in 0 1 2 3; do
  echo "---- mgbe${i}_0 ----"
  sudo ethtool mgbe${i}_0 | grep -E "Speed|Link detected"
done
```

### Configure IP

```bash
EN0=mgbe0_0

sudo nmcli connection delete hololink-$EN0 2>/dev/null || true
sudo nmcli con add con-name hololink-$EN0 ifname $EN0 type ethernet ip4 192.168.0.101/24
sudo nmcli connection modify hololink-$EN0 +ipv4.routes 192.168.0.2/32
sudo nmcli connection up hololink-$EN0
```

### Ping FPGA

```bash
ping 192.168.0.2
```

### Enumerate HSB

```bash
hololink-enumerate
```

### Run Single Camera

```bash
python3 examples/linux_agx5_player.py --cam 0 --lines 1080 --frame-rate 30
```

### Run Headless

```bash
python3 examples/linux_agx5_player.py --headless --frame-limit 100 --cam 0 --lines 1080 --frame-rate 30
```

### Run Stereo

```bash
python3 examples/linux_agx5_player_stereo.py
```

### Fix GUI Permission

On Thor host:

```bash
xhost +local:root
xhost +local:docker
xhost +
```

Inside Docker:

```bash
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
```

### Fix Receiver Buffer Warning

```bash
echo 2621440 | sudo tee /proc/sys/net/core/rmem_max
```

For larger frames:

```bash
echo 10420224 | sudo tee /proc/sys/net/core/rmem_max
```

---

## 9. Lessons Learned

1. Thor default QSFP mode is 10G.
2. The 25G FPGA image will not link unless Thor is booted in 25G mode.
3. 10G/25G switching is not runtime-configurable using `nmcli`.
4. Capsule-based slot switching allows 10G/25G switching without wiping the Linux rootfs.
5. `hololink-enumerate` proves FPGA/HSB communication.
6. Camera I2C errors are separate from Ethernet link errors.
7. GUI/Holoviz failures are often X11 authorization problems, not camera/FPGA problems.
8. Always use `Ctrl+C` to stop apps, not `Ctrl+Z`.
9. `.sof` programming is volatile; reprogram FPGA after a board power cycle.
10. Record boot slot mapping before switching modes.

---

## 10. Final Slot Mapping From This Bring-up

```text
slot 0 = 25G
slot 1 = 10G
```

Switch to 25G:

```bash
sudo nvbootctrl set-active-boot-slot 0
sudo reboot
```

Switch to 10G:

```bash
sudo nvbootctrl set-active-boot-slot 1
sudo reboot
```
