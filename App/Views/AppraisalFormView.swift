import SwiftUI

/// Top-level screen implementing the plan's Core Flow: template preview
/// with the anchored fields + photos, a free-typed/dictated description,
/// and export. The template preview here is a scaled-down live view (not
/// the print output itself) — `PDFExportService` renders the real
/// full-size composite for printing.
struct AppraisalFormView: View {
    @StateObject private var viewModel = AppraisalViewModel()
    @State private var isShowingShareSheet = false
    @State private var isShowingSavedAppraisals = false
    @State private var isShowingNewAppraisalConfirmation = false
    private let layout = TemplateLayout.default

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    templatePreview

                    TapToSpeakField(title: "Customer Name", text: $viewModel.appraisal.customerName, speech: viewModel.speech)

                    DatePicker("Date", selection: $viewModel.appraisal.date, displayedComponents: .date)

                    TapToSpeakField(title: "Address", text: $viewModel.appraisal.address, speech: viewModel.speech)

                    ReplacementValueSectionView(value: $viewModel.appraisal.replacementValue)

                    DescriptionBuilderView(
                        descriptionText: $viewModel.appraisal.descriptionText,
                        speech: viewModel.speech
                    )

                    exportButton
                    newAppraisalButton
                }
                .padding()
            }
            .navigationTitle("Tony's Jewelry Appraisal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingSavedAppraisals = true
                    } label: {
                        Label("Past Appraisals", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
            .onAppear { viewModel.requestPermissionsIfNeeded() }
            // Autosave: every field change (typed, dictated, a photo
            // added...) persists immediately via `AppraisalStore`, so
            // "look at old appraisals" (`SavedAppraisalsView`) never shows
            // stale data and nothing is lost if the app is backgrounded
            // mid-entry. `Appraisal` is already `Equatable`, so this only
            // actually fires on a real change.
            .onChange(of: viewModel.appraisal) { _, _ in viewModel.save() }
            .sheet(isPresented: $isShowingShareSheet) {
                if let url = viewModel.exportedPDFURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $isShowingSavedAppraisals) {
                SavedAppraisalsView { selected in
                    viewModel.load(selected)
                    isShowingSavedAppraisals = false
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
                PhotoCaptureView(photoFilename: $viewModel.appraisal.photoFilenames[0], region: layout.photoOne, containerSize: proxy.size)
                PhotoCaptureView(photoFilename: $viewModel.appraisal.photoFilenames[1], region: layout.photoTwo, containerSize: proxy.size)
                PhotoCaptureView(photoFilename: $viewModel.appraisal.photoFilenames[2], region: layout.photoThree, containerSize: proxy.size)
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

    /// Always available, not gated on having exported first — Tony might
    /// also want to set aside a half-filled appraisal (already autosaved,
    /// reachable later from Past Appraisals) and start the next one
    /// without exporting. So this needs its own "are you sure" rather than
    /// silently clearing the screen, since — unlike export — there's no
    /// action that visibly confirms the current entry was saved.
    private var newAppraisalButton: some View {
        Button {
            isShowingNewAppraisalConfirmation = true
        } label: {
            Label("New Appraisal", systemImage: "plus.circle")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.bordered)
        .confirmationDialog(
            "Start a new appraisal?",
            isPresented: $isShowingNewAppraisalConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start New") { viewModel.startNew() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This one is already saved — find it again under Past Appraisals.")
        }
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(get: { viewModel.exportError != nil }, set: { if !$0 { viewModel.exportError = nil } })
    }
}

#Preview {
    AppraisalFormView()
}
