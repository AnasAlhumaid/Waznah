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
    @Environment(\.managedObjectContext) var moc
    var body: some View {
        RecipeDetailSheet(
            roastery: recepi?.roastery ?? "Unknown roastery".localized(),
            method: recepi?.tools ?? "V60",
            coffee: recepi?.grain ?? "-",
            water: recepi?.prepare ?? "-",
            ratio: recepi?.ratio ?? "-",
            temperature: recepi?.temp ?? "-",
            grind: recepi?.grain ?? "-",
            notes: recepi?.more ?? "",
            steps: [],
            sourceLabel: "Local Recipe".localized()
        )
    }
    
    private var shareText: String {
        """
        Waznah Recipe
        
        Method: \(recepi?.tools ?? "-")
        Roastery: \(recepi?.roastery ?? "-")
        Grind: \(recepi?.grain ?? "-")
        Water: \(recepi?.prepare ?? "-")
        Ratio: \(recepi?.ratio ?? "-")
        Temp: \(recepi?.temp ?? "-")
        
        \(recepi?.more ?? "")
        """
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


