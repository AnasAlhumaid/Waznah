//
//  TapView.swift
//  Waznah
//
//  Created by Anas Hamad on 7/27/23.
//

import SwiftUI

struct TapViewHome: View {
    @StateObject private var firestoreManager = FirestoreManager()
    @State private var selected: Tab = .house

    var body: some View {
        ZStack {
            Group {
                selectedView
            }
            .background(Color.clear)
            .overlay(
                VStack {
                    Spacer()
                    CustomTabView(selectedTab: $selected)
                },
                alignment: .bottom
            )
            .ignoresSafeArea(.keyboard)
        }
        .waznahScreenBackdrop()
    }

    @ViewBuilder
    private var selectedView: some View {
        switch selected {
        case .house:
            Background()
        case .leaf:
            RecepeiScreen(cloudManager: firestoreManager)
        case .bag:
            RecepeiScreenApi(firestore: firestoreManager)
        }
    }
}

struct TapView_Previews: PreviewProvider {
    static var previews: some View {
        TapViewHome()
    }
}

enum Tab: String, CaseIterable {
    case house
    case leaf
    case bag

    var title: String {
        switch self {
        case .house: return "Brew".localized()
        case .leaf: return "My Recipes".localized()
        case .bag: return "Community".localized()
        }
    }
}

struct CustomTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTab: Tab

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
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
                        .foregroundColor(
                            selectedTab == tab
                                ? WaznahBrandColors.accent(for: colorScheme)
                                : (colorScheme == .dark ? Color.white.opacity(0.45) : .gray)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: WaznahTabBarLayout.barHeight)
            .background {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(hex: "#1A1216").opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color(hex: "#BF8A6E").opacity(0.18), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.thinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.12),
                radius: 12,
                x: 0,
                y: 6
            )
            .padding(.horizontal, WaznahTabBarLayout.horizontalPadding)
            .padding(.bottom, WaznahTabBarLayout.bottomPadding)
        }
    }
}
