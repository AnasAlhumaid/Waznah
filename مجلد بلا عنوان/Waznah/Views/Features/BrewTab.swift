//
//  BrewTab.swift
//  Waznah — Brew tab: View + ViewModel + subviews
//

import SwiftUI

// MARK: - ViewModels

@MainActor
final class BrewTabViewModel: ObservableObject {
    @Published var showInfoOverlay = false
}

@MainActor
final class BrewTimerViewModel: ObservableObject {
    @Published var selectedTime = 150
    @Published var elapsedTime = 0
    @Published var isRunning = false {
        didSet {
            guard isRunning != oldValue else { return }
            runAnchor = isRunning ? Date().addingTimeInterval(-Double(elapsedTime)) : nil
            syncBackgroundSurfaces()
        }
    }
    @Published private(set) var didFinish = false
    @Published var showPicker = false

    /// Wall-clock start so the timer stays accurate when the app is backgrounded or the screen locks.
    private var runAnchor: Date?

    var progress: CGFloat {
        guard selectedTime > 0 else { return 0 }
        return min(CGFloat(elapsedTime) / CGFloat(selectedTime), 1)
    }

    var remainingTime: Int { max(selectedTime - elapsedTime, 0) }

    func toggleTimer() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if elapsedTime >= selectedTime { elapsedTime = 0 }
        didFinish = false
        isRunning.toggle()
    }

    func resetTimer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isRunning = false
        elapsedTime = 0
        didFinish = false
        endBackgroundSurfaces()
    }

    func selectQuickTimer(_ seconds: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedTime = seconds
        elapsedTime = 0
        didFinish = false
        isRunning = false
        endBackgroundSurfaces()
    }

    func tick() {
        guard isRunning, let runAnchor else { return }
        elapsedTime = min(Int(Date().timeIntervalSince(runAnchor)), selectedTime)
        if elapsedTime >= selectedTime {
            isRunning = false
            didFinish = true
            endBackgroundSurfaces()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Keeps the Lock Screen Live Activity and the "done" notification in step with the timer.
    private func syncBackgroundSurfaces() {
        guard elapsedTime < selectedTime else { return }
        if isRunning {
            BrewTimerNotifier.schedule(after: remainingTime, title: "Brew Timer".localized())
        } else {
            BrewTimerNotifier.cancel()
        }
        BrewLiveActivityController.shared.startOrUpdate(.init(
            title: "Brew Timer".localized(),
            method: "Waznah".localized(),
            remainingSeconds: remainingTime,
            totalSeconds: selectedTime,
            isRunning: isRunning,
            headline: isRunning ? "Brewing…".localized() : "Paused".localized(),
            detail: String(format: "of %@".localized(), timeFormatted(selectedTime))
        ))
    }

    private func endBackgroundSurfaces() {
        BrewTimerNotifier.cancel()
        BrewLiveActivityController.shared.end()
    }

    func timeFormatted(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

// MARK: - Brew Tab

struct Background: View {
    @StateObject private var tabVM = BrewTabViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    CalculateScreen()
                    BrewTimerView()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, WaznahTabBarLayout.contentClearance)
            }
            .scrollContentBackground(.hidden)
            .waznahScreenBackdrop()
            .navigationTitle("Waznah".localized())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { withAnimation { tabVM.showInfoOverlay.toggle() } } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .waznahAmbientNavigation()
        .overlay {
            if tabVM.showInfoOverlay {
                BrewInfoOverlay {
                    withAnimation(.easeOut(duration: 0.25)) {
                        tabVM.showInfoOverlay = false
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.25), value: tabVM.showInfoOverlay)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Brew Info Overlay

private struct BrewInfoOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var cloudManager = FirestoreManager()

    @State private var showDeleteAccountConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showDeleteAccountSuccess = false
    @State private var accountErrorMessage = ""
    @State private var showAccountError = false

    let onClose: () -> Void

    private let developerEmail = AppUpdateManager.supportEmail
    private let developerPhone = "966555163630"

    private var coffeeTips: [String] {
        [
            "Start with fresh beans and grind right before you brew.".localized(),
            "Use clean water at the right temperature for your method.".localized(),
            "Weigh your coffee and water — a steady ratio keeps every cup balanced.".localized(),
            "Pour with care, then slow down and enjoy the moment.".localized()
        ]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(colorScheme == .dark ? 0.45 : 0.32)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(alignment: .leading, spacing: 18) {
                headerRow

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        tipsSection
                        communitySection
                        legalSection
                        developerSection
                        accountSection
                    }
                }
                .frame(maxHeight: 420)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: -4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, WaznahTabBarLayout.contentClearance + 8)
        }
        .alert("Delete account?".localized(), isPresented: $showDeleteAccountConfirmation) {
            Button("Delete Account".localized(), role: .destructive) {
                deleteAccount()
            }
            Button("Cancel".localized(), role: .cancel) { }
        } message: {
            Text("This permanently deletes your cloud account, shared Community recipes, and synced data. Local recipes stay on this device but are unlinked from Community.".localized())
        }
        .alert("Account deleted".localized(), isPresented: $showDeleteAccountSuccess) {
            Button("OK".localized(), role: .cancel) {
                onClose()
            }
        } message: {
            Text("Your cloud account and shared data were removed.".localized())
        }
        .alert("Account action failed".localized(), isPresented: $showAccountError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(accountErrorMessage)
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("A Good Cup of Coffee".localized())
                    .font(.title2.weight(.bold))
                Text("Small habits that make every brew better.".localized())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 12)
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(coffeeTips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.caption.weight(.bold))
                        .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                        .padding(.top, 3)
                    Text(tip)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Community Guidelines".localized())
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text("Share coffee recipes only. Do not post offensive, misleading, or unrelated content. Report recipes that violate these guidelines.".localized())
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Legal".localized())
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if let privacyURL = URL(string: AppUpdateManager.privacyPolicyURLString) {
                Link(destination: privacyURL) {
                    Label("Privacy Policy".localized(), systemImage: "hand.raised.fill")
                        .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().opacity(0.35)

            Text("Developer".localized())
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Link(destination: URL(string: "mailto:\(developerEmail)")!) {
                Label(developerEmail, systemImage: "envelope.fill")
                    .font(.subheadline.weight(.medium))
            }

            Link(destination: URL(string: "tel:+\(developerPhone)")!) {
                Label("+\(developerPhone)", systemImage: "phone.fill")
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().opacity(0.35)

            Text("Account".localized())
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Button {
                showDeleteAccountConfirmation = true
            } label: {
                HStack {
                    if isDeletingAccount {
                        ProgressView()
                    } else {
                        Image(systemName: "person.crop.circle.badge.minus")
                    }
                    Text("Delete Account".localized())
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(Color(hex: "#86373E"))
            }
            .disabled(isDeletingAccount)

            Text("Removes your cloud account on our servers and all shared Community data.".localized())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func deleteAccount() {
        isDeletingAccount = true
        cloudManager.deleteCurrentUserAccount { error in
            isDeletingAccount = false

            if let error {
                accountErrorMessage = error.waznahUserFacingMessage
                showAccountError = true
                return
            }

            LocalRecipeSyncManager.shared.detachAllCloudLinks(in: viewContext)
            showDeleteAccountSuccess = true
        }
    }
}

// MARK: - Calculator

let size = UIScreen.main.bounds.size
struct CalculateScreen: View {
    @StateObject private var vm = CalcViewModel()
    @Environment(\.colorScheme) private var colorScheme
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
            .tint(WaznahBrandColors.accent(for: colorScheme))
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
        .waznahGlassCard(cornerRadius: 28)
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
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
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
        .background(WaznahAccentPanelBackground(cornerRadius: 20))
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
                        .background {
                            if vm.selectedPreset == preset.name {
                                WaznahBrandColors.accent(for: colorScheme).opacity(0.14)
                            } else {
                                WaznahChipSurfaceBackground()
                            }
                        }
                        .foregroundColor(
                            vm.selectedPreset == preset.name
                                ? WaznahBrandColors.accent(for: colorScheme)
                                : .primary
                        )
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
    // Plain @Published inputs: changing a *second* published value from their didSet while the
    // TextField is mid-edit made the field drop/hide typed characters. `result` is now derived.
    @Published var value = ""
    @Published var ratio = "15"
    @Published var mode: CalculationMode = .water
    @Published var selectedPreset: String?

    var result: Double {
        let amount = parsed(value)
        let ratioValue = parsedRatio
        guard amount > 0, ratioValue > 0 else { return 0 }
        switch mode {
        case .water: return amount * ratioValue
        case .coffee: return amount / ratioValue
        }
    }
    
    var formattedResult: String {
        guard result.isFinite, result > 0 else { return "0" }
        return result.cleanString
    }
    
    var cleanRatio: String {
        parsedRatio.cleanString
    }
    
    /// Kept for call sites; the result is computed on read, so nothing to store.
    func update() {}
    
    func applyPreset(_ preset: RatioPreset) {
        selectedPreset = preset.name
        ratio = preset.ratio.cleanString
        update()
    }
    
    private var parsedRatio: Double {
        max(parsed(ratio), 1)
    }
    
    private func parsed(_ text: String) -> Double {
        let normalized = text.westernDigits
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
            
            // UIKit-backed: the SwiftUI TextField intermittently showed the placeholder over typed digits.
            WaznahNumericTextField(text: $value, placeholder: placeholder)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(WaznahInsetSurfaceBackground())
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
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

// MARK: - Timer

struct BrewTimerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm = BrewTimerViewModel()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brew Timer".localized()).font(.title3.weight(.bold)).lineLimit(1)
                    Text(vm.didFinish ? "Brew is ready ☕️".localized() : vm.isRunning ? "Timer is running".localized() : "Ready when you are".localized())
                        .font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    vm.showPicker = true
                } label: {
                    Label("Set".localized(), systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(WaznahCapsuleBadgeBackground())
                        .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                        .clipShape(Capsule())
                }
            }

            ZStack {
                Circle()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color(.secondarySystemBackground), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(
                        LinearGradient(colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut(duration: 0.25), value: vm.progress)
                VStack(spacing: 6) {
                    Text(vm.timeFormatted(vm.remainingTime))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(String(format: "of %@".localized(), vm.timeFormatted(vm.selectedTime)))
                        .font(.caption).foregroundColor(.secondary)
                    if vm.elapsedTime > 0 {
                        Text("\(Int(vm.progress * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                    }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(width: 190, height: 190)
            .padding(.vertical, 4)

            HStack(spacing: 12) {
                Button { vm.toggleTimer() } label: {
                    Label(
                        vm.isRunning ? "Pause".localized() : (vm.elapsedTime > 0 && !vm.didFinish ? "Resume".localized() : "Start".localized()),
                        systemImage: vm.isRunning ? "pause.fill" : "play.fill"
                    )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#86373E"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Button { vm.resetTimer() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(width: 54, height: 50)
                        .background(WaznahChipSurfaceBackground())
                        .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(vm.elapsedTime == 0 && !vm.isRunning)
                .opacity(vm.elapsedTime == 0 && !vm.isRunning ? 0.45 : 1)
            }

            quickTimers
        }
        .padding(18)
        .frame(maxWidth: min(UIScreen.main.bounds.width - 36, 390))
        .waznahGlassCard(cornerRadius: 28)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .onReceive(ticker) { _ in vm.tick() }
        .onChange(of: vm.isRunning) { running in
            UIApplication.shared.isIdleTimerDisabled = running
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .sheet(isPresented: $vm.showPicker) {
            TimerPickerSheet(selectedTime: $vm.selectedTime, elapsedTime: $vm.elapsedTime, isRunning: $vm.isRunning)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var quickTimers: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach([60, 150], id: \.self) { seconds in quickTimerButton(seconds) }
            }
            HStack(spacing: 8) {
                ForEach([240, 300], id: \.self) { seconds in quickTimerButton(seconds) }
            }
        }
    }

    private func quickTimerButton(_ seconds: Int) -> some View {
        Button { vm.selectQuickTimer(seconds) } label: {
            Text(vm.timeFormatted(seconds))
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    if vm.selectedTime == seconds {
                        WaznahBrandColors.accent(for: colorScheme).opacity(0.14)
                    } else {
                        WaznahChipSurfaceBackground()
                    }
                }
                .foregroundColor(vm.selectedTime == seconds ? WaznahBrandColors.accent(for: colorScheme) : .secondary)
                .clipShape(Capsule())
        }
    }
}

struct TimerPickerSheet: View {
    @Binding var selectedTime: Int
    @Binding var elapsedTime: Int
    @Binding var isRunning: Bool

    var body: some View {
        VStack(spacing: 18) {
            Text("Select Timer".localized()).font(.title3.weight(.bold))
            Picker("Set Time".localized(), selection: $selectedTime) {
                ForEach(Array(stride(from: 30, through: 3600, by: 30)), id: \.self) { timeInSeconds in
                    Text(timeFormatted(timeInSeconds)).tag(timeInSeconds)
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            Text("Changing time resets the current timer.".localized())
                .font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(24)
        .onChange(of: selectedTime) { _ in
            elapsedTime = 0
            isRunning = false
            BrewTimerNotifier.cancel()
            BrewLiveActivityController.shared.end()
        }
    }

    private func timeFormatted(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
