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
            Group {
                selectedView
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
    
    @ViewBuilder
    private var selectedView: some View {
        switch selected {
        case .house:
            Background()
        case .leaf:
            RecepeiScreen()
        case .bag:
            RecepeiScreenApi( vm: FirestoreManager())
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
    case bag
    
    var title: String {
        switch self {
        case .house:
            return "Brew".localized()
        case .leaf:
            return "My Recipes".localized()
        case .bag:
            return "Community".localized()
        }
    }
    
}

struct CustomTabView : View{
    @Binding var selectedTab: Tab
    private var fillimage : String{
        selectedTab.rawValue + ".fill"
    }
    var body: some View {
        VStack{
            HStack(spacing: 0){
                
                ForEach(Tab.allCases, id: \.rawValue){ tab in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == tab ? tab.rawValue + ".fill" : tab.rawValue)
                                .font(.system(size: 22, weight: .semibold))
                            
                            Text(tab.title)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(selectedTab == tab ? Color(hex: "#86373E") : .gray)
                    }
                    .buttonStyle(.plain)
                }
                
            }
            .frame(height: 68)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
