import SwiftUI
import UIKit

@MainActor
final class AppraisalViewModel: ObservableObject {
    @Published var appraisal: Appraisal
    let speech = SpeechRecognitionService()

    @Published var exportedPDFURL: URL?
    @Published var exportError: String?

    init(itemType: ItemType = .ring) {
        self.appraisal = Appraisal(itemType: itemType)
    }

    func requestPermissionsIfNeeded() {
        Task { await speech.requestAuthorization() }
    }

    func export(layout: TemplateLayout) {
        let photo = appraisal.photoFilename.flatMap { PhotoStorage.load($0) }
        do {
            let url = try PDFExportService.export(appraisal: appraisal, layout: layout, photo: photo)
            exportedPDFURL = url
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }
}
