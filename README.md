# wled-builds

Unofficial [WLED](https://kno.wled.ge/) builds for [QuinLED](https://quinled.info/) hardware as well as a few other ESP32 boards. I'm affiliated with neither.

## Targets

### QuinLED boards

- [Dig2go](https://quinled.info/quinled-dig2go/)
- [DigUno](https://quinled.info/pre-assembled-quinled-dig-uno/) including wired ethernet and temperature sensor variants

### Other boards

- [Adafruit Matrix Portal S3](https://www.adafruit.com/product/5778) with HUB75 support
- [Lilygo T7 S3](https://lilygo.cc/en-us/products/t7-s3) for MOONHUB75
- [Ai Thinker ESP32-A1S Audio Kit](https://www.amazon.com/EC-Buying-ESP32-Audio-Kit-Development-ESP32-A1S/dp/B0B63KZ6C1) as a dedicated audio sender

## Environment Variables

- `IOT_SSID`: If set, will be supplied to build as `CLIENT_SSID`
- `WPA_KEY`: If set, will be supplied to build as `CLIENT_PASS`

## Building

1. Checkout WLED source:

    ```bash
    make checkout GIT_REF="v16.0.0"
    ```

1. Prepare dependencies and toolchains:

    ```bash
    make build-prep
    ```

1. Build all default targets:

    ```bash
    make build GIT_REF="v16.0.0"
    ```

1. Or build one or more space-separated targets:

    ```bash
    make build GIT_REF="v16.0.0" PIO_ENVS="quinled_dig2go quinled_diguno_eth_temp"
    ```

Factory and OTA bins are emitted to `build/`.

## Flashing

Factory images should be flashed at `0x0`:

```bash
esptool.py write_flash 0x0 WLED_16.0.0_QuinLED_Dig2go.bin
```
