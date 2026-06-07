//
//  ShareSheet.swift
//  Waznah
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

enum SharePresenter {
    @MainActor
    static func present(items: [Any]) {
        guard !items.isEmpty else { return }
        
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popover = controller.popoverPresentationController {
            let sourceView = topViewController()?.view ?? UIView()
            popover.sourceView = sourceView
            popover.sourceRect = CGRect(
                x: sourceView.bounds.midX,
                y: sourceView.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }
        
        topViewController()?.present(controller, animated: true)
    }
    
    @MainActor
    private static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

struct RecipePDFShareButton: View {
    let shareData: RecipeShareData
    @State private var showShareError = false
    
    var body: some View {
        WaznahCircleIconButton(systemName: "square.and.arrow.up", diameter: 48) {
            sharePDF()
        }
        .alert("Could not share recipe".localized(), isPresented: $showShareError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("The recipe PDF could not be created. Please try again.".localized())
        }
    }
    
    @MainActor
    private func sharePDF() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        guard let url = RecipePDFExporter.makePDFURL(from: shareData) else {
            showShareError = true
            return
        }
        
        SharePresenter.present(items: [url])
    }
}
