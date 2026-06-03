//
//  LottieAnimation.swift
//  Waznah
//
//  Created by Anas Hamad on 11/5/23.
//


import Lottie
import SwiftUI

struct LottieView : UIViewRepresentable{
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name:"Animation - 1699163423982")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        
        ])
        
        return view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }

    
}
