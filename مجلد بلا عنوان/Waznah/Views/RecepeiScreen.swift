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
    @State private var deleteErrorMessage = ""
    @State private var showDeleteError = false
    private let cloudManager = FirestoreManager()
    private let syncManager = LocalRecipeSyncManager.shared
    @FetchRequest(entity: Recepie.entity(), sortDescriptors: [])
       var singRecepisResults: FetchedResults<Recepie>
    
    
    @State  var arrayRecepie: [Recepie] = []
    var body: some View {
        NavigationView{
            ZStack {
                if recepisResults.isEmpty {
                    RecipeEmptyState(
                        systemImage: "leaf.fill",
                        title: "No saved recipes".localized(),
                        message: "Save your favorite brew recipes here for quick access.".localized(),
                        buttonTitle: "Add Recipe".localized()
                    ) {
                        showSheet.toggle()
                    }
                }
                
                VStack{
                    List{
                        Section{
                            ForEach(recepisResults,id: \.self){ rec in
                                if rec.roastery != "" && rec.tools != ""{
                                    
                                    RecepeiCard(recepi: rec, ShowSheet: $showDetailSheet)
                                    
                                }
                                
                            }
                            .onDelete(perform: deleteItem)
                        }
                    }
                    .listStyle(.plain)
                    .background(.clear)
                    .scrollContentBackground(.hidden)
                    .opacity(recepisResults.isEmpty ? 0 : 1)
                    
               
                 
                    
                   
                  
                    
                }
            }
            
              
            
            .sheet(isPresented: $showSheet, content: {
                RecepieDetail( showSheet: $showSheet)
            })
            .navigationTitle("Recipes".localized())
            .alert("Could not delete recipe".localized(), isPresented: $showDeleteError) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
            .onAppear {
                syncManager.refresh(in: viewContext)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem{
                    Button {
                        showSheet.toggle()
                            
                    } label: {
                        Image(systemName: "plus.app")
                            .foregroundColor(Color("Color-2"))
                    }

                }
            }
        }
      
    }
    
    func deleteItem(offsets: IndexSet) {
        for offset in offsets {
            let reci = recepisResults[offset]
            let localId = reci.stableLocalID.uuidString
            let communityId = reci.value(forKey: "cloudRecipeId") as? String
            
            deleteLocalRecipe(reci)
            
            syncManager.deletePrivateRecipe(localId: localId)
            
            if let communityId, !communityId.isEmpty {
                cloudManager.deleteRecipe(id: communityId) { _ in }
            }
        }
    }
    
    private func deleteLocalRecipe(_ recipe: Recepie) {
        viewContext.delete(recipe)
        
        do {
            try viewContext.save()
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
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
    @State private var showRecipe = false
   
    var body: some View {
        PolishedRecipePreviewCard(
            roastery: recepi.roastery ?? "Unknown roastery".localized(),
            method: recepi.tools ?? "V60",
            coffee: recepi.grain ?? "-",
            water: recepi.prepare ?? "-",
            ratio: recepi.ratio ?? "-",
            temperature: recepi.temp ?? "-",
            grain: "",
            actionTitle: "View".localized()
        ) {
            showRecipe.toggle()
        }
        .sheet(isPresented: $showRecipe) {
            RecipeView(recepi: recepi)
        }
    }
}
