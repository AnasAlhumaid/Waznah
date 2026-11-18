//
//  WaznahTimerLiveActivity.swift
//  WaznahTimerWidget — Lock Screen + Dynamic Island brew timer
//

import ActivityKit
import SwiftUI
import WidgetKit

@main
struct WaznahTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        WaznahTimerLiveActivity()
    }
}

private let brandRed = Color(red: 0x86 / 255, green: 0x37 / 255, blue: 0x3E / 255)
private let brandTan = Color(red: 0xBF / 255, green: 0x8A / 255, blue: 0x6E / 255)

struct WaznahTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrewTimerAttributes.self) { context in
            LockScreenBrewView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.method, systemImage: "cup.and.saucer.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(brandTan)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    BrewCountdownText(state: context.state)
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: 80, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.headline)
                            .font(.headline)
                        Text(context.state.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        BrewProgressBar(state: context.state)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.pausedRemaining == nil ? "cup.and.saucer.fill" : "pause.fill")
                    .foregroundColor(brandTan)
            } compactTrailing: {
                BrewCountdownText(state: context.state)
                    .frame(maxWidth: 48)
                    .foregroundColor(brandTan)
            } minimal: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundColor(brandTan)
            }
            .keylineTint(brandRed)
        }
    }
}

private struct LockScreenBrewView: View {
    let context: ActivityViewContext<BrewTimerAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(brandRed)
                Image(systemName: context.state.pausedRemaining == nil ? "cup.and.saucer.fill" : "pause.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(brandTan)
                    .lineLimit(1)
                Text(context.state.headline)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                BrewProgressBar(state: context.state)
            }

            Spacer(minLength: 8)

            BrewCountdownText(state: context.state)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: 100, alignment: .trailing)
        }
        .padding(16)
    }
}

/// Counts down by itself on the Lock Screen — no app updates needed while running.
private struct BrewCountdownText: View {
    let state: BrewTimerAttributes.ContentState

    var body: some View {
        Group {
            if let paused = state.pausedRemaining {
                Text(String(format: "%d:%02d", paused / 60, paused % 60))
            } else {
                Text(timerInterval: Date()...max(state.endDate, Date()), countsDown: true)
            }
        }
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
}

private struct BrewProgressBar: View {
    let state: BrewTimerAttributes.ContentState

    var body: some View {
        let start = state.endDate.addingTimeInterval(-TimeInterval(state.totalSeconds))
        Group {
            if state.pausedRemaining == nil {
                ProgressView(timerInterval: start...max(state.endDate, start.addingTimeInterval(1)), countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                ProgressView(value: Double(state.totalSeconds - (state.pausedRemaining ?? 0)), total: Double(state.totalSeconds))
            }
        }
        .tint(brandTan)
        .labelsHidden()
    }
}
