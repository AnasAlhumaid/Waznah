//
//  AppReviewCoordinator.swift
//  Waznah
//
//  Counts calm, successful moments and decides when to offer the rating sheet.
//  Launch itself never asks. Apple still decides whether the system review card appears.

import SwiftUI

enum AppReviewPresentationSource: Equatable {
    /// After a finished brew, journey, or a newly saved recipe.
    case automatic
    /// The permanent entry in the brew info screen.
    case settings
}

@MainActor
final class AppReviewCoordinator: ObservableObject {
    static let shared = AppReviewCoordinator()

    @Published var isPresented = false
    @Published var presentationSource: AppReviewPresentationSource = .settings
    /// Bumped once the rating sheet is gone, so Apple's card is not stacked on ours.
    @Published var nativeReviewRequestID = 0

    private let store: AppReviewStore
    private var snapshot: AppReviewSnapshot
    private var scheduleGeneration = 0
    private var hasPendingSchedule = false
    private var journeyVisible = false
    private var journeyAwaitingDismiss = false
    private var updateWallVisible = false
    private var launchGateVisible = false
    private var deferredEvaluation = false

    private init(store: AppReviewStore = AppReviewStore()) {
        self.store = store
        self.snapshot = store.load()
        #if DEBUG
        let failures = AppReviewPolicy.selfCheckFailures()
        assert(failures.isEmpty, "App review policy self-check failed: \(failures.joined(separator: ", "))")
        #endif
        registerJourneyHooks()
    }

    func noteBecameActive(now: Date = Date(), calendar: Calendar = .current) {
        var changed = false
        if snapshot.firstLaunchAt == nil {
            snapshot.firstLaunchAt = now
            changed = true
        }

        let stamp = Self.dayStamp(for: now, calendar: calendar)
        if snapshot.lastActiveDay != stamp {
            snapshot.activeDayCount += 1
            snapshot.lastActiveDay = stamp
            changed = true
        }

        if changed {
            store.save(snapshot)
        }
    }

    func setLaunchGateVisible(_ visible: Bool) {
        launchGateVisible = visible
        if !visible {
            flushDeferredEvaluation()
        }
    }

    func setUpdateWallVisible(_ visible: Bool) {
        updateWallVisible = visible
        if visible {
            cancelPendingAutomaticPrompt()
            if isPresented && presentationSource == .automatic {
                isPresented = false
                deferredEvaluation = true
            }
        } else {
            flushDeferredEvaluation()
        }
    }

    func presentFromSettings() {
        guard !updateWallVisible, !isPresented else { return }
        cancelPendingAutomaticPrompt()
        presentationSource = .settings
        isPresented = true
    }

    func recordBrewTimerFinished() {
        recordPositiveEvent(scheduleAfter: 2)
    }

    func recordRecipeSaved() {
        // Wait until the recipe editor sheet has finished dismissing.
        recordPositiveEvent(scheduleAfter: 1.4)
    }

    func recordBrewJourneyAppeared() {
        journeyVisible = true
        if hasPendingSchedule {
            deferredEvaluation = true
        }
        cancelPendingAutomaticPrompt()
    }

    func recordBrewJourneyCompleted() {
        journeyAwaitingDismiss = true
        recordPositiveEvent(scheduleAfter: nil)
        cancelPendingAutomaticPrompt()
    }

    func recordBrewJourneyRestarted() {
        journeyAwaitingDismiss = false
        cancelPendingAutomaticPrompt()
    }

    func recordBrewJourneyDismissed() {
        journeyVisible = false
        let shouldPrompt = journeyAwaitingDismiss || deferredEvaluation
        journeyAwaitingDismiss = false
        guard shouldPrompt else { return }
        deferredEvaluation = false
        scheduleAutomaticPrompt(after: 0.7)
    }

    /// The user left without reviewing or writing. Settings swipes do not call this.
    func noteDeferred() {
        if snapshot.lastOutcome == .responded,
           let lastPrompt = snapshot.lastPromptAt,
           Date().timeIntervalSince(lastPrompt) < AppReviewPolicy.current.responseInterval {
            return
        }
        snapshot.lastOutcome = .deferred
        snapshot.lastPromptAt = Date()
        store.save(snapshot)
    }

    func noteResponded() {
        snapshot.lastOutcome = .responded
        snapshot.lastPromptAt = Date()
        store.save(snapshot)
    }

    func cancelPendingAutomaticPrompt() {
        scheduleGeneration += 1
        hasPendingSchedule = false
    }

    /// Called after the sheet dismisses. The system may still decline to show a card.
    func scheduleNativeReviewAfterSheet() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !updateWallVisible else { return }
            nativeReviewRequestID += 1
        }
    }

    #if DEBUG
    /// Clears the counters. Debug console: `po AppReviewCoordinator.shared.resetStoredProgress()`
    func resetStoredProgress() {
        cancelPendingAutomaticPrompt()
        hasPendingSchedule = false
        journeyVisible = false
        journeyAwaitingDismiss = false
        deferredEvaluation = false
        isPresented = false
        snapshot = .empty
        store.reset()
    }
    #endif

    private func recordPositiveEvent(scheduleAfter delay: TimeInterval?) {
        snapshot.positiveEventCount += 1
        store.save(snapshot)
        guard let delay else { return }
        if journeyAwaitingDismiss || journeyVisible {
            deferredEvaluation = true
            return
        }
        scheduleAutomaticPrompt(after: delay)
    }

    private func scheduleAutomaticPrompt(after delay: TimeInterval) {
        scheduleGeneration += 1
        let generation = scheduleGeneration
        hasPendingSchedule = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard scheduleGeneration == generation else { return }
            hasPendingSchedule = false
            evaluateAutomaticPrompt()
        }
    }

    private func evaluateAutomaticPrompt() {
        guard !isPresented else { return }
        guard !journeyVisible, !journeyAwaitingDismiss else {
            deferredEvaluation = true
            return
        }

        if updateWallVisible || launchGateVisible {
            deferredEvaluation = true
            return
        }

        guard AppReviewPolicy.current.canPromptAutomatically(snapshot: snapshot, now: Date()) else { return }

        presentationSource = .automatic
        noteDeferred()
        isPresented = true
    }

    private func flushDeferredEvaluation() {
        guard deferredEvaluation else { return }
        guard !updateWallVisible, !launchGateVisible else { return }
        deferredEvaluation = false
        scheduleAutomaticPrompt(after: 0.8)
    }

    private func registerJourneyHooks() {
        WaznahEngagementCenter.brewJourneyAppeared = {
            Task { @MainActor in
                AppReviewCoordinator.shared.recordBrewJourneyAppeared()
            }
        }
        WaznahEngagementCenter.brewJourneyCompleted = {
            Task { @MainActor in
                AppReviewCoordinator.shared.recordBrewJourneyCompleted()
            }
        }
        WaznahEngagementCenter.brewJourneyRestarted = {
            Task { @MainActor in
                AppReviewCoordinator.shared.recordBrewJourneyRestarted()
            }
        }
        WaznahEngagementCenter.brewJourneyDismissed = {
            Task { @MainActor in
                AppReviewCoordinator.shared.recordBrewJourneyDismissed()
            }
        }
    }

    private static func dayStamp(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

struct AppReviewStore {
    /// UserDefaults key. Delete it to test the automatic sheet again.
    static let storageKey = "waznah.appReview.snapshot.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppReviewSnapshot {
        guard let data = defaults.data(forKey: Self.storageKey) else { return .empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return (try? decoder.decode(AppReviewSnapshot.self, from: data)) ?? .empty
    }

    func save(_ snapshot: AppReviewSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func reset() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
