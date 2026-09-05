# PaperIndex UI/UX audit

Audited and rebuilt September 4, 2026.

## Product flow

The core flow is intentionally short:

1. Open the searchable document archive.
2. Start a scan from one primary blue action.
3. Capture pages in Apple's document camera.
4. Wait while PaperIndex recognizes text and creates Files copies.
5. See an explicit saved confirmation.
6. Open a document to review its pages, recognized text, and Files status.

The capture experience is provided by VisionKit. The PaperIndex-specific experience begins in the archive and resumes when the system scanner closes.

## Findings before the rebuild

### High priority

- The centered `Docs` capsule looked like a selected tab, not the product or screen title.
- The empty archive exposed both a large scan button and another camera button before either had a distinct role.
- Search was visible with zero documents, creating a prominent control that could not produce a useful result.
- Saving ended without a durable success state. The only feedback was a modal progress indicator, and the Files destination was hidden behind an unlabeled folder icon on the detail screen.
- Multiple category colors plus a blue-to-teal primary gradient worked against the desired restrained palette.

### Medium priority

- White controls on a near-white background relied heavily on shadows, so sections blended together.
- Category color bars implied a taxonomy the interface never explained.
- Detail content prioritized page imagery before answering the more important user question: “Where was this saved?”
- Delete and Files actions received equal toolbar weight despite very different frequency and risk.
- Pipe-separated metadata was visually dense at small sizes.

## Competitor audit

The review used the current official product and App Store presentations for [Adobe Scan](https://apps.apple.com/us/app/adobe-scan-pdf-ocr-scanner/id1199564834), [Scanner Pro](https://apps.apple.com/us/app/scanner-pro-scan-documents/id333710667), [Scanner Pro’s product page](https://readdle.com/scannerpro), and [Genius Scan](https://apps.apple.com/us/app/scanner-app-genius-scan/id377672876).

| Product | Dominant palette | Useful pattern | Pattern to avoid |
| --- | --- | --- | --- |
| Adobe Scan | Black/charcoal work surface, white content, bright blue commit action | The final `Save PDF` action is labeled and visually isolated | Dense editing toolbars make the finishing step feel busy |
| Scanner Pro | Black capture surface, white controls, saturated blue brand field, occasional indigo | Strong contrast around capture and clear separation between document and chrome | Secondary brand colors proliferate once editing tools appear |
| Genius Scan | Dark charcoal capture surface, white control sheets, orange selected state | Accent color means “active” while most of the interface remains neutral | Orange-tinted marketing and selection states can overpower document content |

The common lesson is not to add more color. Each product creates differentiation with dark capture surfaces, white document surfaces, pale neutral backgrounds, borders, and one saturated action color. Accent color is most effective when it means “start,” “selected,” or “save.”

## Rebuilt design system

- Background: cool gray `#F4F5F7`
- Surface: white `#FFFFFF`
- Primary ink: near-black `#111317`
- Secondary ink: slate gray `#5D6573`
- Primary action/status: blue `#0954CC`
- Selected surface: pale blue `#E9F1FE`
- Category treatment: neutral gray; categories no longer introduce new hues
- Shape language: 14–24 pt continuous corners for clear surface grouping
- Elevation: low-opacity shadows paired with borders, never shadows alone

## Rebuilt experience

- Added a real `Documents` header with archive count and one labeled `Scan` action.
- Removed search from the zero-document state.
- Reworked the empty state into one focused explanation and CTA.
- Replaced the gradient and category rainbow with a monochrome-plus-blue palette.
- Added page-count-aware saving feedback that explains text recognition and Files creation.
- Added an explicit `Saved and searchable` completion card with the Files destination.
- Added a compact checkmark to completed archive rows without repeating the saved status in text.
- Put a single, prominent `View in Files` action near the top of document detail.
- Moved copy, Files, and delete utilities into a conventional overflow menu; delete no longer competes visually with the primary action.

## Follow-up opportunities

- Generate a combined searchable PDF in addition to the existing page JPGs and OCR text. This is the largest output-format gap versus the reviewed competitors.
- Add a first-class share sheet after PDF generation.
- Add rename and category editing so automatically generated metadata can be corrected.
- Test the archive with very long localized titles and Accessibility text sizes on physical devices.
