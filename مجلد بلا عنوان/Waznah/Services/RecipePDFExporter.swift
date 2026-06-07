//
//  RecipePDFExporter.swift
//  Waznah
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {
    static func makeImage(from string: String, length: CGFloat) -> UIImage? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(trimmed.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }

        let scale = length / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

enum RecipePDFExporter {
    static let pageWidth: CGFloat = 595
    
    @MainActor
    static func makePDFURL(from data: RecipeShareData) -> URL? {
        let content = RecipePDFDocumentView(data: data)
            .frame(width: pageWidth, alignment: .topLeading)
        
        guard let image = renderImage(from: content, width: pageWidth) else {
            return nil
        }
        
        let pageHeight = max(image.size.height, 720)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let pdfData = UIGraphicsPDFRenderer(bounds: pageRect).pdfData { context in
            context.beginPage()
            image.draw(in: pageRect)
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(data.pdfFileName)
        
        do {
            try pdfData.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
    
    @MainActor
    private static func renderImage<V: View>(from view: V, width: CGFloat) -> UIImage? {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                return uiImage
            }
        }
        
        return renderImageWithHostingController(from: view, width: width)
    }
    
    @MainActor
    private static func renderImageWithHostingController<V: View>(from view: V, width: CGFloat) -> UIImage? {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .white
        hostingController.view.semanticContentAttribute = AppLanguage.isRightToLeft
            ? .forceRightToLeft
            : .forceLeftToRight
        
        let targetSize = hostingController.sizeThatFits(
            in: CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        )
        let size = CGSize(width: width, height: max(targetSize.height, 1))
        
        hostingController.view.bounds = CGRect(origin: .zero, size: size)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
}
