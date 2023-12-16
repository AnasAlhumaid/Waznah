//
//  RecipeView.swift
//  Waznah
//
//  Created by Anas Hamad on 10/14/23.
//

import SwiftUI

struct RecipeView: View {
    
  
 
    @FetchRequest(fetchRequest: Recepie.all)
    private var recepisResults : FetchedResults<Recepie>
     var recepi: Recepie?
    @State var isSheet = false
    @Environment(\.managedObjectContext) var moc
    
    @State var screenShot : [Any] = []
    var body: some View {
        
        NavigationView{
            ScrollView{
                VStack{
                    Text("Recipe Card")
                        .font(.custom("FONTSPRINGDEMO-TheSeasonsRegular", size: 25))
                    VStack{
                        VStack{
                            VStack{
                                
                            }
                            .frame(height: 20)
                            HStack{
                                Text(recepi?.tools ?? "")
                                    .font(.custom("FONTSPRINGDEMO-TheSeasonsRegular", size: 25))
                                Spacer()
                                Image(recepi?.tools ?? "")
                                    .resizable()
                                    .frame(width: 70,height: 70)
                                    .padding()
                            }
                            .padding()
                            
                            VStack{
                                HStack{
                                    Image(systemName: "pin")
                                        .padding(10)
                                        .foregroundColor(.white)
                                        .background(Color(hex: "ABAEA5"))
                                        .clipShape(Circle())
                                    Text("Coffee Origin : ".localized())
                                    Text(recepi?.roastery ?? "")
                                    Spacer()
                                }
                                HStack{
                                    Image(systemName: "circle.hexagongrid")
                                        .padding(10)
                                        .foregroundColor(.white)
                                        .background(Color(hex: "354449"))
                                        .clipShape(Circle())
                                    
                                    Text("Grind size :".localized())
                                    Text(recepi?.grain ?? "")
                                    Spacer()
                                }
                                HStack{
                                    Image(systemName: "thermometer.medium")
                                        .padding(10)
                                        .foregroundColor(.white)
                                        .background(Color(hex: "648981"))
                                        .clipShape(Circle())
                                    
                                    Text("Temperature:".localized())
                                    Text(recepi?.temp ?? "")
                                    Spacer()
                                }
                                HStack{
                                    Image(systemName: "percent")
                                        .padding(10)
                                        .foregroundColor(.white)
                                        .background(Color(hex: "BF8A6E"))
                                        .clipShape(Circle())
                                    Text("Ratio:".localized())
                                    Text(recepi?.ratio ?? "")
                                    Spacer()
                                }
                                HStack{
                                    Image(systemName: "drop")
                                        .padding(10)
                                        .foregroundColor(.white)
                                        .background(Color(hex: "8F7469"))
                                        .clipShape(Circle())
                                    Text("Water:".localized())
                                    Text(recepi?.prepare ?? "")
                                    Spacer()
                                }
                                HStack{
                                    Image(systemName: "info")
                                        .padding(10)
                                        .foregroundColor(.white)
                                        .background(Color(hex: "f1d9b7"))
                                        .clipShape(Circle())
                                    Text("More info:".localized())
                                    Text(recepi?.more ?? "")
                                    Spacer()
                                }
                                VStack{
                                    Image("logoNew")
                                        .resizable()
                                        .frame(width: 200,height: 200)
                                    
                                }
                                
                            }
                            .padding()
                            
                        }
                        
                        Spacer()
                    }
                    .frame(width: size.width - 70)
                    .overlay {
                        Rectangle()
                            .stroke(.brown)
                        Color.brown.opacity(0.02)
                        
                        
                    }
                    
                }
            }
        .sheet(isPresented: $isSheet, content: {
            ShareSheet(iten: screenShot)
        })
        .toolbar {
            ToolbarItem {
                Button {
                    isSheet.toggle()
                    screenShot.removeAll()
                    screenShot.append(takeScreenshot() )



                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
              
               
                
                   
                

            }
        }
        
            

    }
       
    }
    func takeScreenshot() -> UIImage? {
        if let keyWindowScene = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene {
            
            let renderer = UIGraphicsImageRenderer(size: keyWindowScene.coordinateSpace.bounds.size)
            
            let screenshot = renderer.image { (context) in
                keyWindowScene.windows[0].layer.render(in: context.cgContext)
            }
            
            return screenshot
        }
        
        return nil
    }
   
  
}

//struct RecipeView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeView(origin: "", grind: "", temp: "", ratio: "", water: "", more: "", brew: "", image: "")
//    }
//}




struct ShareSheet : UIViewControllerRepresentable{
    
    var iten : [Any]
    
    func makeUIViewController(context: Context) ->  UIActivityViewController {
        let controller = UIActivityViewController(activityItems: iten,applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}


