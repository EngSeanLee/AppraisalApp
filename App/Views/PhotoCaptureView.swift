import SwiftUI
import UIKit

/// Core Flow step 4: "User taps a 'Photo' step, takes a picture of the
/// piece, and it's automatically placed and sized into a designated photo
/// region on the template."
struct PhotoCaptureView: View {
    @Binding var photoFilename: String?
    var region: CGRect
    var containerSize: CGSize

    @State private var isShowingCamera = false
    @State private var cachedImage: UIImage?

    var body: some View {
        Button(action: { isShowingCamera = true }) {
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
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureView { image in
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
