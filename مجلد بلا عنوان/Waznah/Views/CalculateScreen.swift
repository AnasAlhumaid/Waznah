//
//  CalculateScreen.swift
//  Waznah
//
//  Created by Anas Hamad on 10/4/22.
//

import SwiftUI

let size = UIScreen.main.bounds.size
struct CalculateScreen: View {
    
    @State private var coffeeRatio: Double = 15.0
      @State private var waterAmount: Double = 300.0
      @State private var coffeeAmount: Double = 0.0
    
    @State var coffeTx = " Coffee g".localized()
    @State var waterTX = " Water ml".localized()
    
    @State var isWater = false
    @ObservedObject var vm = CalcViewModel()
    var body: some View {
        ZStack{
            VStack{
                
                HStack{
                    
                    
                    VStack{
                        
                        Button {
                            withAnimation {
                                isWater.toggle()
                            }
                            
                        } label: {
                            Text( isWater ? "Water Calcuate".localized():"Coffee Clculate".localized())
                                .padding(10)
                                .background(.gray.opacity(0.2))
                                .cornerRadius(15)
                            
                        }
                        .shadow(color: .black.opacity(0.25), radius:5, x:5,y: 8)
                        
                        
                        CustomTextField(text: $vm.ratio, placeHolder: "Ratio".localized())
                        
                            .frame(width: 150, height: 30)
                            .shadow(radius: 10)
                            .background(Color("Color"))
                            .cornerRadius(10)
                            .keyboardType(.numberPad)
                            .shadow(color: .black.opacity(0.25), radius:5, x:5,y: 8)
                        
                        CustomTextField(text: $vm.value1, placeHolder: isWater ? waterTX : coffeTx)
                        
                        
                            .frame(width: 150, height: 30)
                            .shadow(radius: 10)
                            .background(Color("Color"))
                            .cornerRadius(10)
                        
                            .keyboardType(.numberPad)
                            .shadow(color: .black.opacity(0.25), radius:5, x:5,y: 8)
                        
                        
                        
                    }
                    
                    .frame(width: size.width / 1.5,height: 200)
                    .background(Color("Color"))
                    
                    
                    ZStack{
                        
                        VStack(alignment: .center){
                            
                            Text("\(isWater ? vm.water : vm.coffee)")
                            Text(isWater ? "of Coffee".localized(): "of Woter".localized())
                        }
                        
                        
                        
                    }
                    .frame(width: size.width / 2)
                    
                    .cornerRadius(15)
                    
                    
                    
                    
                    
                }
                .frame(width: Waznah.size.width - 20, height: 150)
                
                .background(.thinMaterial
                            //            RoundedRectangle(cornerRadius: 15,style: .circular)
                            //                .background(.ultraThinMaterial)
                            //                .overlay(content: {
                            //                    RoundedRectangle(cornerRadius: 15,style: .circular)
                            //                        .stroke(lineWidth: 0.5)
                            //                        .opacity(0.8)
                            //                })
                            
                )
                .cornerRadius(15)
                VStack{
                HStack{
                    Button {
                        vm.ratio = "16.6"
                    } label: {
                        Text("V60")
                            .foregroundColor(.black.opacity(0.5))
                            .padding(6)
                            .shadow(radius: 1)
                            .background(Color(hex: "#CDC6C3"))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        vm.ratio = "17.0"
                    } label: {
                        Text("Chemex")
                            .foregroundColor(.black.opacity(0.5))
                            .padding(6)
                            .shadow(radius: 1)
                            .background(Color(hex: "#D7D2CE"))
                            .cornerRadius(10)
                    }
                    Button {
                        vm.ratio = "2.0"
                    } label: {
                        Text("Espresso")
                            .foregroundColor(.black.opacity(0.5))
                            .padding(6)
                            .shadow(radius: 1)
                            .background(Color(hex: "#D3C0B2"))
                            .cornerRadius(10)
                    }
                    
                    
                }
                    HStack{
                        Button {
                            vm.ratio = "4.44"
                        } label: {
                            Text("Clod Brew")
                                .foregroundColor(.black.opacity(0.5))
                                .padding(6)
                                .shadow(radius: 1)
                                .background(Color(hex: "#A99282"))
                                .cornerRadius(10)
                        }
                        Button {
                            vm.ratio = "6.0"
                        } label: {
                            Text("AeroPress")
                                .foregroundColor(.black.opacity(0.5))
                                .padding(6)
                                .shadow(radius: 1)
                                .background(Color(hex: "#857B74"))
                                .cornerRadius(10)
                        }
                    }
            }
            }
            .onAppear(){
                
                for familyName in UIFont.familyNames{
                    
                    
                    for family in UIFont.fontNames(forFamilyName: familyName) {
                        print(family)
                    }
                }
                  
                
            }
            
        }
      
       
       
    }
    func calculateCoffeeAmount() {
          let coffeeAmount = waterAmount / coffeeRatio
          self.coffeeAmount = coffeeAmount
      }
    
   
}

struct CalculateScreen_Previews: PreviewProvider {
    static var previews: some View {
        CalculateScreen()
           
    }
}

class CalcViewModel: ObservableObject {
    @Published var value1 = "" {
        didSet { update() }
    }
    @Published var ratio = "" {
        didSet { update() }
    }
    @Published var value3 = "" {
        didSet { update() }
    }
    @Published var coffee: Double = 0.0
    @Published var water : Double = 0.0

    private func update() {
        
        
        self.coffee = (Double(value1) ?? 1.0)  * (Double(ratio) ?? 1.0)
        
        self.water = (Double(value1) ?? 1.0)  / (Double(ratio) ?? 1.0)
    }
    
 
}

struct CoffeeRecipe {
    var coffeeRatio: Double // e.g., 1:15
    var waterAmountInGrams: Double // grams
    var coffeeAmountInGrams: Double // grams
}

struct Glassmorphism: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Create a blur effect
                    Color.clear
                        .blur(radius: 10)
                        .opacity(0.9)
                    
                    // Add a transparent background color
                    Color.white.opacity(0.2)
                }
            )
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
        return NSLocalizedString(self, comment: comment)
    }
}
