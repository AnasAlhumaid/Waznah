//
//  CalculateScreen.swift
//  Waznah
//
//  Created by Anas Hamad on 10/4/22.
//

import SwiftUI

let size = UIScreen.main.bounds.size
struct CalculateScreen: View {
    @StateObject private var vm = CalcViewModel()
    private let presets: [RatioPreset] = [
        RatioPreset(name: "V60", ratio: 16.6),
        RatioPreset(name: "Chemex", ratio: 17.0),
        RatioPreset(name: "Espresso", ratio: 2.0),
        RatioPreset(name: "Cold Brew", ratio: 4.44),
        RatioPreset(name: "AeroPress", ratio: 6.0)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            
            Picker("", selection: $vm.mode) {
                ForEach(CalculationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.mode) { _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                vm.update()
            }
            
            HStack(spacing: 12) {
                CalculatorInputCard(
                    title: vm.mode.inputTitle,
                    value: $vm.value,
                    placeholder: vm.mode.inputPlaceholder,
                    icon: vm.mode.inputIcon
                )
                
                CalculatorInputCard(
                    title: "Ratio".localized(),
                    value: $vm.ratio,
                    placeholder: "15",
                    icon: "percent"
                )
            }
            
            resultCard
            presetSection
        }
        .padding(18)
        .frame(maxWidth: min(UIScreen.main.bounds.width - 36, 390))
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color(hex: "#86373E").opacity(0.12), radius: 18, x: 0, y: 10)
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Brew Calculator".localized())
                    .font(.title3.weight(.bold))
                Text("Calculate coffee or water by ratio.".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "scalemass.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Color(hex: "#86373E"))
                .clipShape(Circle())
        }
    }
    
    private var resultCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.mode.resultTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(vm.formattedResult)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Text(vm.mode.resultUnit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(hex: "#86373E"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("1:\(vm.cleanRatio)")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                Text("current ratio".localized())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "#F7EFE9"), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ratio Presets".localized())
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(presets) { preset in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vm.applyPreset(preset)
                    } label: {
                        HStack {
                            Text(preset.name.localized())
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            Text("1:\(preset.ratioText)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(vm.selectedPreset == preset.name ? Color(hex: "#86373E").opacity(0.14) : Color(.secondarySystemBackground))
                        .foregroundColor(vm.selectedPreset == preset.name ? Color(hex: "#86373E") : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }
}

struct CalculateScreen_Previews: PreviewProvider {
    static var previews: some View {
        CalculateScreen()
           
    }
}

enum CalculationMode: String, CaseIterable, Identifiable {
    case water
    case coffee
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .water:
            return "Need Water".localized()
        case .coffee:
            return "Need Coffee".localized()
        }
    }
    
    var inputTitle: String {
        switch self {
        case .water:
            return "Coffee".localized()
        case .coffee:
            return "Water".localized()
        }
    }
    
    var inputPlaceholder: String {
        switch self {
        case .water:
            return "18 g"
        case .coffee:
            return "270 ml"
        }
    }
    
    var inputIcon: String {
        switch self {
        case .water:
            return "circle.hexagongrid"
        case .coffee:
            return "drop.fill"
        }
    }
    
    var resultTitle: String {
        switch self {
        case .water:
            return "Water needed".localized()
        case .coffee:
            return "Coffee needed".localized()
        }
    }
    
    var resultUnit: String {
        switch self {
        case .water:
            return "ml water".localized()
        case .coffee:
            return "g coffee".localized()
        }
    }
}

struct RatioPreset: Identifiable {
    let name: String
    let ratio: Double
    
    var id: String { name }
    
    var ratioText: String {
        ratio.cleanString
    }
}

class CalcViewModel: ObservableObject {
    @Published var value = "" {
        didSet { update() }
    }
    @Published var ratio = "15" {
        didSet { update() }
    }
    @Published var mode: CalculationMode = .water
    @Published var result: Double = 0.0
    @Published var selectedPreset: String?
    
    var formattedResult: String {
        guard result.isFinite, result > 0 else { return "0" }
        return result.cleanString
    }
    
    var cleanRatio: String {
        parsedRatio.cleanString
    }
    
    func update() {
        let amount = parsed(value)
        let ratioValue = parsedRatio
        
        guard amount > 0, ratioValue > 0 else {
            result = 0
            return
        }
        
        switch mode {
        case .water:
            result = amount * ratioValue
        case .coffee:
            result = amount / ratioValue
        }
    }
    
    func applyPreset(_ preset: RatioPreset) {
        selectedPreset = preset.name
        ratio = preset.ratio.cleanString
        update()
    }
    
    private var parsedRatio: Double {
        max(parsed(ratio), 1)
    }
    
    private func parsed(_ text: String) -> Double {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        return Double(normalized) ?? 0
    }
}

struct CalculatorInputCard: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $value)
                .keyboardType(.decimalPad)
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(.secondarySystemBackground).opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Double {
    var cleanString: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        }
        return String(format: "%.1f", self)
    }
}

struct CoffeeRecipe {
    var coffeeRatio: Double // e.g., 1:15
    var waterAmountInGrams: Double // grams
    var coffeeAmountInGrams: Double // grams
}

struct Glassmorphism: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Create a blur effect
                    Color.clear
                        .blur(radius: 10)
                        .opacity(0.9)
                    
                    // Add a transparent background color
                    Color.white.opacity(0.2)
                }
            )
    }
}

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }
}
extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
