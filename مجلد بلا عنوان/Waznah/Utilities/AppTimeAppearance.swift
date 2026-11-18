//
//  AppTimeAppearance.swift
//  Waznah
//

import SwiftUI
import UIKit

func getCurrentTime() -> Date {
    return Date()
}

// MARK: - Time-based appearance (6 AM day / 6 PM evening)

enum WaznahAppearanceOverride: String {
    case auto
    case light
    case dark

    static var current: WaznahAppearanceOverride {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-WaznahAppearance"), index + 1 < args.count else {
            return .auto
        }
        return WaznahAppearanceOverride(rawValue: args[index + 1].lowercased()) ?? .auto
    }

    static var isForced: Bool { current != .auto }
}

enum WaznahTimeScheme {
    static let dayStartHour = 6
    static let eveningStartHour = 18

    enum Period: Equatable {
        case day
        case evening
    }

    static func period(at date: Date = getCurrentTime()) -> Period {
        isDaytime(at: date) ? .day : .evening
    }

    /// Date used for sun/moon and color scheme (respects `-WaznahAppearance` launch args).
    static func effectiveDate(at date: Date = getCurrentTime()) -> Date {
        switch WaznahAppearanceOverride.current {
        case .auto:
            return date
        case .light:
            return sampleDaytimeDate(relativeTo: date)
        case .dark:
            return sampleEveningDate(relativeTo: date)
        }
    }

    /// Light scheme from 6 AM until 6 PM; evening scheme from 6 PM until 6 AM.
    static func isDaytime(at date: Date = getCurrentTime()) -> Bool {
        switch WaznahAppearanceOverride.current {
        case .light:
            return true
        case .dark:
            return false
        case .auto:
            break
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard
            let sixAM = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: startOfDay),
            let sixPM = calendar.date(bySettingHour: eveningStartHour, minute: 0, second: 0, of: startOfDay)
        else {
            return true
        }
        return date >= sixAM && date < sixPM
    }

    static func colorScheme(at date: Date = getCurrentTime()) -> ColorScheme {
        isDaytime(at: date) ? .light : .dark
    }

    static func nextBoundary(from date: Date = getCurrentTime()) -> Date {
        guard WaznahAppearanceOverride.current == .auto else {
            return .distantFuture
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard
            let sixAM = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: startOfDay),
            let sixPM = calendar.date(bySettingHour: eveningStartHour, minute: 0, second: 0, of: startOfDay)
        else {
            return date.addingTimeInterval(3600)
        }

        if date < sixAM { return sixAM }
        if date < sixPM { return sixPM }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: tomorrow) ?? date.addingTimeInterval(3600)
    }

    private static func sampleDaytimeDate(relativeTo date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startOfDay) ?? date
    }

    private static func sampleEveningDate(relativeTo date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: startOfDay) ?? date
    }
}

private struct WaznahSchemeDateKey: EnvironmentKey {
    static let defaultValue = Date()
}

extension EnvironmentValues {
    var waznahSchemeDate: Date {
        get { self[WaznahSchemeDateKey.self] }
        set { self[WaznahSchemeDateKey.self] = newValue }
    }
}

private struct WaznahTimeBasedColorSchemeModifier: ViewModifier {
    @State private var now = Date()
    @State private var boundaryTimer: Timer?

    func body(content: Content) -> some View {
        let schemeDate = WaznahTimeScheme.effectiveDate(at: now)

        content
            .environment(\.waznahSchemeDate, schemeDate)
            .preferredColorScheme(WaznahTimeScheme.colorScheme(at: now))
            .onAppear(perform: scheduleNextBoundary)
            .onDisappear {
                boundaryTimer?.invalidate()
                boundaryTimer = nil
            }
            .onChange(of: now) { _ in
                scheduleNextBoundary()
            }
    }

    private func scheduleNextBoundary() {
        guard WaznahAppearanceOverride.current == .auto else { return }

        boundaryTimer?.invalidate()
        let interval = max(WaznahTimeScheme.nextBoundary(from: now).timeIntervalSinceNow, 1)
        boundaryTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            now = Date()
        }
    }
}

extension View {
    /// Applies light mode (6 AM–6 PM) or dark evening mode (6 PM–6 AM), switching at each boundary.
    func waznahTimeBasedColorScheme() -> some View {
        modifier(WaznahTimeBasedColorSchemeModifier())
    }

    /// Transparent navigation bar so the dark starfield shows through.
    func waznahAmbientNavigation() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
            .background(NavigationClearBackgroundRepresentable())
    }

    /// Paints the ambient backdrop behind content without affecting layout width.
    func waznahScreenBackdrop() -> some View {
        background {
            WaznahAmbientScreenBackdrop()
        }
    }

    /// Done button above the keyboard for decimal/number pads (no Return key).
    func waznahKeyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done".localized()) {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Numeric text field (decimalPad / numberPad)

/// UIKit-backed field so placeholder and typed text use correct colors in light mode and RTL (Arabic).
/// SwiftUI `TextField` + `.decimalPad` can still draw a white UIKit placeholder over a custom overlay.
struct WaznahNumericTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .decimalPad

    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.keyboardType = keyboardType
        field.font = .systemFont(ofSize: 17, weight: .semibold)
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.textAlignment = .natural
        field.text = text
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        applyAppearance(to: field)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            uiView.text = text
        }
        applyAppearance(to: uiView)
    }

    private func applyAppearance(to field: UITextField) {
        field.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        field.textColor = .label
        field.tintColor = UIColor(WaznahBrandColors.accent(for: colorScheme))
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: WaznahNumericTextField

        init(parent: WaznahNumericTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}

private struct NavigationClearBackgroundRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            Self.clearAncestors(startingAt: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            Self.clearAncestors(startingAt: uiView)
        }
    }

    private static func clearAncestors(startingAt view: UIView) {
        var current: UIView? = view
        for _ in 0..<16 {
            guard let layer = current else { break }
            layer.backgroundColor = .clear
            if let nav = layer as? UINavigationBar {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                nav.standardAppearance = appearance
                nav.scrollEdgeAppearance = appearance
                nav.compactAppearance = appearance
            }
            if let scrollView = layer as? UIScrollView {
                scrollView.backgroundColor = .clear
            }
            current = layer.superview
        }

        var responder: UIResponder? = view
        while let next = responder {
            if let navController = next as? UINavigationController {
                navController.view.backgroundColor = .clear
                navController.viewControllers.forEach { $0.view.backgroundColor = .clear }
                break
            }
            responder = next.next
        }
    }
}

// MARK: - Dark starfield backdrop

/// Flickering starlight — shared across all screens in dark mode.
struct WaznahNightStarfieldBackground: View {
    var body: some View {
        let starlight = WaznahNightStarfieldBackground.makeStarlight()

        GeometryReader { geo in
            TimelineView(.periodic(from: .distantPast, by: 0.1)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    ForEach(Array(starlight.enumerated()), id: \.offset) { index, star in
                        let speed = 1.1 + Double(index % 9) * 0.18
                        let phase = Double(index) * 0.93
                        let wave = 0.5 + 0.5 * sin(time * speed + phase)
                        let flicker = 0.22 + 0.78 * wave

                        Circle()
                            .fill(Color.white)
                            .frame(width: star.size, height: star.size)
                            .opacity(star.opacity * flicker)
                            .position(
                                x: geo.size.width * star.x,
                                y: geo.size.height * star.y
                            )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
    }

    static func makeStarlight() -> [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] {
        let sizes: [CGFloat] = [1.2, 1.4, 1.6, 1.8, 2.0, 2.4, 2.8, 3.2]
        var stars: [(CGFloat, CGFloat, CGFloat, Double)] = []

        for row in 0..<18 {
            for col in 0..<10 {
                let seed = row * 1000 + col * 37 + 911
                let jitterX = CGFloat((seed % 21) - 10) / 280
                let jitterY = CGFloat((seed % 19) - 9) / 260
                let x = min(max((CGFloat(col) + 0.5) / 10 + jitterX, 0.02), 0.98)
                let y = min(max((CGFloat(row) + 0.5) / 18 + jitterY, 0.02), 0.98)
                let size = sizes[(seed / 17) % sizes.count]
                let opacity = 0.22 + Double((seed / 11) % 68) / 100
                stars.append((x, y, size, opacity))
            }
        }

        for i in 0..<60 {
            let seed = i * 7919 + 104729
            let x = CGFloat((seed % 971) + 12) / 995
            let y = CGFloat((seed % 983) + 8) / 999
            let size = sizes[(seed / 23) % sizes.count]
            let opacity = 0.18 + Double((seed / 7) % 72) / 100
            stars.append((x, y, size, opacity))
        }

        return stars
    }
}

/// Full-screen backdrop — starfield in dark mode, clear in light (Brew keeps its own sun).
struct WaznahDarkScreenBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                ZStack {
                    Color(hex: "#0C090B")
                    WaznahNightStarfieldBackground()
                }
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
    }
}

/// Warm sun gradient — shared across all screens in light mode.
struct WaznahSunBackground: View {
    var body: some View {
        GeometryReader { geo in
            Ellipse()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(#colorLiteral(red: 1, green: 0.5783333778381348, blue: 0.5208333730697632, alpha: 1)), location: 0),
                            .init(color: Color(#colorLiteral(red: 1, green: 0.7508333921432495, blue: 0.5208333730697632, alpha: 0.4300000071525574)), location: 1)
                        ]),
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                )
                .frame(width: geo.size.width * 1.35, height: geo.size.width * 0.95)
                .position(x: geo.size.width * 0.5, y: geo.size.width * 0.32)
        }
    }
}

/// Sun + blur — daytime look used app-wide in light mode.
struct WaznahDayAmbientBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                WaznahSunBackground()
                Blur(radius: 20, opaque: true)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
    }
}

/// Full-screen backdrop — sun + blur in light mode, starfield in dark mode.
struct WaznahAmbientScreenBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            Group {
                if colorScheme == .dark {
                    ZStack {
                        Color(hex: "#0C090B")
                        WaznahNightStarfieldBackground()
                    }
                } else {
                    WaznahDayAmbientBackground()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Dark-mode card surfaces

enum WaznahBrandColors {
    static let accent = Color(hex: "#86373E")
    static let accentSoft = Color(hex: "#BF8A6E")

    static func accent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? accentSoft : accent
    }
}

/// Highlight panel — e.g. calculator result card.
struct WaznahAccentPanelBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : 0)
            )
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "#86373E").opacity(0.32),
                Color(hex: "#2A1C21"),
                Color(hex: "#151015")
            ]
        }
        return [Color(hex: "#F7EFE9"), Color(.secondarySystemBackground)]
    }

    private var borderColor: Color {
        Color(hex: "#BF8A6E").opacity(0.28)
    }
}

/// Nested field / metric chip inside a card.
struct WaznahInsetSurfaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                Color.white.opacity(0.08)
            } else {
                Color(.secondarySystemBackground).opacity(0.85)
            }
        }
    }
}

/// Unselected preset / quick-action chip.
struct WaznahChipSurfaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                Color.white.opacity(0.07)
            } else {
                Color(.secondarySystemBackground)
            }
        }
    }
}

/// Recipe list card background.
struct WaznahRecipeCardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.35) : Color(hex: "#86373E").opacity(0.12),
                radius: 18,
                x: 0,
                y: 10
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "#86373E").opacity(0.18),
                Color(hex: "#1A1216"),
                Color(hex: "#120D10")
            ]
        }
        return [Color(.systemBackground), Color(hex: "#F7EFE9").opacity(0.55)]
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color(hex: "#BF8A6E").opacity(0.22)
            : Color.white.opacity(0.65)
    }
}

/// Brew-method thumbnail tile on recipe cards.
struct WaznahRecipeThumbnailBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : 0)
            )
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "#86373E").opacity(0.35),
                Color(hex: "#24181C")
            ]
        }
        return [Color(hex: "#F7EFE9"), Color(hex: "#EAD8CF")]
    }

    private var borderColor: Color {
        Color(hex: "#BF8A6E").opacity(0.3)
    }
}

/// Main floating card — calculator, timer, form sections.
struct WaznahGlassCardBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 28

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : 0)
            )
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "#86373E").opacity(0.16),
                Color(hex: "#1E1519").opacity(0.94),
                Color(hex: "#110C0F").opacity(0.98)
            ]
        }
        return [Color.white.opacity(0.72), Color.white.opacity(0.42)]
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.4)
            : Color(hex: "#86373E").opacity(0.12)
    }

    private var borderColor: Color {
        Color(hex: "#BF8A6E").opacity(0.24)
    }
}

/// Full-screen sheet / form backdrop.
struct WaznahScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                ZStack {
                    Color(hex: "#0C090B")
                    WaznahNightStarfieldBackground()
                }
            } else {
                LinearGradient(
                    colors: [Color(hex: "#FBF7F4"), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

/// Small capsule actions — e.g. timer “Set”.
struct WaznahCapsuleBadgeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                WaznahBrandColors.accentSoft.opacity(0.18)
            } else {
                WaznahBrandColors.accent.opacity(0.12)
            }
        }
    }
}

/// Hero circle behind brew-method artwork.
struct WaznahHeroCircleBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Circle()
            .fill(
                WaznahBrandColors.accent(for: colorScheme)
                    .opacity(colorScheme == .dark ? 0.22 : 0.08)
            )
    }
}

private struct WaznahGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            if colorScheme == .dark {
                WaznahGlassCardBackground(cornerRadius: cornerRadius)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color(hex: "#86373E").opacity(0.12), radius: 18, x: 0, y: 10)
            }
        }
    }
}

extension View {
    func waznahGlassCard(cornerRadius: CGFloat = 28) -> some View {
        modifier(WaznahGlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Tab bar layout

enum WaznahTabBarLayout {
    static let barHeight: CGFloat = 68
    static let bottomPadding: CGFloat = 8
    static let horizontalPadding: CGFloat = 16
    /// Bottom space so the last list/card row stays above the tab bar.
    static let contentClearance: CGFloat = barHeight + bottomPadding + 28
}

/// Invisible list row — keeps scroll content above the floating tab bar.
struct WaznahTabBarListSpacer: View {
    var body: some View {
        Color.clear
            .frame(height: WaznahTabBarLayout.contentClearance)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .accessibilityHidden(true)
    }
}

/// Perfect circle icon button (share / close).
struct WaznahCircleIconButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let systemName: String
    var diameter: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color(.secondarySystemBackground)
                    )
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Circle()
                            .stroke(
                                colorScheme == .dark
                                    ? Color(hex: "#BF8A6E").opacity(0.22)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )

                Image(systemName: systemName)
                    .font(.system(size: diameter * 0.34, weight: .bold))
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
            }
            .frame(width: diameter, height: diameter)
            .fixedSize()
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
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
        NSLocalizedString(self, comment: comment)
    }
}
