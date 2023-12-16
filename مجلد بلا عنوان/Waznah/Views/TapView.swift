//
//  TapView.swift
//  Waznah
//
//  Created by Anas Hamad on 7/27/23.
//

import SwiftUI

struct TapViewHome: View {
    
    @State private var selected : Tab = .house
    
    var body: some View{
        ZStack{
          
            TabView{
                switch selected {
                case .house:
                    Background()
                case .leaf:
                    RecepeiScreen()
                }
            }
            .overlay (
                VStack{
                    Spacer()
                    CustomTabView(selectedTab: $selected)
                }
                ,alignment:.bottom
            )
            .ignoresSafeArea(.keyboard)
       
    }
    }

}

struct TapView_Previews: PreviewProvider {
    static var previews: some View {
        TapViewHome()
    }
}


enum Tab : String,CaseIterable{
    case house
    case leaf
    
}

struct CustomTabView : View{
    @Binding var selectedTab: Tab
    private var fillimage : String{
        selectedTab.rawValue + ".fill"
    }
    var body: some View {
        VStack{
            HStack{
                
                ForEach(Tab.allCases, id: \.rawValue){ tab in
                    Spacer()
                    Image(systemName: selectedTab == tab ? fillimage : tab.rawValue)
                        .scaleEffect(selectedTab == tab ? 1.25 : 1.0)
                        .foregroundColor(selectedTab == tab ? Color(hex: "#86373E") : .gray)
                        .font(.system(size: 22))
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 0.1)) {
                                selectedTab = tab
                            }
                                
                            
                        }
                    Spacer()
                    
                    
                }
                
            }
            .frame(width: nil,height: 60)
            .background(.thinMaterial)
            .cornerRadius(10)
            .padding()
        }
    }
}
