//
//  BlurView.swift
//  Waznah
//
//  Created by Anas Hamad on 10/4/22.
//

import SwiftUI

 class UIBackdropView: UIView {

  open override class var layerClass: AnyClass {
    NSClassFromString("CABackdropLayer") ?? CALayer.self
  }
}

 struct Backdrop: UIViewRepresentable {

 

   func makeUIView(context: Context) -> UIBackdropView {
    UIBackdropView()
  }

   func updateUIView(_ uiView: UIBackdropView, context: Context) {}
}

public struct Blur: View {

    var radius :CGFloat = 3
    var opaque: Bool = false

    public var body: some View {
    Backdrop()
      .blur(radius: radius, opaque: opaque)
  }
}
