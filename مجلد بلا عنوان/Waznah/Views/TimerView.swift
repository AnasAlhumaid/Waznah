//
//  TimerView.swift
//  Waznah
//
//  Created by Anas Hamad on 1/20/23.
//

import SwiftUI

struct TimerView: View {
    @State private var selectedTime: Int = 150 // Default time in seconds
    @State private var elapsedTime: Int = 0
    @State private var timer: Timer?
    @State private var isPaused: Bool = true
    @State private var showTimer: Bool = false
    
    var body: some View {
       
            VStack {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(elapsedTime) / CGFloat(selectedTime))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color("coffeeN"))
                        .rotationEffect(Angle(degrees: -90))
                    
                    
                    VStack {
                        Text("\(timeFormatted(elapsedTime))")
                            .font(.largeTitle)
                        
                        HStack {
                            Button(action: {
                                if isPaused {
                                    startTimer()
                                } else {
                                    pauseTimer()
                                }
                            }) {
                                Text(isPaused ? "Start".localized() : "Pause".localized())
                                    .foregroundColor(.white)
                                    .frame(width: 70,height: 30)
                                    .shadow(radius: 1)
                                    .background(Color("greenN"))
                                    .cornerRadius(10)
                                
                            }
                            
                            Button(action: {
                                stopTimer()
                            }) {
                                Text("Stop".localized())
                                    .foregroundColor(.white)
                                    .frame(width: 70,height: 30)
                                    .shadow(radius: 1)
                                    .background(Color("redN"))
                                    .cornerRadius(10)
                                    
                            }
                        }
                        .padding(.top, 20)
                    }
                    
                }
                .frame(width: 200, height: 200)
                .padding()
                
                
                
                Button {
                    showTimer.toggle()
                } label: {
                    Text("Select Timer".localized())
                        .foregroundColor(.white)
                        .frame(width: 100,height: 30)
                        .shadow(radius: 1)
                        .background(Color("show"))
                        .cornerRadius(10)
                }
                
                .halfSheet(showSheet: $showTimer) {
                    CustumAlertTime(selectedTime: $selectedTime, showAlert: $showTimer)
                        .background(.gray.opacity(0.2))
                } onEnd: {
                    
                }

               
                
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(15)
        }
     
        
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if elapsedTime < selectedTime {
                elapsedTime += 1
            } else {
                resetTimer()
            }
        }
        isPaused = false
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        isPaused = true
    }
    
    private func stopTimer() {
        resetTimer()
        isPaused = false
    }
    
    private func resetTimer() {
        timer?.invalidate()
        elapsedTime = 0
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




struct CustumAlertTime : View {
    
    @Binding var selectedTime : Int
    @Binding var showAlert : Bool
    var body: some View{
        VStack{
            Picker("Set Time", selection: $selectedTime) {
                ForEach(1...3600, id: \.self) { timeInSeconds in
                    Text(timeFormatted(timeInSeconds)).tag(timeInSeconds)
                }
            }
            .labelsHidden()
            .pickerStyle(WheelPickerStyle())
            .padding(.vertical)
        }
        .padding(.vertical,25)
        .padding(.horizontal,35)
        .cornerRadius(20)
       
        .cornerRadius(20)
        .frame(maxWidth: .infinity,maxHeight: .infinity)
       
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
