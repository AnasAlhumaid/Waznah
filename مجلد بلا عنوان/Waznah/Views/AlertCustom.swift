//
//  AlertCustom.swift
//  Waznah
//
//  Created by Anas Hamad on 1/15/24.
//

import Foundation
import SwiftUI


struct CustumAlertDone : View {
    
    var placeholedr :String
    @Binding var showAlert : Bool
    var body: some View{
        VStack{
            Image(systemName: "checkmark")
                .resizable()
                .frame(width: 80,height: 80)
               
            
            Text(placeholedr)
                .fontWeight(.bold)
        }
        .padding(.vertical,25)
        .padding(.horizontal,35)
        .background(BlurAlert())
        .cornerRadius(20)
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background(
            Color.primary.opacity(0.35)
                .onTapGesture {
                    withAnimation {
                        //Closing alert
                        showAlert.toggle()
                    }
                }
        )
    }
}
struct BlurAlert : UIViewRepresentable{
    
    func makeUIView(context: Context) -> some UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        
        return view
    }
    
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}
struct CustumAlertIsloading : View {
    
    var placeholedr :String
    @Binding var showAlert : Bool
    @State var animte = false
    var body: some View{
        VStack(spacing: 28 ){
            
            Circle()
                .stroke( AngularGradient(gradient: .init(colors: [Color.primary,Color.primary.opacity(0)]),center: .center))
                .frame(width: 80,height: 80)
                .rotationEffect(.init(degrees: animte ? 360 : 0 ))
            
            
            Text(placeholedr)
                .fontWeight(.bold)
               
        }
        .padding(.vertical,25)
        .padding(.horizontal,35)
       
        .background(BlurAlert())
        .cornerRadius(20)
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background(
            Color.primary.opacity(0.35)
                .onTapGesture {
                    withAnimation {
                        //Closing alert
                        showAlert.toggle()
                    }
                }
        )
        .onAppear{
            withAnimation (Animation.linear(duration: 1.5).repeatForever()) {
                
                    animte.toggle()
                
            }
        }
    }
}
