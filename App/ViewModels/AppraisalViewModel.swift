import SwiftUI
import UIKit

@MainActor
final class AppraisalViewModel: ObservableObject {
    @Published var appraisal: Appraisal
    let speech = SpeechRecognitionService()

    @Published var exportedPDFURL: URL?
    @Published var exportError: String?

    init() {
        self.appraisal = Appraisal()
    }

    /// Swaps in an existing appraisal for editing — used when Tony reopens
    /// one from `SavedAppraisalsView`. Clears any export state left over
    /// from whatever was on screen before.
    func load(_ appraisal: Appraisal) {
        self.appraisal = appraisal
        exportedPDFURL = nil
        exportError = nil
    }

    /// Clears the form for the next customer, so after exporting Tony can
    /// chain straight into the next appraisal instead of navigating back
    /// out. Doesn't need to explicitly save the outgoing appraisal first —
    /// autosave (`AppraisalFormView`'s `.onChange(of: viewModel.appraisal)`)
    /// already persisted every change as it happened, and it's still
    /// reachable from `SavedAppraisalsView` afterward.
    func startNew() {
        appraisal = Appraisal()
        exportedPDFURL = nil
        exportError = nil
    }

    func requestPermissionsIfNeeded() {
        Task { await speech.requestAuthorization() }
    }

    /// Persists the current appraisal to `AppraisalStore`.
    func save() {
        AppraisalStore.save(appraisal)
    }

    func export(layout: TemplateLayout) {
        let photos = appraisal.photoFilenames.map { filename in filename.flatMap { PhotoStorage.load($0) } }
        do {
            let url = try PDFExportService.export(appraisal: appraisal, layout: layout, photos: photos)
            exportedPDFURL = url
            exportError = nil
            save() // exporting is also a natural save checkpoint
        } catch {
            exportError = error.localizedDescription
        }
    }
}
