# RTL Top-Level Selection

Use the correct top for your task:

```text
Quartus standalone compile/timing top:
  psk8_modem_quartus_top
  file: hdl/rtl/psk8_modem_quartus_top.v

Board integration modem core:
  psk8_modem_top
  file: hdl/rtl/psk8_modem_top.v
```

Do not compile `psk8_modem_top` as the standalone Quartus project top. It
exposes the full packed DAC/ADC sample buses and creates 1094 package I/O pins.
That is why Quartus reports:

```text
Design requires 1094 user-specified I/O pins -- too many to fit
```

For Quartus Prime Pro 26.1, open or run:

```text
hdl/synth/quartus/psk8_modem_agilex7.qpf
hdl/synth/quartus/run_quartus_compile.tcl
```

Both select `psk8_modem_quartus_top`.

