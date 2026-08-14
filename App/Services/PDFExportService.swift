import UIKit

/// Core Flow step 5: "app composites everything into a single-page PDF,
/// ready to print and stamp." Renders the template + four fields + photo
/// directly into a PDF context at US Letter size, independent of whatever
/// scale the on-screen preview happened to use.
enum PDFExportService {
    enum ExportError: LocalizedError {
        case renderingFailed
        var errorDescription: String? { "The PDF could not be generated." }
    }

    /// US Letter at 72pt/inch — the standard PDF page-geometry unit.
    /// (This is not image resolution: embedded photos keep their own pixel
    /// detail regardless of page point size.)
    private static let pageSize = CGSize(width: 8.5 * 72, height: 11 * 72)

    static func export(appraisal: Appraisal, layout: TemplateLayout, photo: UIImage?) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        let data = renderer.pdfData { context in
            context.beginPage()
            let page = CGRect(origin: .zero, size: pageSize)

            drawBackground(in: page)
            drawText(appraisal.customerName, in: rect(for: layout.customerName, page: page), maxFontSize: 16)
            drawText(formattedDate(appraisal.date), in: rect(for: layout.date, page: page), maxFontSize: 14)
            drawText(appraisal.address, in: rect(for: layout.address, page: page), maxFontSize: 14)
            drawText(appraisal.descriptionText, in: rect(for: layout.itemDescription, page: page), maxFontSize: 13)

            if let photo {
                drawPhoto(photo, in: rect(for: layout.photo, page: page))
            }
        }

        let filename = exportFilename(for: appraisal)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
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

        while fontSize > 6 {
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

    private static func exportFilename(for appraisal: Appraisal) -> String {
        let safeName = appraisal.customerName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "-")
        let base = safeName.isEmpty ? "appraisal" : safeName
        return "\(base)-\(Int(appraisal.date.timeIntervalSince1970)).pdf"
    }
}
