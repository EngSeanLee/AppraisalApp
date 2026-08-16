import SwiftUI
import UIKit

/// Full-screen crop step shown after a photo is captured/picked, before
/// it's saved into a `PhotoCaptureView` slot. Every photo slot on the
/// template renders roughly square (see `TemplateLayout.photoSlots`), so
/// this always crops to a fixed 1:1 square — there's no aspect-ratio
/// picker, matching the rest of the app's "one clear path, no options Tony
/// doesn't need" style (see `ReplacementValueSectionView`'s doc comment
/// for the same philosophy elsewhere in the app).
///
/// Sized against `UIScreen.main.bounds` rather than driven by a
/// `GeometryReader`, since this is always shown full-screen — a fixed size
/// keeps the pan/zoom clamping math below simple to reason about without a
/// device to test on. Flag if that ever needs to change (e.g. for
/// multitasking/iPad split view — this app is iPhone-only per
/// `project.yml`'s `TARGETED_DEVICE_FAMILY`, so that's not a concern yet).
struct PhotoCropView: View {
    var onCrop: (UIImage) -> Void
    var onCancel: () -> Void

    private let normalizedImage: UIImage
    private let imageSize: CGSize

    init(image: UIImage, onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.onCrop = onCrop
        self.onCancel = onCancel
        let normalized = image.normalizedOrientation()
        self.normalizedImage = normalized
        self.imageSize = normalized.size
    }

    private var cropSize: CGFloat {
        min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.86
    }

    /// The zoom level at which the image exactly covers the crop square
    /// (its shorter dimension matches `cropSize`, the same "fill" behavior
    /// `PhotoCaptureView` uses for the saved thumbnail) — the floor that
    /// `scale` and the pan clamping below are measured against, so the
    /// crop square can never show empty space past the image's edge.
    private var baseFillScale: CGFloat {
        max(cropSize / imageSize.width, cropSize / imageSize.height)
    }

    private var totalScale: CGFloat { baseFillScale * scale }

    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: normalizedImage)
                    .resizable()
                    .frame(width: imageSize.width * totalScale, height: imageSize.height * totalScale)
                    .offset(offset)
                    .gesture(dragGesture.simultaneously(with: magnifyGesture))

                cropOverlay
            }
            .navigationTitle("Crop Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Photo", action: confirmCrop)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    /// Dims everything outside the crop square using an even-odd fill —
    /// a `Path` containing both the full-screen rect and the (smaller,
    /// nested) crop-square rect cancels out where they overlap, leaving a
    /// translucent "frame with a hole" without needing blend modes.
    private var cropOverlay: some View {
        GeometryReader { proxy in
            let full = proxy.size
            let squareOrigin = CGPoint(x: (full.width - cropSize) / 2, y: (full.height - cropSize) / 2)
            Path { path in
                path.addRect(CGRect(origin: .zero, size: full))
                path.addRect(CGRect(origin: squareOrigin, size: CGSize(width: cropSize, height: cropSize)))
            }
            .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
            .overlay(
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
            )
            .allowsHitTesting(false)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = clampedOffset(
                    CGSize(
                        width: committedOffset.width + value.translation.width,
                        height: committedOffset.height + value.translation.height
                    )
                )
            }
            .onEnded { _ in committedOffset = offset }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1, committedScale * value)
                offset = clampedOffset(offset) // zooming out can put the old offset out of bounds
            }
            .onEnded { _ in
                committedScale = scale
                committedOffset = offset
            }
    }

    /// Keeps the image covering the crop square at all times. Half the
    /// overhang (displayed size minus the crop square, in each dimension)
    /// is exactly how far the image's center can shift before its edge
    /// reaches the crop square's edge.
    private func clampedOffset(_ proposed: CGSize) -> CGSize {
        let displayedWidth = imageSize.width * totalScale
        let displayedHeight = imageSize.height * totalScale
        let maxX = max(0, (displayedWidth - cropSize) / 2)
        let maxY = max(0, (displayedHeight - cropSize) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    /// Inverts the on-screen display transform (center + `totalScale` +
    /// `offset`) to find what the crop square spans in the source image's
    /// own coordinate space, then crops the actual pixel buffer to that.
    private func confirmCrop() {
        let displayedWidth = imageSize.width * totalScale
        let displayedHeight = imageSize.height * totalScale
        // Top-left of the displayed image, relative to the crop square's
        // own top-left — both measured in the same on-screen point space
        // (the crop square sits centered in the same full-screen ZStack
        // the image is centered in).
        let imageOriginInCropFrame = CGPoint(
            x: (cropSize - displayedWidth) / 2 + offset.width,
            y: (cropSize - displayedHeight) / 2 + offset.height
        )
        let cropInImagePoints = CGRect(
            x: -imageOriginInCropFrame.x / totalScale,
            y: -imageOriginInCropFrame.y / totalScale,
            width: cropSize / totalScale,
            height: cropSize / totalScale
        )
        // `.size` is point space; the backing pixel buffer is larger by
        // `.scale` (e.g. 3x on most iPhones) — scale up to crop the actual
        // pixels, not a downsampled fraction of them.
        let pixelScale = normalizedImage.scale
        let cropInPixels = CGRect(
            x: cropInImagePoints.minX * pixelScale,
            y: cropInImagePoints.minY * pixelScale,
            width: cropInImagePoints.width * pixelScale,
            height: cropInImagePoints.height * pixelScale
        ).integral

        let pixelBounds = CGRect(x: 0, y: 0, width: normalizedImage.size.width * pixelScale, height: normalizedImage.size.height * pixelScale)
        guard let cgImage = normalizedImage.cgImage,
              let cropped = cgImage.cropping(to: cropInPixels.intersection(pixelBounds)) else {
            onCrop(normalizedImage) // fall back to the uncropped photo rather than losing it
            return
        }
        onCrop(UIImage(cgImage: cropped, scale: pixelScale, orientation: .up))
    }
}
