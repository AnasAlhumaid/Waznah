//
//  Alerts.swift
//  Waznah
//
//  Created by Anas Hamad on 12/16/23.
//

import Foundation
import SwiftUI

struct LoadingAlert: View {
    var body: some View {
        // Compact, fixed-size card only — no full-screen layer, so it never takes over the page.
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(Color(hex: "#86373E"))

            Text("Loading...".localized())
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .frame(width: 132, height: 112)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
        .fixedSize()
        .transition(.opacity)
        .accessibilityElement(children: .combine)
    }
}




