import Foundation

/// Saves/loads/lists appraisals as individual JSON files in Application
/// Support (private — see `PhotoStorage`'s doc comment for why this isn't
/// Documents), so Tony can come back to an appraisal he started earlier,
/// reopen it, and either finish or edit it. One file per appraisal, named
/// by its `Appraisal.id`, so saving the same appraisal again just
/// overwrites its own file rather than piling up duplicates.
enum AppraisalStore {
    private static var appraisalsDirectory: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Appraisals", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func url(for id: UUID) -> URL {
        appraisalsDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    /// Skips writing a blank, never-touched appraisal — see
    /// `Appraisal.isBlank`. Called from `AppraisalFormView` on every field
    /// change; a single-page JSON record is cheap enough to write on each
    /// change without debouncing.
    static func save(_ appraisal: Appraisal) {
        guard !appraisal.isBlank else { return }
        guard let data = try? JSONEncoder.appraisal.encode(appraisal) else { return }
        try? data.write(to: url(for: appraisal.id))
    }

    /// Removes the saved record and its photos. Photos live in
    /// `PhotoStorage`, keyed by filename rather than by appraisal, so they
    /// have to be deleted explicitly here — nothing else will notice they
    /// became orphaned.
    static func delete(_ appraisal: Appraisal) {
        try? FileManager.default.removeItem(at: url(for: appraisal.id))
        for case let filename? in appraisal.photoFilenames {
            PhotoStorage.delete(filename)
        }
    }

    /// All saved appraisals, most recently edited first. Sorted by each
    /// file's own modification date rather than `Appraisal.date` (the
    /// appraisal date Tony picks, which he might backdate) — "most
    /// recently edited" is the more useful ordering for "go back and look
    /// at" than the appraisal's own date field.
    static func loadAll() -> [Appraisal] {
        let fileManager = FileManager.default
        guard let urls = try? fileManager.contentsOfDirectory(
            at: appraisalsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return [] }

        let withDates: [(appraisal: Appraisal, modified: Date)] = urls.compactMap { url in
            guard url.pathExtension == "json",
                  let data = try? Data(contentsOf: url),
                  let appraisal = try? JSONDecoder.appraisal.decode(Appraisal.self, from: data) else { return nil }
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                ?? appraisal.date
            return (appraisal, modified)
        }

        return withDates.sorted { $0.modified > $1.modified }.map(\.appraisal)
    }
}

private extension JSONEncoder {
    /// ISO-8601 dates so `Appraisal.date` round-trips exactly — the
    /// default `.deferredToDate` strategy encodes a raw `TimeInterval`,
    /// which is harder to eyeball if anyone ever inspects these files
    /// directly.
    static let appraisal: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder {
    static let appraisal: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
