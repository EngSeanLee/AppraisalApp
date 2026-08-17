import UIKit

/// Saves captured piece photos as JPEGs, keyed by filename. `Appraisal`
/// stores just the filename (not raw image data) so the model stays small
/// and Codable.
///
/// Lives in Application Support, not Documents. Documents is what
/// `UIFileSharingEnabled` exposes in the Files app (see
/// `PDFExportService`, which *does* write there for the exported PDFs) —
/// these raw, UUID-named JPEGs (and `AppraisalStore`'s JSON records
/// alongside them) are internal app data Tony should never see, rename, or
/// accidentally delete from Files. Application Support is private to the
/// app.
enum PhotoStorage {
    private static var photosDirectory: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos", isDirectory: true)
        // Unlike Documents, Application Support isn't guaranteed to exist
        // yet — `withIntermediateDirectories: true` creates it (and this
        // Photos subfolder) in one call if needed.
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @discardableResult
    static func save(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        let url = photosDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    static func load(_ filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ filename: String) {
        let url = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
