# Holoscan Sensor Bridge Bring-up Guide

## NVIDIA AGX Thor + Agilex 5 Modular Development Kit

This guide summarizes the customer bring-up flow used for the Altera/NVIDIA Holoscan Sensor Bridge demo on NVIDIA AGX Thor with Agilex 5 Modular Development Kits. It covers the working 10GbE and 25GbE paths, the issues encountered, and the fixes applied.

---

## 1. Reference Documents

- Jetson AGX Thor ISO installation:  
  <https://docs.nvidia.com/jetson/agx-thor-devkit/user-guide/latest/quick_start.html#>

- Holoscan Sensor Bridge host setup, AGX Thor tab:  
  <https://docs.nvidia.com/holoscan/sensor-bridge/2.5.0/setup.html#sd-tab-item-3>

- Altera HSB 25GbE reference design:  
  <https://github.com/altera-fpga/holoscan-sensor-bridge/tree/altera-release-2.6.0/fpga/altera/AGX_5E_065A_Modular_DevKit_HSB_MIPI_25GbE>

- Altera HSB 10GbE reference design:  
  <https://github.com/altera-fpga/holoscan-sensor-bridge/tree/altera-release-2.6.0/fpga/altera/AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE>

---

## 2. System Used

### Host

- NVIDIA Jetson AGX Thor Developer Kit
- JetPack 7.2 / L4T R39.2

Verify:

```bash
cat /etc/nv_tegra_release
```

Expected:

```text
# R39 (release), REVISION: 2.0
```

### FPGA Images

10GbE / Group B:

```text
AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE.sof
```

25GbE / Group A:

```text
AGX_5E_065A_Modular_DevKit_HSB_MIPI_25GbE.sof
```

---

## 3. AGX Thor Base Installation

Follow the Jetson AGX Thor ISO quick start guide.

High-level flow:

1. Download the Jetson AGX Thor ISO image.
2. Create the bootable USB installer.
3. Boot AGX Thor from the USB installer.
4. Install the BSP to NVMe.
5. Remove the USB installer.
6. Boot from NVMe and complete Ubuntu OEM setup.
7. Verify JetPack/L4T version.

Reference:

```text
https://docs.nvidia.com/jetson/agx-thor-devkit/user-guide/latest/quick_start.html#
```

---

## 4. Host Setup for Holoscan Sensor Bridge

Use the AGX Thor tab in the Holoscan Sensor Bridge host setup guide.

Reference:

```text
https://docs.nvidia.com/holoscan/sensor-bridge/2.5.0/setup.html#sd-tab-item-3
```

Clone the Altera release branch:

```bash
git clone -b altera-release-2.6.0 https://github.com/altera-fpga/holoscan-sensor-bridge.git
cd holoscan-sensor-bridge
git lfs pull
```

Build the demo container:

```bash
sh docker/build.sh --igpu
```

Start the demo container:

```bash
xhost +
sh docker/demo.sh
```

Inside the container, use:

```bash
hololink-enumerate
```

The tool is installed under `/usr/local/bin`, so `./tools/enumerate/hololink-enumerate` may not exist in the container.

---

## 5. Common Network Configuration

The FPGA/HSB default IP is:

```text
192.168.0.2
```

Configure Thor:

```bash
EN0=mgbe0_0

sudo nmcli connection delete hololink-$EN0 2>/dev/null || true
sudo nmcli con add con-name hololink-$EN0 ifname $EN0 type ethernet ip4 192.168.0.101/24
sudo nmcli connection modify hololink-$EN0 +ipv4.routes 192.168.0.2/32
sudo nmcli connection up hololink-$EN0
```

Test:

```bash
ping 192.168.0.2
```

Check link status:

```bash
for i in 0 1 2 3; do
  echo "---- mgbe${i}_0 ----"
  sudo ethtool mgbe${i}_0 | grep -E "Speed|Link detected"
done
```

---

## 6. 10GbE Demo Flow

Program the 10GbE FPGA image:

```text
AGX_5E_065B_Modular_DevKit_HSB_MIPI_10GbE.sof
```

Expected Thor link:

```text
mgbe0_0
Speed: 10000Mb/s
Link detected: yes
```

Successful HSB enumeration example:

```text
mac_id=CA:FE:C0:FF:EE:10
hsb_ip_version=0x2603
ip_address=192.168.0.2
fpga_uuid=7b1fa8c7-31aa-44b6-abcc-eac134461fdc
interface=mgbe0_0
```

Run camera test:

```bash
python3 examples/linux_agx5_player.py --cam 0 --lines 1080 --frame-rate 30
```

Headless validation:

```bash
python3 examples/linux_agx5_player.py --cam 0 --lines 1080 --frame-rate 30 --headless --frame-limit 100
```

Stereo:

```bash
python3 examples/linux_agx5_player_stereo.py
```

---

## 7. 25GbE Demo Flow

### Important

AGX Thor does not support runtime switching between 10GbE x4 and 25GbE x4 through `nmcli` or normal Linux network settings. The Thor boot image / QSPI boot slot must be switched.

Capsule files used:

```text
Tegra_Thor_BL_7.2_10G.Cap
Tegra_Thor_BL_7.2_25G.Cap
```

Current slot mapping from this bring-up:

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

Check active slot and speed:

```bash
sudo nvbootctrl get-current-slot
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

Expected for 25G:

```text
0
25000
25000
25000
25000
```

Program the 25GbE FPGA image:

```text
AGX_5E_065A_Modular_DevKit_HSB_MIPI_25GbE.sof
```

Expected Thor link:

```text
mgbe0_0
Speed: 25000Mb/s
Link detected: yes
```

Run:

```bash
hololink-enumerate
python3 examples/linux_agx5_player.py --cam 0 --lines 1080 --frame-rate 30
```

For two physical cameras:

```bash
python3 examples/agx5_multiviewer.py --cam 2 --lines 2160 --frame-rate 30 --receiver-type coe
```

### 25G CoE Stability Workaround on AGX Thor

For the 25G demo on AGX Thor, use CoE mode demos only. If running the demo repeatedly, refresh the MGBE interface before every run after the first one:

```bash
sudo ip link set mgbe0_0 down
sudo ip link set mgbe0_0 up
```

Equivalent one-line command:

```bash
sudo ip link set mgbe0_0 down ; sudo ip link set mgbe0_0 up
```

This workaround was recommended for AGX Thor 25GbE demos to avoid issues seen on repeated CoE runs.

For debugging only, if CoE remains unstable, test with Linux receiver:

```bash
python3 examples/agx5_multiviewer.py --cam 2 --lines 1080 --frame-rate 30 --receiver-type linux
```

---

## 8. MAX10 MIPI Power Fix

### Symptom

Holoscan applications reached the FPGA/HSB, but camera configuration failed with I2C transaction errors:

```text
hololink._hololink.TransactionError: i2c_transaction i2c_address=0x37
hololink._hololink.TransactionError: i2c_transaction i2c_address=0x1a
```

### Root Cause

Early production MDK boards, both Group A and Group B, shipped with a bug in the MAX10 image. The buggy MAX10 image does not apply power to the MIPI connectors. Without MIPI connector power, camera I2C communication is impossible.

Customer release production boards are expected to ship with a fixed MAX10 image and should be plug-and-play. Currently available early boards may need MAX10 reflashing.

### Fix Applied

1. Switch MAX10 onto the JTAG chain by setting `SW4` on the carrier board to `ON`. This is the single switch nearest the HDMI connector.
2. Use Quartus Programmer GUI to reflash MAX10 with:

   ```text
   max10_top_rtl_v1p1p6_fw_v2p0p1.pof
   ```

3. Power off the board.
4. Set `SW4` back to `OFF` so the FPGA appears on the JTAG chain again.

After this MAX10 update, camera I2C configuration succeeded.

### Additional Note

Initial production MDK batches may have a carrier micro USB hub that is susceptible to ESD. If the carrier micro USB is not detected, for example Windows fails to read descriptors, use the standard JTAG connector and a Byte Blaster.

---

## 9. AI Demo Examples

### YOLOv8 Body Pose

Inside container:

```bash
apt-get update && apt-get install -y ffmpeg
pip3 install ultralytics onnx

cd examples
yolo export model=yolov8n-pose.pt format=onnx
trtexec --onnx=yolov8n-pose.onnx --saveEngine=yolov8n-pose.engine.fp32
cd -
```

Run:

```bash
python3 examples/linux_body_pose_estimation_agx5.py --cam 0 --lines 1080 --frame-rate 30
```

### TAO PeopleNet

Download model:

```bash
curl -L 'https://api.ngc.nvidia.com/v2/models/org/nvidia/team/tao/peoplenet/pruned_quantized_decrypted_v2.3.3/files?redirect=true&path=resnet34_peoplenet_int8.onnx' -o examples/resnet34_peoplenet_int8.onnx
```

Run:

```bash
python3 examples/linux_tao_peoplenet_agx5.py --cam 0 --lines 1080 --frame-rate 30
```

First run builds a TensorRT engine and can take several minutes.

If the PeopleNet AGX5 example crashes in `InferenceOp`, disable metadata in `examples/linux_tao_peoplenet_agx5.py`:

```python
self.is_metadata_enabled = False
```

---

## 10. Display and Runtime Notes

If Holoviz/GLFW fails:

```text
Failed to initialize glfw
Authorization required, but no authorization protocol specified
XDG_RUNTIME_DIR is invalid or not set
```

Run on Thor host before starting Docker:

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

For receiver buffer warnings:

```bash
echo 10420224 | sudo tee /proc/sys/net/core/rmem_max
```

Inside the container as root, omit `sudo`:

```bash
echo 10420224 > /proc/sys/net/core/rmem_max
```

Use `Ctrl+C` to stop demos. Avoid `Ctrl+Z`, which suspends jobs and can leave resources open.

---

## 11. Known Issues and Lessons Learned

- Thor defaults to 10GbE mode.
- 25GbE FPGA images need Thor booted in 25GbE mode.
- 10G/25G mode switching requires boot slot / capsule handling, not `nmcli`.
- Early MDK boards may need MAX10 reflashing to power MIPI connectors.
- Camera I2C errors can be caused by missing MIPI connector power, not only cable orientation.
- `hololink-enumerate` confirms the FPGA/HSB network path.
- GUI failures are often X11 authorization issues.
- `.sof` FPGA programming is volatile; reprogram after FPGA board power cycle.
- For customer demos on AGX Thor, 10GbE and Linux socket mode are the most stable paths. 25GbE CoE is available but may show stability issues under some multi-stream scenarios.

