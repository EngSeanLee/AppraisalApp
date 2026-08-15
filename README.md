# Tony's Jewelry Appraisal App

A native iOS SwiftUI app that lets Tony fill out a printed, stamped jewelry
appraisal mostly by voice. Full background/rationale is in
[`jewelry-appraisal-app-plan_1.md`](./jewelry-appraisal-app-plan_1.md), and
the description-generation logic (metal/stone/certification clauses) is
driven by [`appraisal-description-spec.md`](./appraisal-description-spec.md)
— a reference derived from 12 of Tony's real past appraisals. This README
covers what's actually been built and what's still needed to get it onto
his phone.

This was scaffolded and coded on a Windows PC (no Mac/Xcode available), so
it's never been opened in Xcode locally. It builds and passes its tests on
the GitHub Actions macOS runner (see below) — that's the real compile/test
signal, checked on every push.

## What's built

- **Full SwiftUI project**, generated from `project.yml` via
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) rather than a hand-built
  `.xcodeproj` — this is what lets the project live as readable text files
  and be built on a cloud Mac without ever opening Xcode locally.
- **Core Flow** (template background → anchored fields → guided
  description → photo → PDF export), matching the plan:
  - `TemplateBackgroundView` / `AppraisalTemplate` in `Assets.xcassets` —
    the real Tony's Jewelry & Custom Design letterhead (falls back to a
    labeled placeholder grid if the asset is ever missing).
  - `TapToSpeakField` — the tap-mic-then-talk control, with a keyboard
    toggle always visible next to it.
  - `SpeechRecognitionService` — on-device-only `SFSpeechRecognizer`
    wrapper (`requiresOnDeviceRecognition = true`).
  - `AppraiserFieldView` — the "PER" line (name + optional credential),
    seeded from a small roster but freely editable, not hardcoded to one
    person.
  - `ValuationSectionView` — combined-total vs. itemized-per-piece
    Replacement Value, both real patterns per the spec.
  - `DescriptionBuilderView` — one or more `PieceEditorView`s (multi-item
    appraisals get one per piece: qualifier/custom-made, metal, item
    style, a repeatable stones list, chain/length for stone-less pieces)
    assembling into one editable text box via `DescriptionTemplateEngine`.
    Each stone carries its own grading, an explicit natural/lab-grown/
    unspecified toggle (never inferred from a cert-number prefix), and an
    optional certification — real appraisals show up to 3 independently
    certified stones on one piece.
  - `DescriptionTemplateEngine` — a composable clause system (metal/weight,
    setting style, center stone, accent-stone groups, chain/length for
    stone-less pieces), not a fixed template per item type. Which clauses
    appear is driven by what data is actually present, so it naturally
    covers rings, necklaces, bracelets, earrings, and loose stones without
    a separate hand-written template for each — per the spec's own "Core
    Insight" that there's no single fixed sentence shape even within one
    item type.
  - `QuantityNormalizer` — parses "three point oh five carat" → exact 3.05,
    "about half a carat" → approximate 0.50, etc. Still only tuned against
    the plan's own examples, not yet against real transcripts — see below.
  - `PhotoCaptureView` / `CameraCaptureView` — camera capture placed into
    the template's photo region.
  - `PDFExportService` — composites everything (including the appraiser
    line and Replacement Value line(s)) into a single-page, US-Letter PDF
    via `UIGraphicsPDFRenderer`.
- **Unit tests** (`Tests/`) for the normalizer, the template engine (full
  clause set, chain-only pieces, loose stones, multi-piece concatenation,
  and a check that the lab-grown flag never silently alters generated
  text), and Replacement Value formatting/itemization.
- **CI** (`.github/workflows/ios-build.yml`) — builds and runs tests on a
  macOS GitHub Actions runner on every push, no signing required (Simulator
  build only).
- **Sideload builds** (`.github/workflows/ios-sideload-ipa.yml`) — manually
  triggered (`Run workflow` on the Actions tab, or `gh workflow run
  ios-sideload-ipa.yml`), produces an unsigned `.ipa` for a real device as
  a downloadable workflow artifact, for testing on your own phone with
  AltStore/Sideloadly + your free Apple ID, before paying for the Developer
  Program. See "Testing on your phone for free" below. Kept off the normal
  push trigger on purpose — macOS runner minutes count 10x against
  GitHub's free-tier allowance, and this isn't needed on every commit.

## Testing on your phone for free

Before paying for the Apple Developer Program, you can install this app on
your own iPhone for free using [AltStore](https://altstore.io) (or
[Sideloadly](https://sideloadly.io), similar tool) — no Mac needed, since
the actual compiling still happens on the GitHub Actions macOS runner.

1. Install **AltServer for Windows** on this PC, and **AltStore** on your
   iPhone through it (AltServer's tray icon → your device → "Install
   AltStore"). First-time pairing needs a USB cable; after that it can work
   over WiFi as long as your phone and this PC are on the same network.
2. Trigger the `ios-sideload-ipa.yml` workflow (Actions tab → "Build
   Sideload IPA" → "Run workflow"), then download the `.ipa` from the
   finished run's Artifacts section.
3. Right-click AltServer's tray icon → your device → **Install .ipa**, and
   pick the downloaded file. It'll ask for your Apple ID — a regular free
   one, not a paid Developer account.
4. On the phone: **Settings → General → VPN & Device Management** → tap
   your Apple ID → **Trust**, then open the app.

Free-tier signing like this expires after **7 days** — AltStore can
refresh it automatically in the background if AltServer stays running on
this PC and your phone checks in over WiFi periodically, or you can just
re-run steps 2–3 whenever it lapses. I haven't been able to test this
sideload path myself (no device, no AltStore access from here), so treat
the exact AltServer UI wording as approximate — shout if anything doesn't
match what you see.

## Still needs you

Nothing below can be done from here — they need your accounts, your
hardware, or your dad's paperwork.

1. **Apple Developer Program** — $99/year, apple.com/programs, browser-only,
   no Mac needed. Required before TestFlight or the App Store (not before
   on-device testing — see "Testing on your phone for free" above).

2. **Look at the real template on an actual device or printer.** The
   letterhead artwork is in and the field positions in
   `App/Models/TemplateLayout.swift` (`TemplateLayout.default`) are tuned
   against it, but it turned out to be a blank bordered page with a logo
   block and no pre-printed field lines — so those positions are an
   eyeballed layout choice, not a measurement against anything. Worth a
   look once you can see it rendered for real; nudge the fractional
   numbers if anything overlaps the border or looks off.

3. **Tune `QuantityNormalizer` against how your dad actually talks.** The
   phrase tables are still only seeded from the plan's own written
   examples, not real dictation. The description-clause side of things now
   has real reference material (`appraisal-description-spec.md`); the
   voice-normalization side still doesn't.

4. **Decide the remaining UI/data-model open items the spec itself
   flags** — see appraisal-description-spec.md's "Open Items for the
   Build." Most are handled (per-stone certification, the explicit lab-
   grown/natural/unspecified toggle, combined vs. itemized valuation), but
   worth a second look once Tony is actually using it day to day.

5. **TestFlight setup** once you have the Developer account — internal
   testing group, his Apple ID invited, `DEVELOPMENT_TEAM` filled in in
   `project.yml`. Codemagic or GitHub Actions can push to TestFlight once
   signing secrets exist; the current workflow only builds for the
   Simulator.

## Building it yourself (once you have a Mac, or via CI)

```
brew install xcodegen
xcodegen generate
open JewelryAppraisal.xcodeproj
```

The generated `.xcodeproj` is gitignored on purpose — `project.yml` is the
source of truth, so there's nothing to keep in sync by hand.
