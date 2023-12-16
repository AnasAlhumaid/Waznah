//
//  RecepeiScreen.swift
//  Waznah
//
//  Created by Anas Hamad on 7/27/23.
//

import SwiftUI

struct RecepeiScreen: View {
    
    @FetchRequest(fetchRequest: Recepie.all)
    var recepisResults : FetchedResults<Recepie>
    @Environment(\.managedObjectContext) private var viewContext
    @State var showSheet = false
    @State var showDetailSheet = false
    @FetchRequest(entity: Recepie.entity(), sortDescriptors: [])
       var singRecepisResults: FetchedResults<Recepie>
    
    
    @State  var arrayRecepie: [Recepie] = []
    var body: some View {
        NavigationView{
            
                VStack{
                    List{
                        ForEach(recepisResults,id: \.self){ rec in
                            if rec.roastery != "" && rec.tools != ""{
                         
                                    RecepeiCard(recepi: rec, ShowSheet: $showDetailSheet)
                                    .onTapGesture {
                                        showDetailSheet.toggle()
                                    }

                                    .sheet(isPresented: $showDetailSheet) {
                                        RecipeView( recepi: rec )
                                    }
                               
                            }
                                
                        }
                        .onDelete(perform: deleteItem)
                    }
                    
                }
                .background(.clear)
            
            .sheet(isPresented: $showSheet, content: {
                RecepieDetail( showSheet: $showSheet)
            })
            .navigationTitle("Recipes".localized())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem{
                    Button {
                        showSheet.toggle()
                    } label: {
                        Image(systemName: "plus.app")
                            .foregroundColor(.black)
                    }

                }
            }
        }
      
    }
    
    func deleteItem(offsets : IndexSet){
        for offset in offsets{
            
            let reci = recepisResults[offset]
            viewContext.delete(reci)
            
            do{
               try viewContext.save()
            }catch{
                print(error)
            }
           
        }

    }
}

//struct RecepeiScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        RecepeiScreen()
//    }
//}

struct RecepeiCard: View {
    
    let recepi : Recepie
    @Binding var ShowSheet : Bool
   
    var body: some View {
        VStack{
            
            HStack{
                Image(recepi.tools ?? "")
                    .resizable()
                    .frame(width: 80,height: 80)
                   
                
                VStack(alignment: .leading){
                    HStack{
                        VStack(alignment: .leading){
                            Text(recepi.roastery ?? "")
                                .font(.title2)
                            Text(recepi.tools ?? "")
                                .font(.title3)
                        }
                        
                        Spacer()
                      
                     

                     
                            
                    }
                    VStack{
                        HStack{
                            Image(systemName: "circle.hexagongrid")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "354449"))
                                .clipShape(Circle())
                            Text("Gind:\(recepi.grain ?? "")")
                                .font(.caption)
                            
                            Image(systemName: "drop")
                                .resizable()
                                .frame(width: 8,height: 8)  .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "648981"))
                                .clipShape(Circle())
                            Text("Water:\(recepi.prepare ?? "")")
                            
                                .font(.caption)
                            
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
                            Text("Ratio:\(recepi.ratio ?? "")")
                                .font(.caption)
                            
                            Image(systemName: "thermometer.medium")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "8F7469"))
                                .clipShape(Circle())
                            Text("temp:\(recepi.temp ?? "")")
                                .font(.caption)
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
        .cornerRadius(30)
    }
}
