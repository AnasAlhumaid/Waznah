//
//  Background.swift
//  Waznah
//
//  Created by Anas Hamad on 10/4/22.
//

import SwiftUI

struct Background: View {
    
    private var isDaytime: Bool {
          let calendar = Calendar.current
          let currentTime = getCurrentTime()
          let startOfDay = calendar.startOfDay(for: currentTime)
          let sixAM = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: startOfDay)!
          let sixPM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: startOfDay)!
          return currentTime >= sixAM && currentTime < sixPM
      }
 @State var highlite = false
    @State var showInfo = false
    var body: some View {
        
        NavigationView{
            
                ZStack{
                    
                    if isDaytime{
                        morning
                        
                    }else{
                        night
                    }
                    
                    ZStack{
                        
                        Blur(radius: 20, opaque: true)
                        ScrollView{
                            VStack{
                                CalculateScreen()
                                    .shadow(color: .black.opacity(0.25), radius:5, x:5,y: 8)
                                
                                
                                TimerView()
                                    .shadow(color: .black.opacity(0.25), radius:5, x:5,y: 8)
                            }
                            
                        }
                       
                    }
                    
                    //clip content
                    
                    .popover(isPresented: $showInfo) {
                        
                    }
                }
                .navigationTitle("Waznah".localized())
            
      
           
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing){
                Button {
                    withAnimation {
                        highlite.toggle()
                    }
                 
                } label: {
                    Image(systemName: "info.circle")
                }
    
                    
                
            }
        }
         
        }
        .overlay {
            if highlite {
                ZStack{
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
   
                    VStack{
                        Text(
                            
                            "The ratio of ground coffee to water differs greatly between brew methods and personal taste. The ratios on this page are based on a mixture of consensus and official sources.".localized()
                        )
                        Text(
                            "But, there is no right way—so long as you enjoy your coffee and aren't consuming a dangerous amount!".localized())
                    }

                   
                    .padding()
                    .font(.title2)
                   
                }
                .onTapGesture {
                    withAnimation {
                        highlite.toggle()
                    }
                   
                }
            }
        }
        .onTapGesture {
                    // Dismiss the keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        
    }
    
    func horeState() -> ColorScheme{
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<12 :
            return .light
        case 12 :
            return
                .light
        case 13..<17 :
            return .dark
        case 17..<22 :
            return .dark
        default:
            return .light
        }
    }
    
    
    
    var sun : some View{
        Ellipse()
            .fill(LinearGradient(
                    gradient: Gradient(stops: [
                .init(color: Color(#colorLiteral(red: 1, green: 0.5783333778381348, blue: 0.5208333730697632, alpha: 1)), location: 0),
                .init(color: Color(#colorLiteral(red: 1, green: 0.7508333921432495, blue: 0.5208333730697632, alpha: 0.4300000071525574)), location: 1)]),
                    startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17),
                    endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999)))
        .frame(width: 500, height: 500)
    }
        
        var moon :some View{

               
                ZStack {
               
                    Ellipse()
                    .fill(Color(#colorLiteral(red: 0.9458333253860474, green: 0.9458333253860474, blue: 0.9458333253860474, alpha: 1)))
                    .frame(width: 200.3, height: 200)
                    .rotationEffect(.degrees(0))

                //Ellipse 8
                    Ellipse()
                    .fill(Color(#colorLiteral(red: 0.8333333134651184, green: 0.8333333134651184, blue: 0.8333333134651184, alpha: 1)))
                    .frame(width: 200.8, height:200)
                    
                 
                    
                }
 
        }
    var stars :some View{

           
            ZStack {
           
                Ellipse()
                .fill(Color(#colorLiteral(red: 0.9458333253860474, green: 0.9458333253860474, blue: 0.9458333253860474, alpha: 1)))
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(0))

            //Ellipse 8
                Ellipse()
                .fill(Color(#colorLiteral(red: 0.8333333134651184, green: 0.8333333134651184, blue: 0.8333333134651184, alpha: 1)))
                .frame(width: 30, height:30)
            }

    }
    var morning :some View{
        sun
    }
    var night :some View{
        ZStack{
            moon
            stars
                 .position(x: 250, y: 23  )
             stars
                  .position(x: 376, y: 120  )
             stars
                  .position(x: 50, y: 700 )
             stars
                  .position(x: 100, y: 100 )
             stars
                  .position(x: 245, y: 650  )
             stars
                  .position(x: 77, y: 467 )
             stars
                  .position(x: 100, y: 287  )
             stars
                  .position(x: 400, y: 620 )
        }
      
    }
}

struct Background_Previews: PreviewProvider {
    static var previews: some View {
        Background()
            
            .ignoresSafeArea()
            
    }
}



