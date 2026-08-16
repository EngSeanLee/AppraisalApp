import SwiftUI
import UIKit

/// Core Flow step 4: "User taps a 'Photo' step, takes a picture of the
/// piece, and it's automatically placed and sized into a designated photo
/// region on the template." Tapping offers a choice between the camera and
/// the photo library — not every photo of a piece is taken fresh in the
/// moment; some are already on the phone. Every captured/picked photo goes
/// through `PhotoCropView` before it's saved, so Tony can frame the piece
/// tight in the slot rather than relying on whatever the source photo's
/// framing happened to be.
struct PhotoCaptureView: View {
    @Binding var photoFilename: String?
    var region: CGRect
    var containerSize: CGSize

    @State private var isShowingSourcePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType?
    /// Set once the source picker hands back an image; drives the crop
    /// sheet below. Cleared (back to `nil`) whether the crop is confirmed
    /// or canceled.
    @State private var imagePendingCrop: UIImage?
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
                // Hands off to the crop step (below) rather than saving
                // straight away.
                imagePendingCrop = image
            }
            .ignoresSafeArea()
        }
        .sheet(item: $imagePendingCrop) { image in
            PhotoCropView(image: image) { cropped in
                if let filename = PhotoStorage.save(cropped) {
                    if let old = photoFilename { PhotoStorage.delete(old) }
                    photoFilename = filename
                    cachedImage = cropped
                }
                imagePendingCrop = nil
            } onCancel: {
                imagePendingCrop = nil
            }
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

// Likewise for chaining straight into the crop sheet once a photo comes
// back from the picker — this sheet only ever shows one photo at a time,
// and `imagePendingCrop` is cleared (back to nil) as soon as that crop
// step finishes either way, so object identity is a fine key here.
extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
