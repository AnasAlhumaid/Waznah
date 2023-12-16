//
//  RecepieDetail.swift
//  Waznah
//
//  Created by Anas Hamad on 7/27/23.
//

import SwiftUI

struct RecepieDetail: View {
    @State var origin  = ""
    @State var grind  = ""
    @State var temp  = ""
    @State var ratio  = ""
    @State var water  = ""
    @State var more = ""
    @State var brew  = "V60"
   
    
    @Environment(\.managedObjectContext) private var viewContext
    
    let options = ["V60", "Chemex","Espresso", "Clod Brew","AeroPress"]
    @State private var selectedOption: String = "V60"
    @Binding var showSheet :Bool
    var body: some View {
        NavigationView{
            VStack{
                HStack{
                    Spacer()
                    Button {
                        showSheet.toggle()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 20,height: 20)
                            .foregroundColor(Color(hex: "ABAEA5"))
                    }
                    .padding()

                }
                List{
                    HStack{
                        Image(systemName: "pin")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "ABAEA5"))
                            .clipShape(Circle())
                        Text("Coffee Origin : ".localized())
                        Spacer()
                        CustomTextFieldC(text: $origin, placeHolder: "Origin...")
                            .frame(width: 100)
                           
                           
                            
                    }
                    .padding()
                    HStack{
                        Image(systemName: "circle.hexagongrid")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "354449"))
                            .clipShape(Circle())
                            
                        Text("Grind size :".localized())
                        Spacer()
                        CustomTextFieldC(text: $grind, placeHolder: "Size...")
                            .frame(width: 100)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    HStack{
                        Image(systemName: "thermometer.medium")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "648981"))
                            .clipShape(Circle())
                            
                        Text("Temperature:".localized())
                        Spacer()
                        CustomTextFieldC(text: $temp, placeHolder: "Degree...")
                            .frame(width: 100)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    HStack{
                        Image(systemName: "percent")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "BF8A6E"))
                            .clipShape(Circle())
                        Text("Ratio:".localized())
                        Spacer()
                        CustomTextFieldC(text: $ratio, placeHolder: "Ratio...")
                            .frame(width: 100)
                    }
                    .padding()
                    HStack{
                        Image(systemName: "drop")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "8F7469"))
                            .clipShape(Circle())
                        Text("Water:".localized())
                        Spacer()
                        CustomTextFieldC(text: $water, placeHolder: "Water...")
                            .frame(width: 100)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    HStack{
                        Image(systemName: "info")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "8F7462"))
                            .clipShape(Circle())
                        Text("More info:".localized())
                        Spacer()
                        CustomTextFieldC(text: $more, placeHolder: "More...")
                            .frame(width: 100)
                    }
                    .padding()
                HStack{
                    Image( "V60")
                        .resizable()
                        .frame(width: 15,height: 15)
                        .padding(10)
                        .foregroundColor(.white)
                        .background(Color(hex: "ffdeab"))
                        .clipShape(Circle())
                    Text("Choose Brew Type:".localized())
                    
                    Picker("", selection: $brew) {
                        ForEach(options, id: \.self) { option in
                            Text(option)
                         
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                    
                   
                    
                        .padding()
                }
                    VStack{
                        HStack{
                            Spacer()
                            Button {
                              
                                saveR()
                                showSheet.toggle()
                                
                                
                            } label: {
                                Text("Save".localized())
                                    .foregroundColor(.blue)
                                    .padding(10)
                                    .shadow(radius: 1)
                                    .background(Color(hex: "#D7D2CE"))
                                    .cornerRadius(10)
                            }
                            Spacer()
                        }
                        .padding()
                    }
            }
                
                
                
              

                
              
            }
            
        }
    }
    
    func saveR(){
        let recepie = Recepie(context: viewContext)
    
        recepie.id = UUID()
         recepie.grain = grind
         recepie.prepare = water
         recepie.ratio = ratio
         recepie.roastery = origin
         recepie.temp = temp
         recepie.tools = brew
        recepie.more = more
        
        do {
           try recepie.save()
        }catch{
            print(error)
        }
    }
    
}

//struct RecepieDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        RecepieDetail()
//    }
//}


struct CustomTextFieldC: View {
    @Binding var text: String
    var placeHolder : String
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeHolder)
                    .foregroundColor(Color.gray)
                   
            }
            TextField("", text: $text)
            
        }
      
    }
}
