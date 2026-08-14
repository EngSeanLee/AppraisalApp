# Jewelry Appraisal App — Planning Brief

## Objective
A native iOS app for EngSean's father (Tony's Jewelry) to produce printed, stamped jewelry appraisals with minimal typing. He is not tech-savvy, so the interaction model prioritizes voice input and minimal taps over flexibility.

## Core Flow
1. App opens to a fixed background template image (the appraisal border/letterhead).
2. Four anchored text regions overlay the template: **Customer Name**, **Date**, **Address**, **Item Description**.
3. User taps a field, then speaks — on-device speech-to-text fills that field. Text auto-sizes/wraps to fit its bounded region on the template.
4. User taps a "Photo" step, takes a picture of the piece, and it's automatically placed and sized into a designated photo region on the template.
5. User taps "Export" → app composites everything into a single-page PDF, ready to print and stamp.

## Key Design Decisions
- **Voice input model:** tap-field-then-talk (not continuous/parsed dictation). Chosen for reliability — a non-technical user is much less likely to get frustrated by a misrouted field than by one continuous "just talk" mode that has to guess which words go where.
- **Typing is always available, on every field** — not just an error-correction fallback. Names are a known failure point for dictation (e.g. "Shawn" vs "Sean" vs "Sean" — homophones), so a visible keyboard toggle must sit next to the mic button at all times, letting him type from scratch or fix a word without extra navigation.
- **Description input is hybrid:** guided prompts for each required element (see below) that assemble into the standard sentence, shown as a single editable text box he can tap into and freely rewrite/override at any point. This gives structure/completeness without forcing rigid sub-fields — the assembled sentence *is* the override surface, so there's only one thing to look at, not a form full of little boxes.
- **Export format:** PDF only. No Word/DOCX — it's not needed since the output is printed and stamped, and DOCX generation on iOS has no good native support (would add real complexity for zero benefit).
- **Distribution:** Personal/internal install for his father only — not a public App Store release. No App Store review needed.

## Description — Minimum Required Elements
Based on the example ("14 karat white gold, 8.00 gram Euro shank ring with halo, set with a 3.05 carat marquise cut diamond in the center. The marquise diamond is certified by IGI #764659900, E, VS1. The halo consists of diamonds with a total weight of 0.53 carat."), every complete appraisal description needs:
1. **Metal type, karat/purity & total weight** — e.g. "14 karat white gold, 8.00 gram"
2. **Item type & setting style** — e.g. "Euro shank ring with halo"
3. **Center stone details** (shape, carat weight, cut) — e.g. "3.05 carat marquise cut diamond"
4. **Certification # and grading** (color/clarity) — e.g. "certified by IGI #764659900, E, VS1"
5. **Side/accent stone total weight** — e.g. "halo consists of diamonds with a total weight of 0.53 carat"

Since not every piece has all of these (e.g., a plain band has no center stone), the app should prompt for each element but allow "N/A" or skip — while making it visually obvious in the guided checklist which elements are filled vs. skipped, so nothing gets missed by accident on a piece that *does* need it.

## Fuzzy Dictation Parsing & Standardization
The app should not just transcribe raw speech into the description — it should extract the required elements from natural, rambling speech and discard filler, then render them into a **fixed sentence template per item type** (ring, necklace, bracelet, earrings, etc.), so every appraisal of the same item type reads with identical structure/order regardless of how your dad phrased it out loud.

- **Parsing engine: on-device only.** No cloud AI/LLM API call — everything happens locally on the phone. This keeps it fully offline-capable, avoids per-call API costs, and keeps customer/item data on-device. Tradeoff worth flagging: on-device parsing of loosely-structured speech is a harder engineering problem than calling a cloud LLM — likely built from a combination of Apple's `NaturalLanguage` framework (entity/keyword tagging) and a rules/pattern layer tuned to jewelry vocabulary (metals, karats, stone shapes, cut types, grading scales, cert-issuer names like GIA/IGI). This will need iteration against real examples to get reliable — see reference samples below.
- **Fixed template per item type:** each item type (ring, necklace, bracelet, etc.) has its own sentence skeleton with slots in a set order, e.g. for rings: `[karat] [metal], [weight] [item type] with [setting style], set with a [carat] [cut] [stone] in the center. The [stone] is certified by [issuer] #[cert #], [color], [clarity]. The [setting] consists of [stone type] with a total weight of [weight].` Other item types (necklace, bracelet, earrings, loose stone, etc.) will need their own templates defined the same way — a good next step once real past appraisals are available for reference.
- **Vague quantities auto-normalize, with a qualifier when appropriate:** "about half a carat" → "approximately 0.50 carat"; "a couple grams" → "approximately 2.00 gram(s)". Precise dictated figures ("three point oh five carat") normalize cleanly without the "approximately" qualifier. This distinction (was the input exact or hedged?) needs to be preserved through parsing, not just the final number.
- **Reference samples:** EngSean can pull a handful of his dad's past appraisal writeups to use as the ground-truth style/phrasing reference — these should directly inform both the per-item-type sentence templates and the on-device parser's expected vocabulary/patterns, so standardized output actually matches how appraisals already read rather than a generic format invented from scratch.

## Recommended Tech Stack
- **Language/framework:** Native SwiftUI (real iOS project, not a wrapper/no-code tool)
- **Speech-to-text:** Apple's `SFSpeechRecognizer` (Speech framework) — supports on-device recognition, works offline, good privacy fit for customer PII
- **Photo capture/placement:** `PhotosPicker` / `AVFoundation` + Core Graphics compositing onto the template image
- **Text layout:** SwiftUI `Text` in bounded frames with dynamic type scaling (`minimumScaleFactor`) anchored to fixed coordinates on the template
- **PDF export:** `PDFKit` / `UIGraphicsPDFRenderer` rendering the composited view straight to a PDF context

## Solving the "No Mac" Problem
Apple requires Xcode (macOS-only) to compile any iOS app — but you don't need to own or rent a Mac yourself:
- Write/maintain the Swift project (e.g., via Claude Code on your PC, pushed to a git repo).
- Use a cloud build service — **Codemagic** or **GitHub Actions macOS runners** — to compile the app on a cloud-hosted Mac. You never touch Xcode directly.
- Enroll in the **Apple Developer Program** ($99/year, done via web browser, no Mac required).
- Distribute via **TestFlight**: your dad installs the TestFlight app once from the App Store, taps an install link you send him, and future updates just arrive as normal app updates. This avoids the free-tier sideloading pain of re-signing via Xcode every 7 days.

## Costs
- Apple Developer Program: $99/year
- Cloud build service: free tier (e.g., Codemagic's free monthly build minutes) should comfortably cover occasional builds for an app this size

## Open Items / Next Steps
- [ ] Finalize the template image (exact border/letterhead design, field positions, fonts, logo/stamp area)
- [ ] Confirm which description elements can legitimately be skipped per piece type (e.g. plain band = no center stone) vs. always required
- [ ] Decide guided-prompt wording/order for the description checklist (metal → weight → item/setting → center stone → cert/grading → side stones)
- [ ] Gather a handful of past appraisal writeups from your dad to use as phrasing/format reference
- [ ] Define the fixed sentence template for each item type (ring done above as example; still need necklace, bracelet, earrings, loose stone, etc.)
- [ ] Build/tune the on-device parsing layer (NaturalLanguage framework + jewelry-vocabulary rules) against those reference examples
- [ ] Create Apple Developer Program account (~30–45 min, browser-based)
- [ ] Set up git repo + Codemagic (or GitHub Actions) pipeline for cloud builds
- [ ] Build the SwiftUI project (likely to be done via Claude Code on EngSean's PC)
- [ ] Set up TestFlight distribution to father's device
- [ ] Test full flow end-to-end: voice fill → photo capture → PDF export → print
