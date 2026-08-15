import SwiftUI
import UIKit

/// Core Flow step 4: "User taps a 'Photo' step, takes a picture of the
/// piece, and it's automatically placed and sized into a designated photo
/// region on the template." Tapping offers a choice between the camera and
/// the photo library — not every photo of a piece is taken fresh in the
/// moment; some are already on the phone.
struct PhotoCaptureView: View {
    @Binding var photoFilename: String?
    var region: CGRect
    var containerSize: CGSize

    @State private var isShowingSourcePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType?
    @State private var cachedImage: UIImage?

    var body: some View {
        Button(action: { isShowingSourcePicker = true }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: photoFilename == nil ? [4, 3] : []))

                if let image = cachedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "camera")
                            .imageScale(.large)
                        Text("Photo").font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: region.width * containerSize.width, height: region.height * containerSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .position(
            x: (region.minX + region.width / 2) * containerSize.width,
            y: (region.minY + region.height / 2) * containerSize.height
        )
        .confirmationDialog("Add Photo", isPresented: $isShowingSourcePicker, titleVisibility: .visible) {
            Button("Take Photo") { pickerSourceType = .camera }
            Button("Choose from Library") { pickerSourceType = .photoLibrary }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $pickerSourceType) { sourceType in
            CameraCaptureView(sourceType: sourceType) { image in
                if let filename = PhotoStorage.save(image) {
                    if let old = photoFilename { PhotoStorage.delete(old) }
                    photoFilename = filename
                    cachedImage = image
                }
            }
            .ignoresSafeArea()
        }
        .onAppear(perform: loadCachedImage)
        .onChange(of: photoFilename) { _, _ in loadCachedImage() }
    }

    private func loadCachedImage() {
        guard let photoFilename else {
            cachedImage = nil
            return
        }
        cachedImage = PhotoStorage.load(photoFilename)
    }
}

// So `.sheet(item:)` can key off which source type was picked — UIKit's
// own `UIImagePickerController.SourceType` isn't Identifiable.
extension UIImagePickerController.SourceType: @retroactive Identifiable {
    public var id: Int { rawValue }
}
