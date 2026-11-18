//
//  RateWaznahSheet.swift
//  Waznah
//
//  Asks how the cup is going. People who love it can reach Apple's review card
//  or the App Store page. Everyone else can leave a private note.

import SwiftUI

struct RateWaznahSheet: View {
    let source: AppReviewPresentationSource
    var recordsOutcome: Bool = true

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var step: Step
    @State private var highlighted: Sentiment?
    @State private var feedbackSentiment: Sentiment
    @State private var note = ""
    @State private var appeared = false
    @State private var pulse = false
    @State private var sending = false
    @State private var mailUnavailable = false
    @State private var storePageOpened = false
    @State private var choseLove = false
    @State private var didFinishFlow = false
    @State private var requestedNativeReview = false
    @FocusState private var noteFocused: Bool

    private let coordinator = AppReviewCoordinator.shared

    init(
        source: AppReviewPresentationSource,
        recordsOutcome: Bool = true,
        initialStep: Step = .ask
    ) {
        self.source = source
        self.recordsOutcome = recordsOutcome
        _step = State(initialValue: initialStep)
        _feedbackSentiment = State(initialValue: .improve)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WaznahScreenBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        hero
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared && !reduceMotion ? 1 : (reduceMotion ? 1 : 0.92))

                        Group {
                            switch step {
                            case .ask:
                                askStep
                            case .loved:
                                lovedStep
                            case .alright:
                                alrightStep
                            case .feedback:
                                feedbackStep
                            case .sent:
                                sentStep
                            }
                        }
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .opacity.combined(with: .move(edge: .bottom))
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 28)
                    .padding(.bottom, 36)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .navigationBar)
            .waznahKeyboardDismissToolbar()
        }
        .animation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.86), value: step)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.78)) {
                appeared = true
            }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear(perform: handleDisappear)
        .onChange(of: note) { updated in
            let limit = AppReviewFeedbackLimits.maximumCharacters
            guard updated.count > limit else { return }
            note = String(updated.prefix(limit))
        }
    }

    // MARK: - Hero

    private var showsHero: Bool {
        dynamicTypeSize < .accessibility2
    }

    private var heroSymbol: String {
        switch step {
        case .ask, .alright:
            return "cup.and.saucer.fill"
        case .loved:
            return "heart.fill"
        case .feedback:
            return "text.bubble.fill"
        case .sent:
            return "checkmark"
        }
    }

    @ViewBuilder
    private var hero: some View {
        if showsHero {
            ZStack {
                Circle()
                    .fill(WaznahBrandColors.accent(for: colorScheme).opacity(colorScheme == .dark ? 0.22 : 0.12))
                    .frame(width: 112, height: 112)
                    .scaleEffect(!reduceMotion && pulse && (step == .ask || step == .loved) ? 1.06 : 1)

                Circle()
                    .stroke(WaznahBrandColors.accent(for: colorScheme).opacity(0.28), lineWidth: 1)
                    .frame(width: 112, height: 112)

                Image(systemName: heroSymbol)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .id(heroSymbol)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    .accessibilityHidden(true)
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: - Ask

    private var askStep: some View {
        VStack(spacing: 18) {
            titleBlock(
                "How are you enjoying Waznah?".localized(),
                subtitle: "A quiet moment after a good cup. No rewards — just an honest note.".localized()
            )

            VStack(spacing: 10) {
                sentimentButton(.love, title: "Love it".localized(), detail: "The cup hits the spot".localized(), symbol: "heart.fill")
                sentimentButton(.alright, title: "It's alright".localized(), detail: "Good enough for now".localized(), symbol: "cup.and.saucer.fill")
                sentimentButton(.improve, title: "Could be better".localized(), detail: "Something's off".localized(), symbol: "text.bubble.fill")
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)

            Button(action: deferAndClose) {
                Text("Not now".localized())
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            if source == .settings {
                settingsStoreLink
            }
        }
    }

    private func sentimentButton(_ sentiment: Sentiment, title: String, detail: String, symbol: String) -> some View {
        let selected = highlighted == sentiment
        return Button {
            choose(sentiment)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        selected
                            ? WaznahBrandColors.accent(for: colorScheme).opacity(colorScheme == .dark ? 0.28 : 0.14)
                            : Color.clear
                    )
            }
            .background {
                if !selected {
                    WaznahChipSurfaceBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        selected
                            ? WaznahBrandColors.accent(for: colorScheme).opacity(0.45)
                            : Color(hex: "#BF8A6E").opacity(colorScheme == .dark ? 0.22 : 0.12),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(WaznahPressButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var settingsStoreLink: some View {
        VStack(spacing: 6) {
            Button(action: openStoreFromSettingsLink) {
                Text("Write a review on the App Store".localized())
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.plain)
            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))

            Text("Opens the App Store review page. Optional, and nothing is unlocked.".localized())
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    // MARK: - Loved / alright / sent

    private var lovedStep: some View {
        VStack(spacing: 18) {
            titleBlock(
                "That means a lot".localized(),
                subtitle: lovedSubtitle
            )

            primaryButton(lovedButtonTitle, action: finishLoved)
        }
    }

    private var lovedSubtitle: String {
        if source == .automatic {
            return "If Apple shows a review card, a few words help other coffee people find Waznah.".localized()
        }
        if storePageOpened {
            return "A short review helps other coffee people find Waznah.".localized()
        }
        return "Opens the App Store review page. Optional, and nothing is unlocked.".localized()
    }

    private var lovedButtonTitle: String {
        if source == .settings && !storePageOpened {
            return "Write a review on the App Store".localized()
        }
        return "Done".localized()
    }

    private var alrightStep: some View {
        VStack(spacing: 18) {
            titleBlock(
                "Thanks for brewing with Waznah.".localized(),
                subtitle: "Glad it's in the routine.".localized()
            )

            primaryButton("Done".localized()) { dismiss() }

            Button {
                feedbackSentiment = .alright
                mailUnavailable = false
                withAnimation { step = .feedback }
            } label: {
                Text("Send a note".localized())
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
        }
    }

    private var sentStep: some View {
        VStack(spacing: 18) {
            titleBlock(
                "Thank you. We'll read it.".localized(),
                subtitle: "This note stays with the developer.".localized()
            )
            primaryButton("Done".localized()) { dismiss() }
        }
    }

    // MARK: - Feedback

    private var trimmedNoteCount: Int {
        note.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var canSendNote: Bool {
        trimmedNoteCount >= AppReviewFeedbackLimits.minimumCharacters && !sending
    }

    private var feedbackStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                noteFocused = false
                mailUnavailable = false
                withAnimation { step = .ask }
            } label: {
                Label {
                    Text("Back".localized())
                        .font(.body.weight(.semibold))
                } icon: {
                    Image(systemName: "chevron.backward")
                        .flipsForRightToLeftLayoutDirection(true)
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))

            titleBlock(
                "Tell us what to improve".localized(),
                subtitle: "This note goes to the developer. It is not published as an App Store review.".localized(),
                alignment: .leading
            )

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("What should we improve?".localized())
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $note)
                    .focused($noteFocused)
                    .font(.body)
                    .frame(minHeight: 140)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .tint(WaznahBrandColors.accent(for: colorScheme))
            }
            .background(WaznahInsetSurfaceBackground())
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "#BF8A6E").opacity(colorScheme == .dark ? 0.28 : 0.16), lineWidth: 1)
            }

            HStack(alignment: .firstTextBaseline) {
                if !note.isEmpty && trimmedNoteCount < AppReviewFeedbackLimits.minimumCharacters {
                    Text(String(format: "At least %d characters required".localized(), AppReviewFeedbackLimits.minimumCharacters))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(String(
                    format: "Feedback length %d of %d".localized(),
                    min(note.count, AppReviewFeedbackLimits.maximumCharacters),
                    AppReviewFeedbackLimits.maximumCharacters
                ))
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            }

            if mailUnavailable {
                Text("Could not open Mail, so you can share the note instead.".localized())
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: shareNote) {
                    Label("Share your note".localized(), systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(WaznahBrandColors.accent(for: colorScheme).opacity(0.16))
                        .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(WaznahPressButtonStyle())
            }

            Button(action: sendNote) {
                HStack(spacing: 8) {
                    if sending {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Send feedback".localized())
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSendNote ? Color(hex: "#86373E") : Color.gray.opacity(0.35))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(WaznahPressButtonStyle())
            .disabled(!canSendNote)
        }
    }

    // MARK: - Pieces

    private func titleBlock(_ title: String, subtitle: String, alignment: HorizontalAlignment = .center) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)

            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(Color(hex: "#86373E"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(WaznahPressButtonStyle())
    }

    // MARK: - Actions

    private func choose(_ sentiment: Sentiment) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        highlighted = sentiment

        let apply = {
            guard step == .ask else { return }
            switch sentiment {
            case .love:
                beginLove()
            case .alright:
                if recordsOutcome { coordinator.noteDeferred() }
                didFinishFlow = true
                withAnimation { step = .alright }
            case .improve:
                feedbackSentiment = .improve
                mailUnavailable = false
                withAnimation { step = .feedback }
            }
        }

        if reduceMotion {
            apply()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: apply)
        }
    }

    private func beginLove() {
        choseLove = true
        didFinishFlow = true
        if recordsOutcome { coordinator.noteResponded() }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { step = .loved }
        if source == .settings {
            openWriteReview { opened in
                storePageOpened = opened
            }
        }
    }

    private func finishLoved() {
        if source == .automatic {
            scheduleNativeReviewIfNeeded()
            dismiss()
            return
        }
        if !storePageOpened {
            openWriteReview { opened in
                storePageOpened = opened
                if opened { dismiss() }
            }
            return
        }
        dismiss()
    }

    private func scheduleNativeReviewIfNeeded() {
        guard recordsOutcome, source == .automatic, choseLove, !requestedNativeReview else { return }
        requestedNativeReview = true
        coordinator.scheduleNativeReviewAfterSheet()
    }

    private func deferAndClose() {
        if recordsOutcome { coordinator.noteDeferred() }
        didFinishFlow = true
        dismiss()
    }

    private func openStoreFromSettingsLink() {
        if recordsOutcome { coordinator.noteResponded() }
        didFinishFlow = true
        openWriteReview { opened in
            if opened { dismiss() }
        }
    }

    private func openWriteReview(completion: @escaping (Bool) -> Void) {
        UIApplication.shared.open(WaznahAppStore.writeReviewURL, options: [:]) { accepted in
            Task { @MainActor in
                completion(accepted)
            }
        }
    }

    private func sendNote() {
        guard canSendNote else { return }
        noteFocused = false
        let body = feedbackBody()
        guard let url = WaznahAppStore.mailtoURL(
            to: AppUpdateManager.supportEmail,
            subject: "Waznah feedback",
            body: body
        ) else {
            mailUnavailable = true
            return
        }

        sending = true
        UIApplication.shared.open(url, options: [:]) { accepted in
            Task { @MainActor in
                sending = false
                if accepted {
                    finishSent()
                } else {
                    mailUnavailable = true
                }
            }
        }
    }

    private func shareNote() {
        noteFocused = false
        SharePresenter.present(items: [feedbackBody()])
        finishSent()
    }

    private func finishSent() {
        if recordsOutcome { coordinator.noteResponded() }
        didFinishFlow = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { step = .sent }
    }

    private func feedbackBody() -> String {
        let code: String
        let label: String
        switch feedbackSentiment {
        case .love:
            code = "love"
            label = "Love it".localized()
        case .alright:
            code = "alright"
            label = "It's alright".localized()
        case .improve:
            code = "improve"
            label = "Could be better".localized()
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let system = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        return """
        Sentiment: \(code)
        Label: \(label)
        App: Waznah \(version) (\(build))
        System: \(system)
        Language: \(AppLanguage.preferredLanguageCode)

        \(note.trimmingCharacters(in: .whitespacesAndNewlines))
        """
    }

    private func handleDisappear() {
        guard recordsOutcome else { return }
        if choseLove {
            scheduleNativeReviewIfNeeded()
        }
        if !didFinishFlow && source == .automatic {
            coordinator.noteDeferred()
        }
    }

    enum Step: Equatable {
        case ask, loved, alright, feedback, sent
    }

    private enum Sentiment: Equatable {
        case love, alright, improve
    }
}

private struct WaznahPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct ReviewSheetChrome: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(colorScheme == .dark ? Color(hex: "#0C090B") : Color(hex: "#FBF7F4"))
        } else {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

extension View {
    func waznahReviewSheetChrome() -> some View {
        modifier(ReviewSheetChrome())
    }
}

struct RateWaznahSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RateWaznahSheet(source: .settings, recordsOutcome: false)
                .preferredColorScheme(.light)
                .previewDisplayName("Ask · Light")

            RateWaznahSheet(source: .automatic, recordsOutcome: false)
                .preferredColorScheme(.dark)
                .environment(\.dynamicTypeSize, .accessibility2)
                .previewDisplayName("Ask · Dark · Large type")

            RateWaznahSheet(source: .settings, recordsOutcome: false, initialStep: .feedback)
                .preferredColorScheme(.dark)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .previewDisplayName("Feedback · RTL")

            RateWaznahSheet(source: .automatic, recordsOutcome: false, initialStep: .loved)
                .preferredColorScheme(.dark)
                .previewDisplayName("Loved · Dark")
        }
    }
}
