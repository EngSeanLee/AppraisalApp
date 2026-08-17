import UIKit

extension UIImage {
    /// Camera photos carry their rotation as EXIF orientation metadata
    /// rather than baked into the pixel buffer — UIKit/SwiftUI display
    /// code (and `PDFExportService`'s `image.draw(in:)`) handles that
    /// transparently, but cropping the raw `cgImage` does not. `PhotoCropView`
    /// redraws through here first so every later size/crop calculation can
    /// trust `.size` and `.cgImage` without also reasoning about
    /// `.imageOrientation`.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }
}
