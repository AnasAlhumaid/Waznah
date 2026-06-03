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
        ZStack {
            Blur(radius: 20, opaque: true)

            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(2.0) // Adjust the scale as needed

                Text("Loading...")
                    .foregroundColor(.black)
                    .padding(.top, 8)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
    }
}




