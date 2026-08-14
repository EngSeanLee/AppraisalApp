import UIKit

/// Saves captured piece photos to the app's Documents directory as JPEGs,
/// keyed by filename. `Appraisal` stores just the filename (not raw image
/// data) so the model stays small and Codable.
enum PhotoStorage {
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    @discardableResult
    static func save(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        let url = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    static func load(_ filename: String) -> UIImage? {
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ filename: String) {
        let url = documentsURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
