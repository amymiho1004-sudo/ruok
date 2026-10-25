# Hardware Wiring Notes

Raspberry Pi Zero 2 WH, all connections below use the standard 40-pin GPIO header.

## Pin reference (all components)

| Component | Pin/Wire | Raspberry Pi physical pin | Function |
|---|---|---|---|
| I2S microphone (ICS-43434) | VDD | 1 | 3.3V |
| I2S microphone | GND | 6 or 9 | Ground |
| I2S microphone | L/R (SEL) | 3.3V or GND | Channel select |
| I2S microphone | WS | 35 (GPIO19) | Word select / LRCLK (shared with speaker) |
| I2S microphone | SCK | 12 (GPIO18) | Bit clock / BCLK (shared with speaker) |
| I2S microphone | SD | 38 (GPIO20) | Data out (PCM_DIN) |
| Speaker amp (MAX98357A) | VIN | 2 or 4 | 5V |
| Speaker amp | GND | any GND pin | Ground |
| Speaker amp | BCLK | 12 (GPIO18) | Bit clock (shared with mic) |
| Speaker amp | LRC (WS) | 35 (GPIO19) | Word select (shared with mic) |
| Speaker amp | DIN | 40 (GPIO21) | Audio data in (PCM_DOUT) |
| Speaker amp | Output +/- | — | To the physical speaker driver |
| Motion sensor (LD2410C) | VCC | 2 or 4 | 5V |
| Motion sensor | GND | any GND pin | Ground |
| Motion sensor | TX | 10 (GPIO15 / RXD) | Sensor transmit → Pi receive |
| Motion sensor | RX | 8 (GPIO14 / TXD) | Sensor receive ← Pi transmit |
| Setup button (momentary) | Leg 1 | 5 (GPIO3) | Pulled up; LOW while pressed |
| Setup button | Leg 2 | 6 (GND) | Ground |
| Status LED (not wired yet) | Anode (+) | 11 (GPIO17), via a 220–330Ω resistor | Reserved, needs a resistor before connecting |
| Status LED | Cathode (-) | any GND pin | Ground |

Notes:
- GND pins available anywhere on the header: 6, 9, 14, 20, 25, 30, 34, 39.
- BCLK (pin 12) and WS (pin 35) are shared between the mic and the speaker — both devices tap the same two Pi pins.
- The LED is not connected yet; it needs a series resistor (220–330Ω) before wiring to avoid overcurrent damage to the GPIO pin or the LED itself.

## UART setup for the motion sensor

Raspberry Pi OS ships with the serial port used as a login console by default, which conflicts with the LD2410C. Disable the console (keep the UART hardware enabled):

```bash
sudo raspi-config nonint do_serial_cons 1   # disable login shell over serial
sudo raspi-config nonint do_serial_hw 0     # keep serial hardware enabled
sudo reboot
```

## I2S microphone capture device

The onboard `googlevoicehat-soundcard` overlay exposes the mic/speaker codec as ALSA card 0. Point capture explicitly at `plughw:0,0` rather than the ALSA "default" device, since "default" may be aliased to a playback-only dmix path (e.g. if `/etc/asound.conf` is set up for the speaker):

```bash
arecord -D plughw:0,0 -f S16_LE -c 1 -r 16000 -d 2 -t raw > /tmp/test.raw
```

## Privacy design

Raw audio is never stored. Only an RMS (loudness) value is computed to decide whether sound was detected, then discarded.
