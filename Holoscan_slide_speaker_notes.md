# Holoscan Sensor Bridge 25G Presentation Speaker Notes

## Detailed slide-by-slide talk track and technical Q&A

Prepared for presenting `DFAE_Cert_ILT_2026_HSB.pptx` to a technical audience.

Audience assumption: FPGA, embedded, networking, vision, and AI engineers.

Presentation objective:

- Explain why Holoscan Sensor Bridge matters.
- Position Agilex 5 as the deterministic sensor-ingest and Ethernet-transport layer.
- Explain how the NVIDIA host uses Holoscan for processing, visualization, and AI inference.
- Show what was actually brought up on AGX Thor.
- Be transparent about 10G/25G switching, MAX10 firmware, CoE behavior, and demo limitations.

---

## Executive summary for presenter

The presentation should land three main messages:

1. FPGA value:
   Agilex 5 handles real-world sensor interfaces, deterministic ingest, timing, protocol conversion, packetization, and Ethernet transport.

2. NVIDIA Holoscan value:
   Holoscan provides the host-side graph framework for GPU accelerated processing, AI inference, and visualization.

3. Demo proof:
   The 10GbE and 25GbE Agilex 5 Holoscan Sensor Bridge demos were both brought up on AGX Thor. 10G is the simpler stable path. 25G works, but Thor requires boot-slot switching and the CoE interface refresh workaround for repeated runs.

Recommended verbal opener:

> Today I will walk through how Agilex 5 bridges high-bandwidth sensor data into NVIDIA Holoscan over Ethernet. The FPGA owns deterministic sensor capture and transport; the NVIDIA platform owns GPU processing, AI inference, and visualization. I will cover the architecture, available reference designs, the demo setup, and the practical bring-up lessons from both 10GbE and 25GbE on AGX Thor.

Recommended closing:

> The key takeaway is that this architecture gives customers a scalable path from custom sensors to GPU processing over standard Ethernet. Altera provides the sensor-facing FPGA flexibility and deterministic transport, while NVIDIA Holoscan provides the application and AI pipeline on the host.

---

## Slide 1 - Holoscan Sensor Bridge 25G

### Purpose of the slide

Introduce the topic and set the technical scope: Holoscan Sensor Bridge using 25GbE-capable Agilex 5 design with NVIDIA host processing.

### What to say

> This session is about the Holoscan Sensor Bridge 25G demo. We are connecting sensor data into NVIDIA Holoscan using an Agilex 5 FPGA as the sensor-ingest and Ethernet-transport bridge. The demo focuses on MIPI camera capture, FPGA formatting and packetization, Ethernet transport, and host-side Holoscan processing.

### Technical details to emphasize

- The FPGA is not only a pass-through device.
- It terminates sensor protocols, formats data, and packetizes it.
- The NVIDIA host receives the stream and runs Holoscan operators.
- 25G is important because modern sensors and multi-camera systems exceed simple 1G/10G bandwidth limits.

### Transition

> I will start with Holoscan concepts, then show how the FPGA IP and Altera reference designs fit into that model.

---

## Slide 2 - Agenda

### Purpose of the slide

Set expectations for the flow of the session.

### What to say

> The agenda starts with concepts: Holoscan, Holoscan Sensor Bridge, and FPGA-based sensor-to-Ethernet conversion. Then I will cover the market relevance, available reference designs, how to select the right design, and finally the demo setup, hardware architecture, software flow, and bring-up observations.

### Technical details to emphasize

- The audience should expect both architecture and practical bring-up details.
- The later slides include hardware and software internals, not only demo commands.

### Suggested pacing

- Slides 3-5: concept and value proposition.
- Slides 6-11: market and design discovery.
- Slides 12-17: demo setup.
- Slides 18-27: FPGA architecture and transport.
- Slides 28-31: software, app flow, and platform caveats.

---

## Slide 3 - Holoscan Overview

### Purpose of the slide

Explain the Holoscan programming model: applications, fragments, operators, and data flow.

### What to say

> Holoscan is NVIDIA's framework for building low-latency streaming AI pipelines. A Holoscan application is composed of fragments. A fragment contains a graph of operators, and each operator performs a unit of work. Operators receive streaming inputs, process data, and publish outputs to the next operator.

### Explain the terms

- Application: complete pipeline.
- Fragment: partition of the application, possibly deployable across systems.
- Operator: computational or IO block.
- Source operator: introduces data into the graph.
- Sink operator: consumes or displays data.

### Tie to this demo

> In this demo, the Holoscan Sensor Bridge receiver is effectively the source operator. It receives camera frames from the FPGA. The image-processing, demosaic, format conversion, and inference blocks are processing operators. Holoviz is the visualization sink.

### Technical emphasis

- This graph abstraction is useful for real-time sensor systems.
- It separates ingest, preprocessing, inference, and visualization.
- It allows the FPGA transport layer to be integrated into a GPU processing pipeline.

### Likely audience question

Q: Is Holoscan only for medical?

A: No. Holoscan originated strongly in medical and edge AI use cases, but the framework applies to any streaming sensor pipeline: robotics, industrial vision, broadcast, wireless, aerospace, and defense.

---

## Slide 4 - Holoscan Sensor Bridge IP

### Purpose of the slide

Explain what the HSB IP does in the FPGA and how it interacts with host software.

### What to say

> Holoscan Sensor Bridge has an FPGA IP component and a host software component. The FPGA IP provides both a control plane and a data transport plane. The control plane gives host software access to HSB registers, external IP registers over APB, and sensor interfaces such as I2C or SPI. The data plane moves frames between FPGA and host over high-speed Ethernet.

### Key technical points

- HSB IP is open-source NVIDIA FPGA IP under Apache 2.0.
- It provides internal registers and external control interfaces.
- It can control sensors through interfaces such as I2C/SPI.
- It packetizes frame data for Ethernet transport.
- It presents data to Holoscan through CPU or GPU memory.

### RoCE versus CoE

> On platforms with ConnectX, HSB can use RoCEv2. AGX Thor does not use RoCEv2 for this path. Thor uses Camera over Ethernet, or CoE, which is RDMA-like for receive acceleration.

### Important nuance

- CoE is receive-side acceleration only.
- It is not identical to RoCEv2.
- The FPGA packet format must match the host driver expectation.

### Likely audience question

Q: Can the same HSB IP support both Linux socket and accelerated paths?

A: Yes, but the FPGA and host configuration must match the chosen transport. Linux socket mode is simpler and useful for debug. CoE/RoCE paths are used for higher performance.

---

## Slide 5 - Altera FPGA-based Sensor-to-Ethernet Converters

### Purpose of the slide

Position Altera FPGAs as flexible sensor-ingest and Ethernet conversion devices.

### What to say

> Altera FPGAs enable sensor-to-Ethernet conversion at the edge. Many sensors do not connect directly to GPU platforms. They use interfaces like MIPI CSI, JESD204, LVDS, SLVS-EC, SDI, SPI, I2C, or custom GPIO. The FPGA terminates these protocols, optionally preprocesses or synchronizes data, and sends it over Ethernet to GPU or CPU compute.

### Value proposition

- Ultra-low latency ingest.
- Protocol flexibility.
- Deterministic timing.
- Bandwidth scaling from 10G to 25G, 100G, and beyond.
- Offload preprocessing before the host.
- Reduces system integration complexity.

### Strong phrase to use

> The FPGA solves the hard real-time sensor and transport problem; Holoscan solves the host-side GPU processing and AI workflow.

### Technical audience angle

- Mention that Ethernet decouples sensor location from host location.
- FPGAs can aggregate, timestamp, packetize, and align streams before the host sees them.
- Customers can customize the FPGA for proprietary sensors or custom preprocessing.

---

## Slide 6 - Markets / Use Cases

### Purpose of the slide

Show that this architecture applies broadly.

### What to say

> The architecture is relevant wherever high-rate sensor data needs deterministic capture and GPU-side processing. Examples include robotics, industrial inspection, medical imaging, studio production, wireless, and defense.

### Market-by-market talk track

Robotics:

- Multi-camera, lidar, radar, IMU, and actuator feedback.
- Need timestamping, synchronization, low latency, and sensor fusion.
- FPGA handles deterministic ingest; Holoscan handles perception and AI.

Industrial:

- Machine vision, defect inspection, thermal imaging, vibration monitoring.
- FPGA handles triggering, deterministic capture, and transport.
- Host runs classification, measurement, and visualization.

Medical:

- Endoscopy, ultrasound, microscopy, surgical robotics, AI diagnostics.
- FPGA interfaces to specialized imaging sensors.
- Holoscan handles visualization, enhancement, segmentation, inference.

Studio / broadcast:

- Low-latency video ingest, metadata, switching, effects.
- FPGA converts and aligns media streams.

Wireless:

- IQ/baseband data over JESD204 or custom RF paths.
- FPGA packetizes high-rate radio data.
- Host analyzes, visualizes, or runs AI-assisted signal processing.

Defense / aerospace:

- Radar, EO/IR, lidar, SIGINT.
- FPGA provides deterministic capture and transport.
- Host performs sensor fusion or target detection.

### Key message

> The same architecture repeats across markets: sensor diversity at the FPGA, compute scalability at the host.

---

## Slide 7 - Available Today

### Purpose of the slide

Show available reference designs and bandwidth options.

### What to say

> Altera has multiple Holoscan-related sensor-to-Ethernet reference designs. For Agilex 5, the key designs are the Group B 10GbE design and the Group A 25GbE design. These give customers a starting point depending on board type, bandwidth, and number of streams.

### Explain each design

- Stratix 10 sensor processing kit: earlier HSB-related platform.
- Agilex 5 Group B 10GbE: simpler two-camera path.
- Agilex 5 Group A 25GbE: higher bandwidth, multi-stream, CoE-oriented path.

### Customer guidance

> If the customer wants a stable first evaluation, start with 10GbE. If the value proposition is bandwidth, multi-stream scaling, or 25G transport, use the Group A 25GbE design.

---

## Slide 8 - Step by Step Guide

### Purpose of the slide

Guide field teams on qualifying customer opportunities.

### What to say

> This is a discovery workflow for customer engagement. Start by identifying customers using GPUs for edge AI or high-rate sensor processing. Then understand the sensors, protocols, bandwidth, and AI throughput requirement. Finally, map that to an Altera reference design.

### Discovery questions

- Which GPU or host platform is used?
- Which sensors are used?
- What are the sensor interfaces?
- How many streams?
- What resolution and frame rate?
- What latency budget?
- What Ethernet speed is required?
- Is FPGA preprocessing needed?
- Does the customer need deterministic trigger/sync?

### Technical framing

> The right design is chosen from the data rate and system architecture, not just from the camera type.

---

## Slide 9 - Altera FPGA Developer Site

### Purpose of the slide

Point audience to customer-facing collateral.

### What to say

> The Altera FPGA Developer Site is the first stop for customers. It provides reference design descriptions, supported hardware, Quartus version requirements, and links to GitHub documentation.

### Why it matters

- Reduces risk of using wrong branch or wrong SOF.
- Provides official README flow.
- Links to design collateral and prebuilt images.

### Practical tip

> Always verify the exact FPGA board group and Quartus version before programming a design.

---

## Slide 10 - Altera GitHub Repository

### Purpose of the slide

Explain the GitHub repository as engineering source of truth.

### What to say

> GitHub contains the latest source tree, README instructions, example scripts, FPGA design folders, and release assets. For this bring-up we used the `altera-release-2.6.0` branch.

### Designs in branch

- 25GbE design for Agilex 5 Group A MDK.
- 10GbE design for Agilex 5 Group B MDK.
- 10GbE ES variant for earlier Group B hardware.

### Practical warning

> Do not mix the 065A 25G SOF with Thor in 10G mode. Do not mix Group A and Group B images. The link or application will fail in ways that look like network issues.

---

## Slide 11 - What's in a Design

### Purpose of the slide

Show that the reference design is complete collateral, not just RTL.

### What to say

> Each design includes overview documentation, hardware and software requirements, prebuilt SOF/JIC files, operating instructions, Platform Designer project source, and expansion resources.

### Technical value

- Customers can run prebuilt files quickly.
- Customers can modify Platform Designer source later.
- The README includes register maps, hierarchy, constraints, and design assumptions.

### Customer positioning

> This supports both evaluation and engineering adoption. Use prebuilt binaries for demo, then use source for customization.

---

## Slide 12 - The Demo

### Purpose of the slide

Transition to hands-on demonstration.

### What to say

> Now we move from architecture to the actual demo. The demo has three major parts: programming the FPGA, configuring the AGX Thor host, and running Holoscan applications.

### Transition

> I will first cover hardware requirements and connections, then software setup and commands.

---

## Slide 13 - Hardware Requirements

### Purpose of the slide

List required physical components.

### What to say

> The demo requires the Agilex 5 MDK, IMX678 4K cameras, MIPI cables, camera mounting hardware, a NVIDIA AGX Thor or DGX Spark host, and a QSFP28 to 4x SFP28 cable for the Thor connection.

### Key technical details

- Group A board is used for 25GbE.
- Group B board is used for 10GbE.
- Camera module used is Framos FSM:GO IMX678C.
- MIPI cable orientation matters.
- QSFP28 breakout lane selection matters.

### Bring-up lesson

> For the 25G design, Thor must also be in 25G mode. A 25G FPGA image will not link to Thor if Thor is booted in default 10G mode.

---

## Slide 14 - Software Requirements

### Purpose of the slide

Identify required software tools.

### What to say

> On the host, we need JetPack, the Holoscan Sensor Bridge repository, Docker, and Holoscan dependencies. On the FPGA side, we need Quartus Programmer 26.1 to program the SOF or JIC.

### Important details

- Thor tested with JetPack 7.2 / L4T R39.2.
- HSB Docker build used `--igpu` for AGX Thor.
- Quartus Programmer is required for FPGA and MAX10 updates.

### Verbal correction if slide is generic

> For AGX Thor, use the iGPU Docker build path. Use dGPU only on a host with a discrete NVIDIA GPU.

---

## Slide 15 - Development Kit and Host System Connection Diagram

### Purpose of the slide

Explain physical data/control connections.

### What to say

> Sensor data enters the Agilex board through MIPI. The FPGA formats and packetizes the stream, then sends it over Ethernet through the SFP connector to the NVIDIA host. The host also sends control transactions, such as camera I2C configuration, through the HSB path.

### Debug logic

- If `ethtool` says no carrier: check cable, FPGA image, Thor mode.
- If `ping` fails: check IP and link.
- If `hololink-enumerate` fails: check HSB endpoint/network.
- If camera I2C fails but enumerate works: check MIPI power, MAX10, cable, camera.

---

## Slide 16 - Modular Development Kit Connector

### Purpose of the slide

Highlight connector and switch importance.

### What to say

> The MDK connector details matter. During bring-up we found that early production MDKs may have a MAX10 firmware issue where MIPI connector power is not enabled. That causes camera I2C failures even though the FPGA and Ethernet path are working.

### MAX10 fix

Explain:

1. Set SW4 to ON to put MAX10 on the JTAG chain.
2. Reflash MAX10 with `max10_top_rtl_v1p1p6_fw_v2p0p1.pof`.
3. Power off the board.
4. Set SW4 back to OFF so FPGA appears on JTAG again.

### Key message

> Camera I2C failure is not always software. On early MDKs, it can be missing MIPI connector power due to MAX10 firmware.

---

## Slide 17 - Run Applications

### Purpose of the slide

Explain high-level execution flow.

### What to say

> There are two sides to running the demo: program the Agilex FPGA and run the Holoscan application on the NVIDIA host.

### FPGA side

- Program `.sof` through JTAG for volatile demo.
- Program `.jic` to flash for non-volatile boot.

### Host side

For AGX Thor:

```bash
sh docker/build.sh --igpu
sh docker/demo.sh
```

Then run a camera app.

### Correct customer demo command

For two cameras in 25G CoE mode:

```bash
python3 examples/agx5_multiviewer.py --cam 2 --lines 2160 --frame-rate 30 --receiver-type coe
```

### Note

The slide may show `--cam 8`; explain that `--cam 8` is for eight logical streams. With two physical cameras, use `--cam 2`.

---

## Slide 18 - Hardware

### Purpose of the slide

Transition into FPGA architecture.

### What to say

> Now let's look inside the FPGA design to understand how the raw camera data becomes Ethernet packets for the Holoscan host.

---

## Slide 19 - The Design

### Purpose of the slide

Show high-level FPGA block diagram.

### What to say

> The design starts with two MIPI camera inputs. Agilex 5 receives the MIPI data, converts it into streaming video, packs it into the format expected by HSB software, routes it into the HSB IP, and sends it to the host over Ethernet.

### Technical breakdown

- IMX678 cameras provide MIPI CSI data.
- MIPI D-PHY receives physical lanes.
- CSI-2 IP converts to internal stream.
- VVP/broadcast logic packs/replicates data.
- HSB IP packetizes and controls transport.
- GTS Ethernet sends data to Thor.

### Key message

> Altera logic wraps and adapts around NVIDIA HSB IP to make it usable with Agilex hardware and Altera Ethernet IP.

---

## Slide 20 - Architecture Overview

### Purpose of the slide

Explain the Platform Designer subsystem structure.

### What to say

> The design is made of four major subsystems: MIPI ingest, VVP broadcast and packing, HSB subsystem, and Ethernet subsystem.

### Subsystem details

1. MIPI subsystem:
   Receives physical camera streams using MIPI D-PHY and CSI-2 IP.

2. Broadcast/packing subsystem:
   Converts Altera Streaming Video Protocol into tightly packed CSI-style data expected by host software.

3. HSB subsystem:
   Instantiates NVIDIA HSB IP, exposes SIFs, APB control, I2C, and host interface.

4. Ethernet subsystem:
   Instantiates hardened Ethernet IP and supporting PHY/reset logic.

### Important statement

> Control and data both move over Ethernet. The same network path is used for discovery, register access, camera configuration, and frame transport.

---

## Slide 21 - Video Interface

### Purpose of the slide

Explain how video is represented before HSB.

### What to say

> The video interface is responsible for taking raw camera data from MIPI and converting it into the packed CSI format expected by the HSB host software.

### Technical details

- MIPI D-PHY supports two 4-lane receive interfaces.
- CSI-2 receiver supports RAW10 and RAW12.
- IMX678 does not support RAW8 in this demo path.
- ASVP carries four pixels in parallel.
- RAW10 wastes bits in ASVP representation.
- CSI packing removes that inefficiency.

### Why packing matters

> The host receiver expects line lengths and pixel packing to match the sensor mode. If the FPGA packing and software mode disagree, frames appear corrupted or fail downstream.

---

## Slide 22 - HSB Subsystem

### Purpose of the slide

Explain HSB IP integration.

### What to say

> The HSB subsystem instantiates NVIDIA HSB IP and the support logic needed to connect it to Altera video and Ethernet blocks.

### Technical details

- SIF inputs receive packed video streams.
- APB buses expose control registers.
- I2C peripheral path supports camera control.
- AVST/AXIS shims adapt interface conventions.
- System ID provides build identification.

### Important nuance

> The shims are not doing image processing. They adapt bus protocol, byte ordering, and streaming signal conventions between Altera and NVIDIA blocks.

---

## Slide 23 - 10GbE Design vs 25GbE Design

### Purpose of the slide

Compare design tradeoffs.

### What to say

> The 10G design is a simpler two-stream pipeline. The 25G design supports replicated streams and up to eight SIF paths, which is useful for bandwidth and multiviewer demonstrations.

### Technical differences

10G:

- Two video streams.
- Separate FIFOs.
- Simpler resource profile.
- Good for stable first demo.

25G:

- Streams replicated and presented to eight HSB SIFs.
- FIFOs incorporated into broadcaster IP.
- Higher bandwidth.
- More logic due to CoE packetizer support.

### Customer guidance

> Start with 10G for basic bring-up. Use 25G when demonstrating bandwidth, CoE, or multi-stream capability.

---

## Slide 24 - HSB Parameters

### Purpose of the slide

Point to NVIDIA HSB integration documentation.

### What to say

> HSB behavior is controlled by integration parameters. These define interface widths, enabled buses, SIF configuration, packetization behavior, and peripheral options.

### Why it matters

- FPGA configuration and host software must match.
- Packetizer settings matter for CoE.
- SIF count and width affect resource use and stream mapping.
- Incorrect parameters can cause link-level success but application-level failure.

---

## Slide 25 - HSB Wrapper Parameterization

### Purpose of the slide

Explain Altera's wrapper value.

### What to say

> Altera created a Platform Designer component and wrapper around NVIDIA HSB IP to make integration easier and less error-prone.

### Technical capabilities

- Exposes HSB parameters in GUI.
- Generates `HOLOLINK_def.svh`.
- Generates wrapper ports.
- Handles mixed SIF widths.
- Ties off unused signals.
- Supports register initialization.
- Keeps SPI0 visible when software expects it.
- Supports build revision and enumeration settings.

### Customer value

> This helps customers adapt HSB without hand-editing low-level macro files and wrapper logic.

---

## Slide 26 - Resource Utilization

### Purpose of the slide

Explain 25G resource cost.

### What to say

> The 25G design uses more FPGA resources because CoE packetizer support is enabled across multiple video SIFs.

### Important number

> The packetizer configuration adds approximately 7k ALMs per SIF. With eight SIFs, this becomes a significant resource increase.

### Technical tradeoff

- CoE support improves host receive path.
- Multi-SIF support improves stream scaling.
- Both increase resource usage.

### Customer guidance

> If the customer does not need CoE or eight SIFs, there may be opportunities to reduce resource use in a custom derivative.

---

## Slide 27 - Camera Over Ethernet on Thor

### Purpose of the slide

Explain Thor-specific transport.

### What to say

> AGX Thor does not use RoCEv2 in this path. It uses Camera over Ethernet, or CoE. CoE is RDMA-like for receive acceleration but has different driver and packetization requirements.

### Update from lab bring-up

> The slide says 25GbE CoE was not yet brought up. Our lab bring-up did validate 25GbE CoE on AGX Thor.

### Current workaround

For repeated 25G CoE runs:

```bash
sudo ip link set mgbe0_0 down ; sudo ip link set mgbe0_0 up
```

### Why workaround is needed

- Thor CoE repeated-run stability issue has been observed.
- Refreshing MGBE resets interface state before the next run.
- Recommended by Sho-san for 25G AGX Thor demo flow.

### Important caveat

> For customer demos, run CoE mode only for the 25G path. Use Linux socket mode mainly as a diagnostic fallback.

---

## Slide 28 - Software

### Purpose of the slide

Transition from FPGA hardware to host software.

### What to say

> Now we move from the FPGA data path to the host-side software that receives frames, configures cameras, runs image processing, and executes AI workloads.

---

## Slide 29 - Altera Builds on NVIDIA

### Purpose of the slide

Explain AGX5-specific software additions.

### What to say

> Altera added Python classes and applications to support the IMX678 camera and AGX5 FPGA design inside the Holoscan Sensor Bridge software framework.

### Software components

- `agx5_imx678.py`: sensor class.
- `agx5_imx678_mode.py`: supported modes.
- `linux_agx5_player.py`: single camera.
- `linux_agx5_player_stereo.py`: stereo.
- `agx5_multiviewer.py`: multi-stream viewer.
- `linux_body_pose_estimation_agx5.py`: YOLOv8 body pose.
- `linux_tao_peoplenet_agx5.py`: PeopleNet.

### Technical details

The camera class manages:

- I2C register access.
- Start/stop sequences.
- Gain control.
- Mode configuration.
- Pixel format assumptions.
- CSI line-byte calculation.

### Important bring-up lesson

> If camera I2C fails, the application cannot configure the sensor even if the Ethernet and HSB path are working.

---

## Slide 30 - Multiviewer Flow

### Purpose of the slide

Explain how the application starts and configures streams.

### What to say

> The multiviewer application starts with device discovery. It enumerates the HSB device, selects data channels, creates camera objects, configures modes, builds the Holoscan graph, and then starts streaming.

### Flow

1. Enumerate HSB at `192.168.0.2`.
2. Read board UUID.
3. Choose Group A or Group B strategy.
4. Select camera channels.
5. Configure IMX678 cameras.
6. Choose receiver type: auto, linux, coe, or roce.
7. Build receiver, conversion, demosaic, and visualization paths.

### Demo guidance

> With two physical cameras, use `--cam 2`. The eight-camera mode is for logical replicated streams on the Group A design, not necessarily eight physical cameras.

---

## Slide 31 - NVIDIA System Ethernet Comparison

### Purpose of the slide

Explain host Ethernet mode limitations.

### What to say

> AGX Thor defaults to 10GbE mode and does not dynamically switch between 10GbE x4 and 25GbE x4 using normal Linux network commands.

### Bring-up result

> We used capsule/boot-slot switching. On our system:

- Slot 0 = 25G.
- Slot 1 = 10G.

### Commands

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

Check:

```bash
sudo nvbootctrl get-current-slot
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

### Key message

> This is not an `nmcli` setting. It is a boot configuration mode.

---

## Slide 32 - Closing

### Purpose of the slide

End with key customer takeaways.

### What to say

> In summary, we validated an end-to-end path from MIPI cameras through Agilex 5, over Ethernet, into NVIDIA Holoscan on AGX Thor. The FPGA provides deterministic sensor ingest and transport, while Holoscan provides GPU processing, visualization, and AI.

### Final takeaways

- 10G path is stable and recommended for first customer evaluation.
- 25G path works on AGX Thor after boot-slot switching.
- CoE repeated-run workaround is documented.
- MAX10 firmware update may be required on early MDKs.
- AI demos are possible once camera and transport are validated.

---

# Expanded Technical Q&A

## Q1. Why do we need an FPGA in this architecture?

Because many sensors do not connect directly to NVIDIA GPU platforms in the required format, timing, or bandwidth. The FPGA can terminate MIPI, JESD204, SLVS-EC, LVDS, SDI, SPI, I2C, GPIO, or custom protocols, then synchronize, preprocess, packetize, and transport the data over Ethernet.

## Q2. What is the exact division of work between FPGA and Holoscan?

The FPGA handles deterministic IO, sensor protocol adaptation, timing, packetization, and Ethernet transport. Holoscan handles host-side graph execution, GPU processing, image conversion, inference, visualization, and application logic.

## Q3. What does HSB IP provide?

HSB IP provides a host-accessible control plane and a high-speed data transport path. It exposes registers, sensor control interfaces, SIF data inputs, and Ethernet transport integration so host software can discover, configure, and receive data from the FPGA.

## Q4. What is a SIF?

SIF means Sensor Interface. It is a data input path into the HSB IP. The 25G design presents multiple video streams to multiple SIFs, enabling multi-stream or replicated-stream operation.

## Q5. What is the difference between Linux receiver, RoCE, and CoE?

Linux receiver uses the standard Linux network stack and is simpler but less accelerated. RoCE uses RDMA over Converged Ethernet and is supported on platforms with appropriate NICs such as ConnectX. CoE is Thor's Camera-over-Ethernet receive acceleration path and is RDMA-like on RX, but not the same as RoCE.

## Q6. Why does Thor need boot-slot switching for 10G and 25G?

AGX Thor does not dynamically switch MGBE between 10GbE x4 and 25GbE x4 from Linux networking tools. The mode is configured in the boot image/QSPI configuration. Capsule-based slot switching lets us move between modes by selecting the active boot slot and rebooting.

## Q7. What is the current boot-slot mapping?

From this bring-up:

- Slot 0 = 25G.
- Slot 1 = 10G.

This should always be verified on the actual unit with `nvbootctrl` and MGBE speed checks.

## Q8. How do we verify Thor is in 25G mode?

Run:

```bash
cat /sys/devices/platform/bus@0/*/net/mgbe*/speed
```

For 25G, expect `25000` for the MGBE ports. Then use `ethtool` to verify the connected port reports `Speed: 25000Mb/s` and `Link detected: yes`.

## Q9. Why did the initial 25G link fail?

Thor was still booted in default 10G mode. The 25G FPGA image cannot link correctly when Thor MGBE is configured for 10G. After switching Thor to 25G boot configuration, the link came up.

## Q10. Why did camera I2C fail even though HSB enumeration worked?

HSB enumeration proves the Ethernet and FPGA HSB endpoint are reachable. Camera I2C is a separate path through the FPGA to the sensor. On early MDK boards, MAX10 firmware did not power the MIPI connectors, so the cameras could not respond to I2C.

## Q11. How was the camera I2C issue fixed?

MAX10 was reflashed with the fixed image `max10_top_rtl_v1p1p6_fw_v2p0p1.pof`. SW4 was used to put MAX10 onto the JTAG chain, then returned to OFF so the FPGA appears on the JTAG chain again.

## Q12. Is the MAX10 issue expected for customer boards?

Customer release production boards are expected to ship with the fixed MAX10 image. Early production MDKs may need reflashing.

## Q13. What should be debugged first if a customer says the demo does not work?

Debug in this order:

1. FPGA programmed with correct SOF.
2. Thor in correct 10G or 25G mode.
3. `ethtool` link detected.
4. `ping 192.168.0.2`.
5. `hololink-enumerate`.
6. Camera I2C configuration.
7. Display/X11.
8. AI model or TensorRT engine.

## Q14. What does `hololink-enumerate` prove?

It proves that the host can discover the HSB endpoint over Ethernet and read board metadata. It does not prove camera power or camera I2C.

## Q15. Why is `--cam 8` not always correct?

The 25G Group A design can expose eight logical streams/SIFs, but the physical board may only have two cameras installed. For two physical cameras, use `--cam 2`. Use `--cam 8` only when the replicated-stream demo is intended and validated.

## Q16. Why does 25G use more FPGA resources?

The CoE packetizer logic is enabled per SIF. In this design it adds approximately 7k ALMs per SIF. With eight SIFs, this significantly increases resource utilization.

## Q17. What is the 25G repeated-run workaround?

Before every 25G CoE run after the first, refresh the interface:

```bash
sudo ip link set mgbe0_0 down ; sudo ip link set mgbe0_0 up
```

This resets the MGBE interface state and avoids repeated-run CoE instability observed on AGX Thor.

## Q18. Should customers use 10G or 25G?

For first evaluation and maximum stability, start with 10G. For bandwidth or 25G-specific demonstrations, use 25G with CoE mode and the MGBE refresh workaround.

## Q19. Why do GUI failures happen inside Docker?

Holoviz requires access to the host display. If X11 permissions or `XDG_RUNTIME_DIR` are missing, the pipeline may run but the visualizer fails. Use `xhost` on the host and set `XDG_RUNTIME_DIR` inside the container.

## Q20. Why does PeopleNet take a long time on first run?

The first run builds a TensorRT engine from the ONNX model. This can take several minutes. The engine is cached, so later runs start faster.

## Q21. Why did PeopleNet crash in InferenceOp?

The AGX5 script had metadata enabled. NVIDIA documentation notes an open metadata issue with InferenceOp. Setting `self.is_metadata_enabled = False` resolved the runtime crash.

## Q22. What is the best customer demo order?

Recommended order:

1. Show architecture slides.
2. Run `hololink-enumerate`.
3. Run single camera.
4. Run stereo or multiviewer.
5. Run body pose or PeopleNet.
6. Explain 10G/25G switch and MAX10 lessons.

## Q23. What is the biggest risk in a live 25G demo?

Repeated CoE run stability and host mode mismatch. Always verify Thor is in 25G mode and refresh `mgbe0_0` before repeated CoE demos.

## Q24. What is the strongest technical value proposition?

The architecture decouples sensor-specific real-time IO from host compute. Customers can adapt the FPGA for their sensor and still use a modern GPU software pipeline through Holoscan.

