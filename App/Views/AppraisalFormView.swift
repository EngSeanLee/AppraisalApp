import SwiftUI

/// Top-level screen implementing the plan's Core Flow: template preview
/// with the four anchored fields + photo, guided description builder, and
/// export. The template preview here is a scaled-down live view (not the
/// print output itself) — `PDFExportService` renders the real full-size
/// composite for printing.
struct AppraisalFormView: View {
    @StateObject private var viewModel = AppraisalViewModel()
    @State private var isShowingShareSheet = false
    private let layout = TemplateLayout.default

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    templatePreview

                    TapToSpeakField(title: "Customer Name", text: $viewModel.appraisal.customerName, speech: viewModel.speech)

                    DatePicker("Date", selection: $viewModel.appraisal.date, displayedComponents: .date)

                    TapToSpeakField(title: "Address", text: $viewModel.appraisal.address, speech: viewModel.speech)

                    AppraiserFieldView(appraiser: $viewModel.appraisal.appraiser, speech: viewModel.speech)

                    ValuationSectionView(
                        valuationMode: $viewModel.appraisal.valuationMode,
                        combinedValue: $viewModel.appraisal.combinedReplacementValue
                    )

                    DescriptionBuilderView(
                        pieces: $viewModel.appraisal.pieces,
                        valuationMode: viewModel.appraisal.valuationMode,
                        descriptionText: $viewModel.appraisal.descriptionText,
                        manuallyEdited: $viewModel.appraisal.descriptionManuallyEdited,
                        speech: viewModel.speech
                    )

                    exportButton
                }
                .padding()
            }
            .navigationTitle("Tony's Jewelry Appraisal")
            .onAppear { viewModel.requestPermissionsIfNeeded() }
            .sheet(isPresented: $isShowingShareSheet) {
                if let url = viewModel.exportedPDFURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Couldn't export PDF", isPresented: exportErrorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.exportError ?? "")
            }
        }
    }

    private var templatePreview: some View {
        GeometryReader { proxy in
            ZStack {
                TemplateBackgroundView(layout: layout)
                PhotoCaptureView(photoFilename: $viewModel.appraisal.photoFilename, region: layout.photo, containerSize: proxy.size)
            }
        }
        .aspectRatio(8.5 / 11, contentMode: .fit)
    }

    private var exportButton: some View {
        Button {
            viewModel.export(layout: layout)
            if viewModel.exportedPDFURL != nil {
                isShowingShareSheet = true
            }
        } label: {
            Label("Export PDF", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.appraisal.isReadyToExport)
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(get: { viewModel.exportError != nil }, set: { if !$0 { viewModel.exportError = nil } })
    }
}

#Preview {
    AppraisalFormView()
}
