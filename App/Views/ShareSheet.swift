import SwiftUI
import UIKit

/// Wraps the standard iOS share sheet so the exported PDF can go straight
/// to AirPrint or wherever else, without a custom export UI.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
