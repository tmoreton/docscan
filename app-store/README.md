# PaperIndex App Store submission assets

This folder contains the English (U.S.) product-page copy and simulator screenshots for PaperIndex 1.1.

## Screenshot sets

Upload the numbered files in order. Every image is a JPEG without transparency and shows the real PaperIndex app running with fictional demo documents.

| Folder | Resolution | App Store Connect use |
| --- | --- | --- |
| `assets/screenshots/iphone-6.9/` | 1320 × 2868 portrait | Current 6.9-inch iPhone display slot |
| `assets/screenshots/iphone-6.5/` | 1284 × 2778 portrait | 6.5-inch iPhone display slot; also matches the requested accepted size |
| `assets/screenshots/ipad-13/` | 2064 × 2752 portrait | Required 13-inch iPad display slot because PaperIndex supports iPad |

The six screenshots cover:

1. Private, on-device first-run state
2. Searchable document archive
3. Search across recognized page text
4. Explicit save confirmation
5. Document detail and Files copy
6. On-device recognition and save progress

Apple accepts one to ten screenshots per device size. App previews are optional.

## Other assets

- `assets/app-icon-1024.png` — flattened 1024 × 1024 RGB icon with no alpha channel
- `METADATA.md` — product-page copy, URLs, review notes, and privacy answers

## Reproducing the screenshots

Debug builds accept fictional preview data arguments that are excluded from Release builds. Build the app for the simulator, then run:

```sh
scripts/capture_app_store_screenshots.sh \
  <simulator-udid> \
  <path-to-PaperIndex.app> \
  .build/app-store-source/<device-name>
```

The source captures are intentionally written to the ignored `.build/` directory. Convert final captures to JPEG before upload so they contain no alpha channel.
