//
//  ApiRecepeiScreen.swift
//  Waznah
//
//  Created by Anas Hamad on 11/5/23.
//

import SwiftUI
import FirebaseFirestore

struct ApiRecepeiView: View {
    
    var recepei : YourDataModelRes
    var body: some View {
//        MugView()
        VStack{
            RecepeiCardApi(recepi: RecepeiApi(grain: recepei.grain ?? "", more: "", roastery: recepei.rostery ?? "", tool:recepei.tool ?? "" , water: recepei.waterGrams ?? "", ration: recepei.ratio ?? "", temp: recepei.ratio ?? ""))
            HStack{
                LottieView()
                    .frame(width: 200,height: 200)
             
                   
            }
       
            
         
            CoffeeDripView(phaseData: recepei.field3 ?? [])
            Spacer()
          
        }
        .frame(width: size.width - 40,height: size.height - 100)
        
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

//#Preview {
//    ApiRecepeiView()
//}



struct TimerViewApi: View {
    @State private var selectedTime: Int = 150 // Default time in seconds
    @State private var elapsedTime: Int = 0
    @State private var timer: Timer?
    @State private var isPaused: Bool = true
    @State private var showTimer: Bool = false
    
    var body: some View {
       
            VStack {
                ZStack {
               
                    
                    
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
              
                .padding()
                
                
                
             

               
                
            }
            .padding()
          
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
struct RecepeiCardApi: View {
    
    let recepi : RecepeiApi
   
   
    var body: some View {
        VStack(alignment: .leading){
            
            HStack{
          
                   
                
                VStack(alignment: .leading){
                  
                        VStack{
                            Text(recepi.roastery)
                                .font(.title2)
                            Text(recepi.tool)
                                .font(.title3)
                        }
                        
                     
                      
                     

                     
                            
                  
                    VStack(alignment: .leading){
                        HStack{
                            Image(systemName: "circle.hexagongrid")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "354449"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Grams Bean:".localized())
                                    .font(.caption)
                                Text("\(recepi.grain)")
                                    .font(.caption)
                            }
                            
                            Image(systemName: "drop")
                                .resizable()
                                .frame(width: 8,height: 8)  .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "648981"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Water:".localized())
                                    .font(.caption)
                                Text("\(recepi.water)")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        .frame(width: 250)
                        
                        HStack{
                            Image(systemName: "percent")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "BF8A6E"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Ratio:".localized())
                                    .font(.caption)
                                Text("\(recepi.ration)")
                                    .font(.caption)
                            }
                            
                            Image(systemName: "thermometer.medium")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "8F7469"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Temp:".localized())
                                    .font(.caption)
                                Text("\(recepi.temp)")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        .frame(width: 250)
                        
                        
                    }
                    
                }
                
            }
            
           
            
        }
        .frame(width: size.width - 40 ,height: 130)
        .background(
            .thinMaterial
        )
       
    }
}




//struct StepsAndTimes: Identifiable {
//    let id: Int
//    let description: String
//    let phaseDuration: TimeInterval
//}

struct CoffeeDripView: View {
    @State private var elapsedTime: TimeInterval = 0
    @State private var currentPhase = 0
    @State var timer: Timer?
    var phaseData: [StepsAndTimes]
   
    
    var body: some View {
        VStack{
            Text("Steps".localized())
            
            ForEach(phaseData,id: \.self) { datum in
                
//                Text( datum.step)
//                Text("\(datum.time)")
//                Text(datum.water)
                
                
                HStack{
                    VStack{
                       
                        Text(datum.step)
                            .lineLimit(3)
                    }
                    Spacer()
                    VStack{
                        Text("Time".localized())
                        HStack(spacing:0){
                            Text(String(format: "%.1f", datum.time))
                            Text("sec")
                        }
                    }
                    
                    Spacer()
                    VStack{
                        Text("Gram".localized())
                        Text(datum.water)
                    }
                }
                .padding()
                .frame(width: size.width - 40)
                .background(.thinMaterial)
                .cornerRadius(10)
            }
        }
      
     
    }

    func startTimer() {
          guard currentPhase < phaseData.count else {
              print("No phases available")
              return
          }

          let phaseEndTime = phaseData[currentPhase].time

//          timer?.invalidate()
//          timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//              withAnimation {
//                  self.elapsedTime += 1
//              }
//              if self.elapsedTime >= phaseEndTime {
//                  self.timer?.invalidate()
//                  startNextPhase()
//              }
//          }
      }
    func startNextPhase() {
        elapsedTime = 0
        guard currentPhase < phaseData.count else {
            // Handle the case where there are no more phases
            print("No more phases")
            return
        }

        let currentPhaseDuration = phaseData[currentPhase].time
        elapsedTime += currentPhaseDuration

        let nextPhaseIndex = currentPhase + 1
        if nextPhaseIndex < phaseData.count {
            let nextPhaseDuration = phaseData[nextPhaseIndex].time
            let totalDuration = elapsedTime + nextPhaseDuration

            timer?.invalidate()

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                withAnimation {
                    self.elapsedTime += 1
                }
                if self.elapsedTime >= totalDuration {
                    self.timer?.invalidate()
                    // Optionally start another phase or handle completion
                }
            }

            currentPhase += 1  // Move to the next phase
        } else {
            // Handle the case where there are no more phases
            print("No more phases")
        }
    }



    func phaseDescription(_ phase: Int) -> String {
        guard phase >= 0 && phase < phaseData.count else {
            return "No Phase"
        }
        return phaseData[phase].step
    }

    func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        let minutes = (seconds % 3600) / 60
        let hours = seconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds % 60)
    }
    
 
}
//
//struct ContentView: View {
//    var body: some View {
//        CoffeeDripView()
//    }
//}
//
//@main
//struct YourApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

class FirestoreManager: ObservableObject {
    @Published var fetchedData: [YourDataModelRes] = []
    let db = Firestore.firestore()

    func fetchDataFromFirestore(completion: @escaping ( Error?) -> Void) {
           let collectionName = "Recepei" // Replace with your actual collection name

           db.collection(collectionName).getDocuments { (snapshot, error) in
               if let error = error {
                   print("Error getting documents: \(error)")
                   completion( error)
                   return
               }

               

               for document in snapshot!.documents {
                   do {
                       let decoder = JSONDecoder()
                       
                     let data = document.data()
                           let jsonData = try JSONSerialization.data(withJSONObject: data)
                           let model = try decoder.decode(YourDataModelRes.self, from: jsonData)
                       self.fetchedData.append(model)
                       
                   } catch {
                       print("Error decoding document: \(error)")
                       completion( error)
                   }
               }

               completion( nil)
           }
       }
}

struct YourDataModelRes: Codable,Hashable,Identifiable {
 
    
    var id : String?
    let rostery: String?
    let grain: String?
    let waterGrams: String?
    let coffeeGrams: String?
    let ratio: String?
    let temp: String?
    let tool: String?
    let field3: [StepsAndTimes]?

    static func == (lhs: YourDataModelRes, rhs: YourDataModelRes) -> Bool {
         return lhs.rostery == rhs.rostery &&
                lhs.grain == rhs.grain &&
                lhs.waterGrams == rhs.waterGrams &&
                lhs.coffeeGrams == rhs.coffeeGrams &&
                lhs.ratio == rhs.ratio &&
                lhs.temp == rhs.temp &&
                lhs.tool == rhs.tool &&
                lhs.field3 == rhs.field3
     }
    private enum CodingKeys: String, CodingKey {
          case id
          case rostery
        case grain,waterGrams,coffeeGrams,ratio,temp,tool
        case field3
          // ... map other properties to their corresponding keys
      }
}
struct StepTime: Codable,Hashable {
    let step: String?
    let time: TimeInterval?
}



//{
//    @State private var elapsedTime: TimeInterval = 0
//    @State private var currentPhase = 0
//     @State   var timer: Timer?
//
//    var body: some View {
//        VStack {
//        
//
//            Text("Phase: \(phaseDescription(currentPhase))")
//                .font(.title)
//                .padding()
//
//            Text("Time: \(formatTime(elapsedTime))")
//                .font(.title)
//                .padding()
//
//            Button(action: {
//                startNextPhase()
//            }) {
//                if elapsedTime == 0 {
//                    Text("Start")
//                        .font(.title)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }else{
//                    Text("Next Phase")
//                        .font(.title)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//            }
//        }
//    }
//
//    func startNextPhase() {
//        if currentPhase < 4 {
//            currentPhase += 1
//            let phaseDuration: TimeInterval = 40 // Each phase lasts 40 seconds
//            let phaseStartTime = TimeInterval(currentPhase - 1) * phaseDuration
//            let phaseEndTime = TimeInterval(currentPhase) * phaseDuration
//
//            timer?.invalidate() // Stop the previous timer if it's running
//
//            withAnimation {
//                self.elapsedTime = phaseStartTime // Reset the elapsed time for the new phase
//            }
//
//            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//                withAnimation {
//                    self.elapsedTime += 1
//                }
//                if self.elapsedTime >= phaseEndTime {
//                    self.timer?.invalidate()
//                }
//            }
//        }
//    }
//
//
//
//    func phaseDescription(_ phase: Int) -> String {
//        switch phase {
//        case 1:
//            return "Blooming"
//        case 2:
//            return "first Drip"
//        case 3:
//            return "second Dirp"
//        case 4:
//            return "Third Drip"
//        default:
//            return "No Phase"
//        }
//    }
//
//    func formatTime(_ time: TimeInterval) -> String {
//        let seconds = Int(time)
//        let minutes = (seconds % 3600) / 60
//        let hours = seconds / 3600
//        return String(format: "%02d:%02d:%02d", hours, minutes, seconds % 60)
//    }
//}
