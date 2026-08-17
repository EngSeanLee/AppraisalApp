# Tony's Jewelry Appraisal App

A native iOS SwiftUI app that lets Tony fill out a printed, stamped jewelry
appraisal mostly by voice. Full background/rationale is in
[`jewelry-appraisal-app-plan_1.md`](./jewelry-appraisal-app-plan_1.md), and
`appraisal-description-spec.md` is real reference material (12 of Tony's
past appraisals) that shaped the description wording, even though the app
no longer tries to auto-assemble it from structured fields — see below.
This README covers what's actually been built and what's still needed.

An earlier version of this app modeled the description as guided,
structured fields (metal, stone cut/carat/color/clarity, certification...)
assembled into text by a composable template engine. After Tony actually
used it, that turned out to be far more form than he needed — he'd rather
just type or say the whole description in his own words. That structured
layer is gone; see "What's built" below for the current, much simpler
shape.

This was scaffolded and coded on a Windows PC (no Mac/Xcode available), so
it's never been opened in Xcode locally. It builds and passes its tests on
the GitHub Actions macOS runner (see below) — that's the real compile/test
signal, checked on every push.

## What's built

- **Full SwiftUI project**, generated from `project.yml` via
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) rather than a hand-built
  `.xcodeproj` — this is what lets the project live as readable text files
  and be built on a cloud Mac without ever opening Xcode locally.
- **Core Flow** (template background → anchored fields → free-text
  description → photos → PDF export):
  - `TemplateBackgroundView` / `AppraisalTemplate` in `Assets.xcassets` —
    the real Tony's Jewelry & Custom Design letterhead (falls back to a
    labeled placeholder grid if the asset is ever missing).
  - `TapToSpeakField` — the tap-mic-then-talk control for short fields
    (customer name, address), with a keyboard toggle always visible next
    to it. Each field tracks its own listening session against
    `SpeechRecognitionService.activeListenerID`, so starting the mic on
    one field doesn't also dump the transcript into every other
    mic-enabled field on screen (a real bug the shared-state version had).
  - `SpeechRecognitionService` — on-device-only `SFSpeechRecognizer`
    wrapper (`requiresOnDeviceRecognition = true`).
  - `ReplacementValueSectionView` — one Replacement Value per appraisal
    (no combined-vs-itemized-per-piece mode anymore; Tony always prices
    the whole appraisal at once).
  - `DescriptionBuilderView` — the description as a single free-typed-or-
    dictated text box, not a guided multi-field form. Voice input here
    *appends* each dictation session to what's already there (space-
    separated) rather than replacing it, since a description gets built
    up over several sentences/passes.
  - `DescriptionChecklist` — the old guided structure, demoted to a quiet
    background check: scans the free text for common missing basics
    (metal/karat, a weight, stone grading when a stone is mentioned) and
    surfaces them as small non-blocking hints under the box. Never blocks
    export, never forces structured entry.
  - `PhotoCaptureView` / `CameraCaptureView` — three photo slots side by
    side, spanning the template's full width, roughly square. Every
    captured/picked photo goes through `PhotoCropView` (drag to pan,
    pinch to zoom, fixed 1:1 crop) before it's saved.
  - `PDFExportService` — composites everything into a single-page,
    US-Letter PDF via `UIGraphicsPDFRenderer`, including a static
    "PER ________" stamp line for Tony to sign/stamp by hand (the
    appraiser is always him — nothing here is app data, it's just a
    printed label + blank line) and the fixed `NoticeText` insurance
    disclaimer in small print at the bottom. Export filename is always
    `<Customer Name>-appraisal.pdf`, and every export is written straight
    into the app's Documents folder — which `UIFileSharingEnabled` /
    `LSSupportsOpeningDocumentsInBrowser` (see `project.yml`) expose in
    the Files app, so it's sitting in Files → On My iPhone →
    JewelryAppraisal right after export with no extra save step.
  - `AppraisalStore` / `SavedAppraisalsView` — every appraisal autosaves
    (as a small JSON record in Application Support, private — not the
    Documents folder the PDFs live in) as soon as any field changes.
    "Past Appraisals" (toolbar button on the main screen) lists them,
    most recently edited first, to reopen and edit or just look back at.
    "New Appraisal" clears the form for the next customer without losing
    the one just finished.
  - `DictationCleanupService` — the description box's dictation now runs
    the raw on-device transcript through Claude (Haiku 4.5, via a small
    Cloudflare Worker proxy — see `/worker`) before appending it, to fix
    run-on sentences and filler words rather than dropping raw speech-to-
    text straight into the appraisal. Falls back to the raw transcript if
    the network/Worker isn't reachable. **Needs the Worker deployed and
    its URL filled in — see "Still needs you" below.**
- **Unit tests** (`Tests/`) for Replacement Value formatting, export
  readiness, `Appraisal.isBlank`, `AppraisalStore`'s save/load/delete, and
  `DescriptionChecklist`'s hint logic.
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

2. **Deploy the dictation-cleanup Worker and fill in its URL.** See
   `/worker/README.md` for the full walkthrough — needs a (free) Cloudflare
   account and a separate Anthropic API key from console.anthropic.com
   (pay-as-you-go, but realistically cents for how much one appraiser
   dictates). Once deployed, paste the Worker's URL into the `endpoint`
   constant in `App/Services/DictationCleanupService.swift`. Without this,
   dictation still works exactly as before — cleanup just silently falls
   back to the raw transcript.

3. **Keep testing on the real device and reporting back.** Sideloaded via
   Sideloadly and already iterated once on real feedback (mic behavior,
   the fields above). This round moved the letterhead logo up in the
   artwork itself and shifted every field below it to match, added the
   notice disclaimer at the bottom, and added the photo crop step —
   `TemplateLayout.default`'s positions and `PhotoCropView`'s crop frame
   are still eyeballed/computed, not seen on a real screen or printer.
   Keep flagging anything that overlaps the border, looks cramped, or
   feels off in the crop gesture once someone can actually see it.

4. **Try `DescriptionChecklist`'s hints against how your dad actually
   writes descriptions.** It's a loose keyword/regex heuristic (metal
   mentioned, a weight mentioned, stone grading if a stone is mentioned),
   not tuned against real transcripts yet — see `App/Services/
   DescriptionChecklist.swift`. Tell me what it misses or nags about
   unnecessarily once you've used it for real.

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
