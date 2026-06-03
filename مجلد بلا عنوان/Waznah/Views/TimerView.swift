//
//  TimerView.swift
//  Waznah
//
//  Created by Anas Hamad on 1/20/23.
//

import SwiftUI

struct TimerView: View {
    @State private var selectedTime: Int = 150
    @State private var elapsedTime: Int = 0
    @State private var isRunning = false
    @State private var showTimer: Bool = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Brew Timer".localized())
                            .font(.title3.weight(.bold))
                            .lineLimit(1)
                        Text(isRunning ? "Timer is running".localized() : "Ready when you are".localized())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showTimer.toggle()
                    } label: {
                        Label("Set", systemImage: "slider.horizontal.3")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#86373E").opacity(0.12))
                            .foregroundColor(Color(hex: "#86373E"))
                            .clipShape(Capsule())
                    }
                }
                
                ZStack {
                    Circle()
                        .stroke(Color(.secondarySystemBackground), lineWidth: 18)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                        )
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.easeInOut(duration: 0.25), value: progress)
                    
                    VStack(spacing: 6) {
                        Text(timeFormatted(remainingTime))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        
                        Text("of \(timeFormatted(selectedTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if elapsedTime > 0 {
                            Text("\(Int(progress * 100))%")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color(hex: "#86373E"))
                        }
                    }
                    
                }
                .frame(width: 190, height: 190)
                .padding(.vertical, 4)
                
                HStack(spacing: 12) {
                    Button {
                        toggleTimer()
                    } label: {
                        Label(isRunning ? "Pause".localized() : "Start".localized(), systemImage: isRunning ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#86373E"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    Button {
                        resetTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(width: 54, height: 50)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(Color(hex: "#86373E"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(elapsedTime == 0 && !isRunning)
                    .opacity(elapsedTime == 0 && !isRunning ? 0.45 : 1)
                }
                
                quickTimers
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
            .onReceive(ticker) { _ in
                tick()
            }
            .sheet(isPresented: $showTimer) {
                TimerPickerSheet(selectedTime: $selectedTime, elapsedTime: $elapsedTime, isRunning: $isRunning)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
     
        
    private var progress: CGFloat {
        guard selectedTime > 0 else { return 0 }
        return min(CGFloat(elapsedTime) / CGFloat(selectedTime), 1)
    }
    
    private var remainingTime: Int {
        max(selectedTime - elapsedTime, 0)
    }
    
    private var quickTimers: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach([60, 150], id: \.self) { seconds in
                    quickTimerButton(seconds)
                }
            }
            
            HStack(spacing: 8) {
                ForEach([240, 300], id: \.self) { seconds in
                    quickTimerButton(seconds)
                }
            }
        }
    }
    
    private func quickTimerButton(_ seconds: Int) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedTime = seconds
            elapsedTime = 0
            isRunning = false
        } label: {
            Text(timeFormatted(seconds))
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTime == seconds ? Color(hex: "#86373E").opacity(0.14) : Color(.secondarySystemBackground))
                .foregroundColor(selectedTime == seconds ? Color(hex: "#86373E") : .secondary)
                .clipShape(Capsule())
        }
    }
    
    private func toggleTimer() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if elapsedTime >= selectedTime {
            elapsedTime = 0
        }
        
        isRunning.toggle()
    }
    
    private func resetTimer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isRunning = false
        elapsedTime = 0
    }
    
    private func tick() {
        guard isRunning else { return }
        
        if elapsedTime < selectedTime {
            elapsedTime += 1
        }
        
        if elapsedTime >= selectedTime {
            isRunning = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes: Int = totalSeconds / 60
        let seconds: Int = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
 
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
            
            
    }
}




struct TimerPickerSheet: View {
    @Binding var selectedTime: Int
    @Binding var elapsedTime: Int
    @Binding var isRunning: Bool
    
    var body: some View {
        VStack(spacing: 18) {
            Text("Select Timer".localized())
                .font(.title3.weight(.bold))
            
            Picker("Set Time".localized(), selection: $selectedTime) {
                ForEach(Array(stride(from: 30, through: 3600, by: 30)), id: \.self) { timeInSeconds in
                    Text(timeFormatted(timeInSeconds)).tag(timeInSeconds)
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            
            Text("Changing time resets the current timer.".localized())
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .onChange(of: selectedTime) { _ in
            elapsedTime = 0
            isRunning = false
        }
    }
    
    private func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes: Int = totalSeconds / 60
        let seconds: Int = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct BlurView : UIViewRepresentable{
    
    func makeUIView(context: Context) -> some UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        
        return view
    }
    
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}
