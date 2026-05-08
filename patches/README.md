# WLED Source Patches

This directory contains small patches that are applied to the checked-out
upstream WLED source before building. `scripts/apply_wled_patches.sh` applies
each `*.patch` file idempotently: it applies patches that still fit, accepts
patches that are already present, and fails if a patch no longer applies
cleanly.

These patches are intentionally narrow. They preserve mainline WLED behavior by
default and only change behavior for builds that opt into the new flags or use
the affected HUB75 path.

## `allow-256-matrix-dimension.patch`

### Need

The Lilygo T7 S3 MoonHub75 target is intended to drive a 256x64 matrix made from
multiple HUB75 panels. WLED v16 rejects matrix dimensions above 255 in
`WS2812FX::setUpMatrix()`, which causes a valid 256-pixel-wide matrix to fall
back to 1D mode. Once that happens, 2D-only effects and matrix behavior are not
available even though the hardware and `MAX_LEDS` budget are otherwise valid.

The same hard-coded 255 clamp is also used when loading dimensions from a
ledmap, so ledmap-provided matrix metadata would be narrowed in the same way.
The 2D setup page also capped each logical panel width and height input at 255,
so a firmware that accepted 256 still could not be configured through the UI.

### Approach

The patch introduces `WLED_MAX_MATRIX_DIMENSION` in `wled00/const.h`, defaulting
to the upstream-compatible value of `255`. It then replaces the hard-coded `255`
checks in:

- `wled00/FX_2Dfcn.cpp`
- `wled00/FX_fcn.cpp`
- `wled00/data/settings_2D.htm`
- `wled00/xml.cpp`

The Lilygo build opts into `-D WLED_MAX_MATRIX_DIMENSION=256` in
`platformio_override.ini`. `xml.cpp` exports that build-time value into the 2D
settings JavaScript, and the page uses it for the generator and per-panel
dimension limits. Other targets continue to use WLED's default limit.

### Removal Criteria

This patch can be removed if upstream WLED supports 256-wide matrix dimensions
directly, or if the Lilygo build no longer needs a 256-pixel-wide logical
matrix.

## `hub75-preserve-ui-panel-config.patch`

### Need

In WLED v16, the HUB75 Quarter Scan bus transforms the user-entered panel
geometry into internal DMA geometry. For example, a 64x64 Quarter Scan panel is
represented internally as a wider, shorter virtual panel. The LED Config UI
later repopulates its inputs through `BusHub75Matrix::getPins()`, but that
method returned the transformed internal values from `mxconfig`.

The result was a confusing save/reload loop: entering 64x64 for HUB75 Quarter
Scan would save, but reopening LED Config showed transformed dimensions such as
128x16/128x32 instead of the original user-facing panel size. Choosing Half Scan
appeared to work only because its internal geometry does not visibly transform
the same 64x64 input.

### Approach

The patch keeps the rendering behavior unchanged and separates configuration
serialization from driver internals:

- `BusHub75Matrix` stores the original panel width, panel height, and sanitized
  chain length when constructed from `BusConfig`.
- The HUB75 driver still receives the transformed `mxconfig` values it needs for
  Quarter Scan rendering.
- `BusHub75Matrix::getPins()` returns the preserved user-facing values, so LED
  Config and JSON serialization show the same dimensions the user entered.

This makes Quarter Scan usable without pretending the panels are Half Scan,
which avoids duplicated or distorted output on real Quarter Scan panels.

### Removal Criteria

This patch can be removed if upstream WLED changes HUB75 config serialization to
return user-facing panel dimensions instead of internal DMA dimensions.

## `hub75-quarter-scan-logical-dimensions.patch`

### Need

HUB75 Quarter Scan panels need the DMA driver to be configured as if each panel
is twice as wide and half as tall. That scan conversion is an electrical detail,
not the visible 2D matrix shape.

WLED v16 was passing those scan-converted dimensions into `VirtualMatrixPanel`.
That leaked the DMA geometry into WLED's logical pixel space: a physical 64x64
Quarter Scan panel behaved like a 128x32 panel, and a 4-panel 256x64 wall could
behave like 512x32. The segment editor then appeared to need bounds larger than
the visible matrix, and the 2D setup/UI could not reasonably express the shape
the renderer expected.

### Approach

The patch keeps the DMA configuration unchanged, because Quarter Scan hardware
still requires the doubled-width/half-height buffer. It changes only the
`VirtualMatrixPanel` construction:

- Half Scan continues to pass the normal panel dimensions.
- Quarter Scan passes the user-facing physical panel width and height.
- The virtual panel layer then translates visible/logical coordinates into the
  scan-converted DMA coordinates.

With this patch, WLED segments and 2D setup should use actual visible/logical
matrix bounds. For example, four 64x64 Quarter Scan panels in a row should be
configured and segmented as 256x64, not 512x32.

### Removal Criteria

This patch can be removed if upstream WLED constructs HUB75 Quarter Scan virtual
panels with physical dimensions, or moves Quarter Scan remapping fully below the
WLED 2D matrix layer.
