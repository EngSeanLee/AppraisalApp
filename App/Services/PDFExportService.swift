import UIKit

/// Core Flow step 5: "app composites everything into a single-page PDF,
/// ready to print and stamp." Renders the template + every `TemplateLayout`
/// region directly into a PDF context at US Letter size, independent of
/// whatever scale the on-screen preview happened to use.
enum PDFExportService {
    enum ExportError: LocalizedError {
        case renderingFailed
        var errorDescription: String? { "The PDF could not be generated." }
    }

    /// US Letter at 72pt/inch — the standard PDF page-geometry unit.
    /// (This is not image resolution: embedded photos keep their own pixel
    /// detail regardless of page point size.)
    private static let pageSize = CGSize(width: 8.5 * 72, height: 11 * 72)

    /// `photos` is positionally matched to `layout.photoSlots` (index 0 =
    /// leftmost slot); fewer than 3 elements or nil entries just leave that
    /// slot blank.
    static func export(appraisal: Appraisal, layout: TemplateLayout, photos: [UIImage?]) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        let data = renderer.pdfData { context in
            context.beginPage()
            let page = CGRect(origin: .zero, size: pageSize)

            drawBackground(in: page)
            // The letterhead has no pre-printed field labels (see
            // TemplateLayout's doc comment) — without a label baked into
            // what we draw, the printed page is just floating values with
            // nothing saying what they are. Replacement Value doesn't need
            // one: its own displayString already starts with the words
            // "Replacement Value".
            drawLabeledText("Name", appraisal.customerName, in: rect(for: layout.customerName, page: page), maxFontSize: 16)
            drawLabeledText("Date", formattedDate(appraisal.date), in: rect(for: layout.date, page: page), maxFontSize: 14)
            drawLabeledText("Address", appraisal.address, in: rect(for: layout.address, page: page), maxFontSize: 14)
            drawLabeledText("Description", appraisal.descriptionText, in: rect(for: layout.itemDescription, page: page), maxFontSize: 13)
            drawText(appraisal.replacementValue.displayString, in: rect(for: layout.replacementValue, page: page), maxFontSize: 13)

            for (photo, slot) in zip(photos, layout.photoSlots) {
                if let photo {
                    drawPhoto(photo, in: rect(for: slot, page: page))
                }
            }

            drawPerLine(in: rect(for: layout.perLine, page: page))
            // Small print, drawn last so it always sits on top. Its own
            // `drawNotice` rather than plain `drawText` -- see that
            // function for why (tighter paragraph spacing, hard clip).
            drawNotice(NoticeText.disclaimer, in: rect(for: layout.notice, page: page), maxFontSize: 7)
        }

        let filename = exportFilename(for: appraisal)
        let url = exportedPDFsDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }

    /// Documents, not Application Support (where `PhotoStorage` and
    /// `AppraisalStore` keep their private files) — this is the one thing
    /// in the app deliberately made visible in the Files app
    /// (`UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInBrowser` in
    /// `project.yml`), so every exported PDF is sitting in Files → On My
    /// iPhone → JewelryAppraisal right after export, with no extra save
    /// step. `.documentDirectory` always exists on iOS, unlike Application
    /// Support, so there's nothing to create here.
    private static var exportedPDFsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Drawing

    private static func drawBackground(in page: CGRect) {
        if let template = UIImage(named: TemplateAsset.name) {
            template.draw(in: page)
        } else {
            UIColor.white.setFill()
            UIRectFill(page)
            UIColor.darkGray.setStroke()
            let border = UIBezierPath(rect: page.insetBy(dx: 18, dy: 18))
            border.lineWidth = 1
            border.stroke()
        }
    }

    private static func drawPhoto(_ image: UIImage, in rect: CGRect) {
        // Aspect-fill then clip, so the photo fills its region without
        // distortion regardless of the piece photo's own aspect ratio.
        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        var drawRect = rect

        if imageAspect > rectAspect {
            let scaledWidth = rect.height * imageAspect
            drawRect = CGRect(x: rect.midX - scaledWidth / 2, y: rect.minY, width: scaledWidth, height: rect.height)
        } else {
            let scaledHeight = rect.width / imageAspect
            drawRect = CGRect(x: rect.minX, y: rect.midY - scaledHeight / 2, width: rect.width, height: scaledHeight)
        }

        UIGraphicsGetCurrentContext()?.saveGState()
        UIBezierPath(rect: rect).addClip()
        image.draw(in: drawRect)
        UIGraphicsGetCurrentContext()?.restoreGState()
    }

    /// "Name: Jane Smith" — prepends a printed label so the field reads as
    /// something on a blank letterhead with no pre-printed labels of its
    /// own. Skipped entirely (not even the bare label) when `value` is
    /// empty, same as plain `drawText`.
    private static func drawLabeledText(_ label: String, _ value: String, in rect: CGRect, maxFontSize: CGFloat) {
        guard !value.isEmpty else { return }
        drawText("\(label): \(value)", in: rect, maxFontSize: maxFontSize)
    }

    /// Draws `text` centered-fit within `rect`, shrinking the font until it
    /// fits — the PDF equivalent of the on-screen `minimumScaleFactor`
    /// behavior called for in the plan's tech stack notes.
    private static func drawText(_ text: String, in rect: CGRect, maxFontSize: CGFloat) {
        guard !text.isEmpty else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        var fontSize = maxFontSize
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ]

        // `>=`, not `>` — with `>`, the loop body never runs again once
        // `fontSize` reaches 6 (the condition fails before re-testing), so
        // `attributes` is left holding whatever size was last *tested and
        // rejected* one iteration earlier. The intended 6pt floor was
        // therefore never actually reachable: any text still too tall at
        // 7pt silently drew at 7pt anyway and overflowed past `rect`'s
        // bottom edge rather than shrinking further. Caught via
        // `NoticeText.disclaimer` overflowing into the template border on
        // a real device — every other caller's text happened to already
        // fit by 7pt, so this never showed up before.
        while fontSize >= 6 {
            attributes[.font] = UIFont.systemFont(ofSize: fontSize)
            let bounding = (text as NSString).boundingRect(
                with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: attributes,
                context: nil
            )
            if bounding.height <= rect.height { break }
            fontSize -= 1
        }

        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
    }

    /// Fourth attempt at fitting `NoticeText.disclaimer` (~1,225 characters,
    /// two paragraphs) into the notice box. Rounds 1-3 all treated this as
    /// a pure vertical-fit problem (reserve enough height, shrink the font,
    /// clip as a backstop) and kept missing because the actual constraint
    /// isn't a rectangle at all: `AppraisalTemplate.png`'s border has
    /// decorative corner medallions that curve inward at the bottom-left
    /// and bottom-right corners, past where the straight-edge margin
    /// (measured for every other field) applies. Measured directly off the
    /// artwork: the curve starts around y-fraction 0.897 (about a third of
    /// the way up from `TemplateLayout.notice`'s bottom edge) and reaches
    /// as far as x-fraction 0.127 from the left (and the mirror image from
    /// the right) by the box's bottom edge -- well inside the 0.09/0.91
    /// margin every other field uses safely. Round 3's taller box put the
    /// notice's own bottom two corners right in that zone, so no amount of
    /// vertical-only fixing was ever going to stop it landing on the
    /// medallions.
    ///
    /// Fix: lay the text out with `NSTextContainer.exclusionPaths` instead
    /// of plain `NSString` layout, so lines that fall in the bottom third
    /// of the box actually narrow around both corner medallions instead of
    /// running straight through them. `cornerExclusion` is sized a few
    /// points larger than the measured curve (conservative on purpose --
    /// slightly over-excluding costs a little width on the last couple of
    /// lines; under-excluding is the bug being fixed). The hard clip to
    /// `rect` from round 3 stays as a backstop underneath this.
    ///
    /// Not verified against a real printed page (no device/printer in this
    /// environment) -- corner measurements come from reading pixel values
    /// off the actual letterhead asset, not a guess, but the on-device
    /// render is still the real check.
    private static func drawNotice(_ text: String, in rect: CGRect, maxFontSize: CGFloat) {
        guard !text.isEmpty else { return }

        let collapsed = text.replacingOccurrences(of: "\n\n", with: "\n")

        // Bottom third of the box, ~28pt in from each side -- covers the
        // measured medallion curve (starts ~y=0.67*rect.height, reaches
        // ~25pt in from each edge at the very bottom) with a few points of
        // margin. Anchored to rect.height so it stays pinned to the box's
        // actual bottom edge regardless of the tall measurement container
        // used below.
        let exclusionWidth: CGFloat = 28
        let exclusionHeight: CGFloat = 30
        let cornerExclusion: (CGFloat) -> UIBezierPath = { x in
            UIBezierPath(rect: CGRect(x: x, y: rect.height - exclusionHeight, width: exclusionWidth, height: exclusionHeight))
        }
        let exclusionPaths = [cornerExclusion(0), cornerExclusion(rect.width - exclusionWidth)]

        var fontSize = maxFontSize
        var layoutManager = NSLayoutManager()
        var textContainer = NSTextContainer()

        while fontSize >= 6 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.lineHeightMultiple = 0.92
            paragraphStyle.paragraphSpacing = fontSize * 0.5
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .paragraphStyle: paragraphStyle
            ]

            let storage = NSTextStorage(string: collapsed, attributes: attributes)
            let manager = NSLayoutManager()
            storage.addLayoutManager(manager)
            // Tall measurement container so the full text always lays out
            // (no truncation to measure against) -- `exclusionPaths` still
            // applies at its fixed y-offset from the top, so the corner
            // narrowing is measured the same way it'll actually draw.
            let container = NSTextContainer(size: CGSize(width: rect.width, height: .greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            container.exclusionPaths = exclusionPaths
            manager.addTextContainer(container)
            manager.glyphRange(for: container) // force layout

            layoutManager = manager
            textContainer = container

            if manager.usedRect(for: container).height <= rect.height { break }
            fontSize -= 1
        }

        // Backstop: whatever the loop above landed on, never let the
        // actual draw paint outside `rect` -- if the exclusion measurement
        // is still wrong somehow, worst case is a clipped line, not text
        // on the medallions or the border again.
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        UIBezierPath(rect: rect).addClip()
        layoutManager.drawGlyphs(forGlyphRange: layoutManager.glyphRange(for: textContainer), at: rect.origin)
        context?.restoreGState()
    }

    /// A static "PER ________________" label + blank line — not bound to
    /// any `Appraisal` field. The appraiser is always Tony, signing or
    /// stamping this by hand after printing, so there's nothing to type;
    /// the app just needs to leave the line for him. Sized down from 13pt
    /// (and `TemplateLayout.perLine` shrunk to match) per UAT feedback —
    /// it was crowding the photo row above it.
    private static func drawPerLine(in rect: CGRect) {
        let label = "PER"
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
        (label as NSString).draw(at: rect.origin, withAttributes: attributes)

        let labelWidth = (label as NSString).size(withAttributes: attributes).width
        let lineY = rect.minY + rect.height / 2
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + labelWidth + 8, y: lineY))
        path.addLine(to: CGPoint(x: rect.maxX, y: lineY))
        path.lineWidth = 1
        UIColor.darkGray.setStroke()
        path.stroke()
    }

    // MARK: - Helpers

    private static func rect(for normalized: CGRect, page: CGRect) -> CGRect {
        CGRect(
            x: normalized.minX * page.width,
            y: normalized.minY * page.height,
            width: normalized.width * page.width,
            height: normalized.height * page.height
        )
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// "<Customer Name>-appraisal.pdf" — no timestamp. Exporting the same
    /// customer's appraisal again overwrites rather than piling up
    /// timestamped duplicates, which is what was actually wanted in
    /// practice.
    private static func exportFilename(for appraisal: Appraisal) -> String {
        let safeName = appraisal.customerName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "-")
        let base = safeName.isEmpty ? "appraisal" : safeName
        return "\(base)-appraisal.pdf"
    }
}
