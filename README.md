# Tony's Jewelry Appraisal App

A native iOS SwiftUI app that lets Tony fill out a printed, stamped jewelry
appraisal mostly by voice. Full background/rationale is in
[`jewelry-appraisal-app-plan_1.md`](./jewelry-appraisal-app-plan_1.md) — this
README covers what's actually been built and what's still needed to get it
onto his phone.

This was scaffolded and coded on a Windows PC (no Mac/Xcode available), so
nothing here has been compiled yet. It's written to build cleanly on the
GitHub Actions macOS runner (see below) — that CI run is the first real
compile check.

## What's built

- **Full SwiftUI project**, generated from `project.yml` via
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) rather than a hand-built
  `.xcodeproj` — this is what lets the project live as readable text files
  and be built on a cloud Mac without ever opening Xcode locally.
- **Core Flow** (template background → 4 anchored fields → guided
  description → photo → PDF export), matching the plan:
  - `TemplateBackgroundView` — draws the letterhead, or a labeled
    placeholder grid if the real artwork isn't in `Assets.xcassets` yet, so
    the app is runnable before that asset exists.
  - `TapToSpeakField` — the tap-mic-then-talk control, with a keyboard
    toggle always visible next to it.
  - `SpeechRecognitionService` — on-device-only `SFSpeechRecognizer`
    wrapper (`requiresOnDeviceRecognition = true`).
  - `DescriptionBuilderView` + 5 step views (metal, item/setting style,
    center stone, certification, side stones) — the guided checklist from
    the plan, each skippable as N/A, assembling into one editable text box
    via `DescriptionTemplateEngine`.
  - `QuantityNormalizer` — parses "three point oh five carat" → exact 3.05,
    "about half a carat" → approximate 0.50, etc.
  - `PhotoCaptureView` / `CameraCaptureView` — camera capture placed into
    the template's photo region.
  - `PDFExportService` — composites everything into a single-page,
    US-Letter PDF via `UIGraphicsPDFRenderer`.
- **Unit tests** (`Tests/`) for the normalizer and template engine,
  including a regression test asserting the ring template reproduces the
  plan's own worked example sentence exactly, word for word.
- **CI** (`.github/workflows/ios-build.yml`) — builds and runs tests on a
  macOS GitHub Actions runner on every push, no signing required (Simulator
  build only).
- Necklace/bracelet/earrings/loose-stone all select a template today, but
  they currently reuse the ring-shaped clause logic in
  `DescriptionTemplateEngine` — flagged there as a stub. The plan calls for
  giving each its own template once real reference appraisals exist (see
  below).

## Still needs you

Nothing below can be done from here — they need your accounts, your
hardware, or your dad's paperwork.

1. **Push this to a GitHub repo.** It's a local git repo with one commit so
   far, no remote configured:
   ```
   git remote add origin <your-new-repo-url>
   git push -u origin main
   ```
   (`gh` isn't installed/authenticated on this machine, so I couldn't
   create the GitHub repo itself — `gh repo create` or the GitHub website
   both work.) Once it's pushed, the Actions workflow runs automatically
   and you'll get a real "does it compile" answer.

2. **Apple Developer Program** — $99/year, apple.com/programs, browser-only,
   no Mac needed. Required before real-device install or TestFlight.

3. **The real template image** — the actual appraisal border/letterhead,
   at the field positions Tony's paper form uses. Drop it into
   `App/Resources/Assets.xcassets` as an image set named
   `AppraisalTemplate`, then adjust the fractional field-position numbers
   in `App/Models/TemplateLayout.swift` (`TemplateLayout.default`) to match
   — everything else reads positions from that one file.

4. **A handful of your dad's past appraisal writeups.** These directly
   drive two things still marked as stubs: the sentence templates for
   necklace/bracelet/earrings/loose-stone in
   `DescriptionTemplateEngine.swift`, and tuning `QuantityNormalizer`'s
   vague-phrase handling against how he actually talks. Right now both are
   built from the plan's single ring example only.

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
