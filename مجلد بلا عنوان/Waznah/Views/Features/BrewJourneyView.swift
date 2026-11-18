//
//  BrewJourneyView.swift
//  Waznah — One-screen brew guide with one total timer, pause/resume, auto step targets
//

import SwiftUI

@MainActor
final class BrewJourneyViewModel: ObservableObject {
    let recipe: BrewJourneyRecipe

    @Published private(set) var currentStepIndex = 0
    @Published private(set) var elapsedTime = 0
    @Published private(set) var isRunning = false {
        didSet {
            runAnchor = isRunning ? Date().addingTimeInterval(-Double(elapsedTime)) : nil
            UIApplication.shared.isIdleTimerDisabled = isRunning
            if isRunning != oldValue { syncBackgroundSurfaces() }
        }
    }
    @Published private(set) var isComplete = false
    @Published private(set) var hasStarted = false

    /// Wall-clock start so the journey stays accurate when the app is backgrounded or the screen locks.
    private var runAnchor: Date?

    init(recipe: BrewJourneyRecipe) {
        self.recipe = recipe
    }

    var steps: [BrewJourneyStep] { recipe.steps }

    var currentStep: BrewJourneyStep? {
        steps[safe: currentStepIndex]
    }

    var totalDuration: Int {
        recipe.totalDurationSeconds
    }

    var hasTotalTimer: Bool {
        totalDuration > 0
    }

    var timerProgress: CGFloat {
        guard hasTotalTimer else { return 0 }
        return min(CGFloat(elapsedTime) / CGFloat(totalDuration), 1)
    }

    var journeyProgress: CGFloat {
        guard !steps.isEmpty else { return 0 }
        if isComplete { return 1 }
        if hasTotalTimer {
            return timerProgress
        }
        return CGFloat(currentStepIndex + 1) / CGFloat(steps.count)
    }

    var isLastStep: Bool {
        currentStepIndex >= steps.count - 1
    }

    var nextStep: BrewJourneyStep? {
        steps[safe: currentStepIndex + 1]
    }

    /// Share of the recipe's total water poured once the current step is done.
    var waterFillFraction: CGFloat {
        guard recipe.totalWaterML > 0 else { return 0 }
        if isComplete { return 1 }
        guard hasStarted, let currentStep else { return 0 }
        return CGFloat(currentStep.targetTotalML / recipe.totalWaterML)
    }

    /// Seconds left in the current step (timed recipes only).
    var stepRemaining: Int? {
        guard hasTotalTimer, let end = recipe.stepEndElapsedSeconds[safe: currentStepIndex] else { return nil }
        return max(end - elapsedTime, 0)
    }

    /// Skip ahead to the next step, or finish on the last one.
    func advanceStep() {
        guard hasStarted, !isComplete else { return }
        if isLastStep {
            completeJourney()
            return
        }
        if hasTotalTimer, let end = recipe.stepEndElapsedSeconds[safe: currentStepIndex] {
            elapsedTime = end
            if isRunning { runAnchor = Date().addingTimeInterval(-Double(elapsedTime)) }
            syncStepToElapsedTime()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentStepIndex += 1
            }
        }
    }

    func restart() {
        endBackgroundSurfaces()
        isRunning = false
        elapsedTime = 0
        currentStepIndex = 0
        isComplete = false
        hasStarted = false
        lastCountdownSecond = nil
    }

    private var lastCountdownSecond: Int?

    func startJourney() {
        guard !hasStarted, !steps.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        hasStarted = true
        isRunning = true
    }

    func togglePauseResume() {
        guard hasStarted, !isComplete else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isRunning.toggle()
    }

    func tick() {
        guard hasStarted, isRunning, !isComplete, let runAnchor else { return }

        elapsedTime = Int(Date().timeIntervalSince(runAnchor))
        countdownHapticIfNeeded()
        syncStepToElapsedTime()

        if hasTotalTimer, elapsedTime >= totalDuration {
            completeJourney()
        }
    }

    func timeFormatted(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    /// Light taps on the last 3 seconds of a step so the next pour can be anticipated without looking.
    private func countdownHapticIfNeeded() {
        guard let remaining = stepRemaining, (1...3).contains(remaining), remaining != lastCountdownSecond else { return }
        lastCountdownSecond = remaining
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    private func syncStepToElapsedTime() {
        guard hasTotalTimer else { return }
        let ends = recipe.stepEndElapsedSeconds
        guard !ends.isEmpty else { return }

        var newIndex = currentStepIndex
        while newIndex < ends.count - 1, elapsedTime >= ends[newIndex] {
            newIndex += 1
        }

        guard newIndex != currentStepIndex else { return }
        defer { syncBackgroundSurfaces() }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStepIndex = newIndex
        }
    }

    /// Mirrors the journey on the Lock Screen / Dynamic Island and schedules the "done" alert.
    func syncBackgroundSurfaces() {
        guard hasStarted, !isComplete, hasTotalTimer, let step = currentStep else {
            endBackgroundSurfaces()
            return
        }
        let remaining = max(totalDuration - elapsedTime, 0)
        if isRunning {
            BrewTimerNotifier.schedule(after: remaining, title: recipe.title)
        } else {
            BrewTimerNotifier.cancel()
        }
        BrewLiveActivityController.shared.startOrUpdate(.init(
            title: recipe.title,
            method: recipe.method,
            remainingSeconds: remaining,
            totalSeconds: totalDuration,
            isRunning: isRunning,
            headline: String(format: "Pour to %@ ml".localized(), BrewJourneyBuilder.formatVolume(step.targetTotalML)),
            detail: String(format: "Step %d of %d".localized(), currentStepIndex + 1, steps.count)
        ))
    }

    func endBackgroundSurfaces() {
        BrewTimerNotifier.cancel()
        BrewLiveActivityController.shared.end()
    }

    private func completeJourney() {
        isRunning = false
        endBackgroundSurfaces()
        currentStepIndex = max(steps.count - 1, 0)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            isComplete = true
        }
    }
}

struct BrewJourneyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm: BrewJourneyViewModel
    @State private var showExitConfirmation = false
    @State private var ringPulse = false
    @State private var selectedTaste: BrewTaste?

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(recipe: BrewJourneyRecipe) {
        _vm = StateObject(wrappedValue: BrewJourneyViewModel(recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WaznahScreenBackground()

                if vm.isComplete {
                    completionView
                } else if let step = vm.currentStep {
                    activeJourneyPage(step: step)
                        .id(step.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: vm.currentStepIndex)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: vm.isComplete)
            .navigationTitle("Brew Journey".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized()) {
                        if vm.isComplete || !vm.hasStarted {
                            dismiss()
                        } else {
                            showExitConfirmation = true
                        }
                    }
                }
            }
        }
        .onReceive(ticker) { _ in vm.tick() }
        .onAppear { ringPulse = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            vm.endBackgroundSurfaces()
        }
        .alert("End brew journey?".localized(), isPresented: $showExitConfirmation) {
            Button("End".localized(), role: .destructive) { dismiss() }
            Button("Continue".localized(), role: .cancel) { }
        } message: {
            Text("Your brew progress will be lost.".localized())
        }
    }

    private func activeJourneyPage(step: BrewJourneyStep) -> some View {
        VStack(spacing: 0) {
            headerBar

            Spacer()

            timerSection(step: step)

            Spacer()

            if vm.hasStarted {
                HStack(spacing: 12) {
                    if vm.hasTotalTimer { pauseResumeButton }
                    nextStepButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            } else {
                startButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
    }

    private var headerBar: some View {
        VStack(spacing: 16) {
            HStack {
                Text(
                    String(
                        format: "Step %d of %d".localized(),
                        vm.currentStepIndex + 1,
                        vm.steps.count
                    )
                )
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(WaznahCapsuleBadgeBackground())
                .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                .clipShape(Capsule())

                Spacer()

                Text(vm.recipe.method)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * vm.journeyProgress, 8))
                        .animation(.easeInOut(duration: 0.35), value: vm.journeyProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func timerSection(step: BrewJourneyStep) -> some View {
        VStack(spacing: 24) {
            ZStack {
                BrewWaterFill(fraction: vm.waterFillFraction)
                    .frame(width: 204, height: 204)
                    .clipShape(Circle())
                    .animation(.spring(response: 0.9, dampingFraction: 0.8), value: vm.waterFillFraction)
                    .accessibilityHidden(true)

                Circle()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.1) : Color(.secondarySystemBackground),
                        lineWidth: 16
                    )
                    .frame(width: 220, height: 220)

                if vm.hasTotalTimer {
                    Circle()
                        .trim(from: 0, to: vm.timerProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: vm.timerProgress)
                } else {
                    Circle()
                        .stroke(WaznahBrandColors.accent(for: colorScheme).opacity(0.2), lineWidth: 16)
                        .frame(width: 220, height: 220)
                        .scaleEffect(ringPulse ? 1.03 : 0.97)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: ringPulse)
                }

                if vm.hasTotalTimer {
                    VStack(spacing: 4) {
                        Text(vm.timeFormatted(vm.elapsedTime))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text(
                            String(
                                format: "of %@".localized(),
                                vm.timeFormatted(vm.totalDuration)
                            )
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                        if vm.hasStarted, let remaining = vm.stepRemaining {
                            Label(vm.timeFormatted(remaining), systemImage: "hourglass")
                                .font(.caption.weight(.bold))
                                .monospacedDigit()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background {
                                    if remaining <= 3 { Color(hex: "#86373E") } else { WaznahCapsuleBadgeBackground() }
                                }
                                .foregroundColor(remaining <= 3 ? .white : WaznahBrandColors.accent(for: colorScheme))
                                .clipShape(Capsule())
                                .padding(.top, 4)
                                .animation(.easeOut(duration: 0.2), value: remaining <= 3)
                        }
                    }
                } else {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            // Ring geometry must not mirror in RTL, or progress starts from the bottom.
            .environment(\.layoutDirection, .leftToRight)

            VStack(spacing: 8) {
                Text(
                    String(
                        format: "Pour to %@ ml".localized(),
                        BrewJourneyBuilder.formatVolume(step.targetTotalML)
                    )
                )
                .font(.title2.weight(.bold))
                .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                .multilineTextAlignment(.center)

                Text(
                    String(
                        format: "+%@ ml".localized(),
                        BrewJourneyBuilder.formatVolume(step.pourAmountML)
                    )
                )
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

                Text(step.title.isEmpty ? "Pour".localized() : step.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.top, 4)

                if let next = vm.nextStep {
                    HStack(spacing: 6) {
                        Text("Next".localized())
                            .fontWeight(.bold)
                        Text("·")
                        Text(String(format: "Pour to %@ ml".localized(), BrewJourneyBuilder.formatVolume(next.targetTotalML)))
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .opacity(0.75)
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var startButton: some View {
        Button { vm.startJourney() } label: {
            Label("Start".localized(), systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#86373E"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var pauseResumeButton: some View {
        Button { vm.togglePauseResume() } label: {
            Label(
                vm.isRunning ? "Pause".localized() : "Resume".localized(),
                systemImage: vm.isRunning ? "pause.fill" : "play.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(vm.isRunning ? Color(hex: "#86373E") : WaznahBrandColors.accent(for: colorScheme).opacity(0.15))
            .foregroundColor(vm.isRunning ? .white : WaznahBrandColors.accent(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var nextStepButton: some View {
        Button { vm.advanceStep() } label: {
            Label(
                vm.isLastStep ? "Finish".localized() : "Next".localized(),
                systemImage: vm.isLastStep ? "checkmark" : "forward.fill"
            )
            .font(.headline)
            .frame(maxWidth: vm.hasTotalTimer ? 130 : .infinity)
            .padding(.vertical, 16)
            .background(vm.hasTotalTimer ? WaznahBrandColors.accent(for: colorScheme).opacity(0.15) : Color(hex: "#86373E"))
            .foregroundColor(vm.hasTotalTimer ? WaznahBrandColors.accent(for: colorScheme) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(WaznahBrandColors.accent(for: colorScheme).opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(ringPulse ? 1.08 : 0.94)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: ringPulse)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text("Brew complete!".localized())
                    .font(.largeTitle.weight(.bold))
                Text("Enjoy your cup.".localized())
                    .font(.body)
                    .foregroundColor(.secondary)

                if vm.hasTotalTimer {
                    Text(
                        String(
                            format: "Total brew time: %@".localized(),
                            vm.timeFormatted(vm.elapsedTime)
                        )
                    )
                    .font(.headline.weight(.semibold))
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                }

                Text(String(
                    format: "%@ ml · %d steps".localized(),
                    BrewJourneyBuilder.formatVolume(vm.recipe.totalWaterML),
                    vm.steps.count
                ))
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            tasteFeedback
                .padding(.horizontal, 24)

            Spacer()

            Button {
                selectedTaste = nil
                vm.restart()
            } label: {
                Label("Brew Again".localized(), systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
            }

            Button { dismiss() } label: {
                Text("Done".localized())
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#86373E"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }

    private var tasteFeedback: some View {
        VStack(spacing: 12) {
            Text("How did it taste?".localized())
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(BrewTaste.allCases) { taste in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTaste = taste
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(taste.emoji).font(.title2)
                            Text(taste.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTaste == taste {
                                WaznahBrandColors.accent(for: colorScheme).opacity(0.18)
                            } else {
                                WaznahChipSurfaceBackground()
                            }
                        }
                        .foregroundColor(selectedTaste == taste ? WaznahBrandColors.accent(for: colorScheme) : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedTaste {
                Label(selectedTaste.tip, systemImage: "lightbulb.fill")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

enum BrewTaste: String, CaseIterable, Identifiable {
    case sour, balanced, bitter, weak

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .sour: return "🍋"
        case .balanced: return "😋"
        case .bitter: return "☕️"
        case .weak: return "💧"
        }
    }

    var title: String {
        switch self {
        case .sour: return "Sour".localized()
        case .balanced: return "Balanced".localized()
        case .bitter: return "Bitter".localized()
        case .weak: return "Weak".localized()
        }
    }

    /// Simple dial-in advice from the cup's dominant taste.
    var tip: String {
        switch self {
        case .sour: return "Under-extracted: grind finer or use hotter water next time.".localized()
        case .balanced: return "Nailed it — keep this recipe as is.".localized()
        case .bitter: return "Over-extracted: grind coarser or use slightly cooler water.".localized()
        case .weak: return "Too light: use more coffee (a tighter ratio, e.g. 1:15).".localized()
        }
    }
}

/// Coffee "liquid" that rises inside the timer ring as water is poured.
private struct BrewWaterFill: View {
    let fraction: CGFloat
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height * min(max(fraction, 0), 1)
            ZStack(alignment: .bottom) {
                Color.clear
                BrewWave(phase: phase, amplitude: fraction > 0 && fraction < 1 ? 5 : 0)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#BF8A6E").opacity(0.35), Color(hex: "#86373E").opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: height + 10)
                    .offset(y: 10)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

private struct BrewWave: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = amplitude
        path.move(to: CGPoint(x: 0, y: midY))
        stride(from: CGFloat(0), through: rect.width, by: 2).forEach { x in
            let y = midY + sin((x / rect.width) * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
