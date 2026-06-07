# Store listing graphics

Drop the Play Store images here using the **exact filenames** below. The
`tool/play_publish` uploader (when extended) reads them by name, and the order
of the numbered screenshots is the order they appear in the store.

| File (in this folder)        | Play slot              | Required | Exact size / rules                                  |
|------------------------------|------------------------|----------|-----------------------------------------------------|
| `icon.png`                   | App icon               | Yes      | **512 × 512** px, 32-bit **PNG** (icon must be PNG), < 1 MB, no transparency |
| `feature-graphic.jpg`        | Feature graphic        | Yes      | **1024 × 500** px, JPEG or 24-bit PNG, no alpha     |
| `phone/01.jpg` … `08.jpg`    | Phone screenshots      | Yes (2–8)| JPEG or PNG, 16:9–9:16 ratio, each side 320–3840 px; **portrait** for this game |
| `seven-inch/01.jpg` …        | 7-inch tablet shots    | Optional | up to 8, same rules                                 |
| `ten-inch/01.jpg` …          | 10-inch tablet shots   | Optional | up to 8, same rules                                 |

## Naming rules
- Use **zero-padded numbers** (`01`, `02`, …) so the upload order is stable.
- Icon = PNG (required by Play). Feature graphic + screenshots = JPEG or PNG.
- Keep originals at the listed pixel sizes — Play rejects off-spec dimensions.

## Folder layout
```
docs/store-assets/
├── icon.png
├── feature-graphic.jpg
├── phone/
│   ├── 01.jpg
│   ├── 02.jpg
│   └── ...
├── seven-inch/      (optional)
└── ten-inch/        (optional)
```

These are uploaded to Play via the androidpublisher `edits.images` endpoint
(imageType: `icon`, `featureGraphic`, `phoneScreenshots`, `sevenInchScreenshots`,
`tenInchScreenshots`).
