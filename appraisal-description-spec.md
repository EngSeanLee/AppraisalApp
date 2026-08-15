# Tony's Jewelry — Appraisal Description Spec

Reference spec for the description-generation logic in the appraisal app. Derived from 12 real past appraisals. This is the ground truth for how a "standardized" description should be assembled — read this before implementing the parsing/templating layer.

> Note: customer names below are anonymized (Sample A, B, C…) since this file may live in a git repo. Real values (metals, stones, certs, prices) are preserved exactly as written on the originals.

## Core Insight

There is **no single fixed sentence template**, even within one item type. A plain band, a 3-stone "past/present/future" ring, and a stone-less Cuban link bracelet share almost no structure. The right model is a **composable clause system**: small building blocks that get assembled based on what's actually present on a given piece, always in the same standardized voice/order. Below are the clauses observed, each with real examples.

## Header / Static Fields (outside the description box)

- **Name** — customer name (always present)
- **Address** — often left blank; present on some (e.g. full street/city/state/zip)
- **Date**
- **Appraiser** — "PER" signature line. NOT a fixed value — observed: "Tony Lee" (no title), "Christopher D. Walker" with title line "GIA Certified Grader" below, "Christopher D Walker GIA" (title inline), and "Christopher D Walker GIA Graduated" (different title wording same person). Must be a selectable/editable field, not hardcoded to one person, and should support an optional credential/title line.
- **Replacement Value** — always present, formatted `Replacement Value…….$X,XXX.00` (dot-leader style, always two decimal places, comma thousands separator). See "Multi-item valuation" below — this can repeat per piece.

## Description Clause Library

### 1. Metal & Weight clause (always present, opens the description)
Pattern: `[gender/qualifier] [total weight] grams [karat] [metal color] gold [item type]` — order of weight vs. karat varies (weight-first and karat-first both observed), item may be "custom made" / "custom-made" (both spellings seen) or omit that word entirely.

Real examples:
- "Ladies' custom made 14kt white gold ring"
- "A 6.30 grams 14kt yellow gold custom made diamonds pendant"
- "An 11.75 grams Ladies custom make 14kt two tone wedding ring"
- "Miami Cuban links bracelet weighs 32.0 grams 14karat yellow gold 7.5 in length"
- "7.10 grams 14kt white gold custom made past present and future diamonds ring"
- "A custom-made 14kt yellow gold weighs 3.10grams engagement ring"

Metal types observed: 14kt white gold, 14kt yellow gold, 14kt two-tone gold, platinum (setting). Karat is not always 14kt-only — field must be free/selectable, not hardcoded.

### 2. Setting/Style descriptor (optional)
A named style inserted into or after the metal clause. Observed values: "Euro shank" + "halo", "hidden halo", "past present and future" (3-stone style), "Miami Cuban links" (chain pattern), plain (no style named).

### 3. Primary/center stone clause (0, 1, or occasionally 2 co-equal stones)
Pattern: `set with a [carat/mm] [cut] [shape] [stone type] in the center` + grading `[clarity], [color] in color` + optional cert `certified by [issuer] #[cert number]` or `[issuer] certified [shape] diamond #[cert number]`.

Real examples:
- "set with 1.32 carat marquise cut diamond SI1, I color in the center"
- "set with a GIA certified oval shape diamond #2476544628 SI2, E color 2.00carat in a platinum setting"
- "with IGI certified LG651440496 round 3.23ct E, VS1 in the center" (note "LG" prefix — see Lab-Grown flag below)
- "with 2X4mm round Blue Zircon on the top" (non-diamond stone, sized by mm not carat)
- "5.7x4.3mm emerald cut VS1, G color weight 0.63ct in the center" (both mm AND carat given together)
- "This marquise diamond is certified by GIA #6542519109 2.50 carat G, SI1" (cert clause placed as its own sentence, not inline)

Cert number can appear **inline within the stone clause** or as a **separate sentence** ("This [stone] is certified by [issuer] #[number]."). Either is acceptable — pick one consistent form for the generated output.

### 4. Secondary/accent stones clause (0 or more)
Pattern: `The [setting name] also consists of [count] [shape] diamonds` + grading, either as a single clarity/color pair or a **range** (e.g. "SI2-SI1") + total weight `with the weight of [X]ctw` or `weight of [X] carat`.

Real examples:
- "The halo also consists of 10 round diamonds of SI1-SI2, H-I in color with the weight of 0.38ctw"
- "The ring also consists of 59 round brilliant cut diamonds. These diamonds are VS2-SI1, G in color with the weight of 1.39ct"
- "The 2 on the side are both IGI certified, LG648473332 and LG644458, they are both 1.04ct VVS1, E in color" (each accent stone individually cert-numbered — not just a group total)
- "with 6 round diamonds are SI3, H in color with the weight of about 0.50ctw" ("about" = hedged/approximate quantity, matches our approximate-quantity rule)

Important: accent stones can be certified **individually** (each with its own cert #) or **as a group** with no cert at all. Both must be supported.

### 5. Chain/length clause (for stone-less pieces — bracelets, chains)
Pattern: `[style name] [item type] weighs [weight] grams [karat] [metal color] gold [length] in length.`
Example: "Miami Cuban links bracelet weighs 32.0 grams 14karat yellow gold 7.5 in length." — no stone clauses at all for this item type.

### 6. Multi-item combination
When one appraisal covers multiple physical pieces (a stacked ring set, a wedding+engagement pair), each piece gets its own metal/stone clauses. Two valuation patterns observed:
- **Combined total**: one "Replacement Value" line covering all pieces together (e.g. 3-ring stack, Kim Eaton's wedding+engagement set)
- **Itemized per piece**: separate "Replacement Value [piece name]……$X" lines, one per piece (Phoenix Carter's — "Replacement Value engagement ring……$6,950.00" and "Replacement Value on the band……$2,500.00")

The app should support **both** — ask the user (or infer from whether pieces were priced separately) which valuation mode applies per appraisal.

### 7. Replacement Value clause
Always `Replacement Value…….$X,XXX.00` (two decimals, comma-separated). Occasionally includes a parenthetical market-price reference justifying part of the valuation, e.g. `1.08 carats ($4375/oz)` — a per-ounce gold price noted alongside the metal weight. This is optional context, not required on every appraisal, but the field should allow it.

## Special Flags

- **Lab-grown vs. natural diamonds**: IGI cert numbers prefixed "LG" (observed: LG651440496, LG648473332, LG644458) indicate lab-grown reports. This materially affects value and should be an **explicit flag the user sets**, not silently inferred from the cert-number prefix — inferring it wrong on a real appraisal is a real liability risk. Surface it as a toggle per stone: natural / lab-grown / unspecified.
- **Approximate/hedged quantities**: words like "about" before a weight ("about 0.50ctw") should map to the "approximately" normalization rule already defined in the main plan doc.
- **Stone sizing**: not all stones use carat weight — small or colored stones are sometimes sized by mm dimensions (e.g. "2X4mm", "5.7x4.3mm") instead of, or in addition to, carat.

## Full Anonymized Example Set (for parser training/testing)

1. "Ladies' custom made 14kt white gold ring set with 4 princess cut diamonds with the weight of 1.02 carat. These diamonds are VS1, G in color." — $6,850.00
2. "A custom made 14kt yellow gold diamonds pendant set with 1.32 carat marquise cut diamond SI1, I color in the center with 6 baguettes 0.34ctw VS2-SI1, H-I in color around it in a halo style. The Halo also consists of 10 round diamonds of SI1-SI2, H-I in color with the weight of 0.38ctw." — $13,900.00
3. "Ladies' 3 separated 14kt yellow gold custom made rings weigh 11.40grams set with 24 round brilliant cut diamonds. These diamonds are SI2-SI1, H-I in color with the weight of 1.04carat in total." — $7,850.00
4. "A 6.30 grams 14kt yellow gold custom made diamonds pendant set with one round brilliant cut diamond 0.86ct SI1, I color. The pendant also consists of 5 smaller round diamonds these diamonds are SI1, H-I in color with the weigh of 0.48ctw." — $9,500.00
5. "An 11.75 grams Ladies custom make 14kt two tone wedding ring set with a VS2, H color round brilliant cut diamond in the center weighs 0.79 carat the ring also consists of 29 round brilliant cut diamonds. These diamonds are SI1, G-H in color with the weight of 0.97 carat." — $9,900.00
6. "Ladies 6.90 grams 14kt white gold custom made ring set with 2X4mm round Blue Zircon on the top and 6 round diamonds are SI3, H in color with the weight of about 0.50ctw." — $3,950.00
7. "Ladies' custom made 14kt white gold wedding and engagement ring set with 1.02ct SI1, I color marquise cut diamond in the center in a halo style. The set also consists of 59 round brilliant cut diamonds. These diamonds are VS2-SI1, G in color with the weight of 1.39ct." — $17,900.00
8. "Ladies' custom-made engagement ring set with a GIA certified oval shape diamond #2476544628 SI2, E color 2.00carat in a platinum setting. The ring also consists of 16 round brilliant cut diamonds set in a hidden halo. These diamonds are VS1, G color weight 0.11 carat." — $27,900.00
9. "Miami Cuban links bracelet weighs 32.0 grams 14karat yellow gold 7.5 in length." — $4,900.00
10. "7.10 grams 14kt white gold custom made past present and future diamonds ring set with IGI certified LG651440496 round 3.23ct E, VS1 in the center. The 2 on the side are both IGI certified, LG648473332 and LG644458, they are both 1.04ct VVS1, E in color." — $12,899.00
11. "Ladies 8.90 grams custom made wedding and engagement rings set with marquise cut diamond in the center. This marquise diamond is certified by GIA #6542519109 2.50 carat G, SI1, the sets also consist of 10 round brilliant cut diamonds set on the side. These diamonds are VS1; G in color with the weight of 1.08 carats ($4375/oz)." — $49,250.00
12. "A custom-made 14kt yellow gold weighs 3.10grams engagement ring set with 5.7x4.3mm emerald cut VS1, G color weight 0.63ct in the center. Consist of 4 round brilliant cut diamonds along the side. These diamonds are SI1, H in color weigh 0.22 carat in total. The wedding band is also custom-made in 14kt yellow gold. The band sets with 7 round diamonds with total weigh of 0.40ctw." — Replacement Value engagement ring: $6,950.00 / Replacement Value on the band: $2,500.00

## Open Items for the Build

- [ ] Confirm whether "approximate" hedging should apply automatically whenever the source speech used a qualifier word, per the main plan doc's normalization rule
- [ ] Decide UI for the lab-grown/natural flag per stone (toggle, not silent inference)
- [ ] Decide UI for choosing combined-total vs. itemized-per-piece valuation when an appraisal covers multiple pieces
- [ ] Decide whether cert numbers attach at the stone level (supporting multiple per appraisal) in the data model — real examples show up to 3 per piece
- [ ] Confirm appraiser field should support name + optional free-text credential line, populated from a small roster (Tony Lee, Christopher D. Walker) but not hardcoded to just those two
