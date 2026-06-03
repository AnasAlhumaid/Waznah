//
//  TestScreen.swift
//  Waznah
//
//  Created by Anas Hamad on 12/3/23.
//

import SwiftUI

struct TestScreen: View {
    var body: some View {
        
        HStack{
            VStack{
                Text("step")
            }
            Spacer()
            VStack{
                Text("time")
            }
            
            Spacer()
            VStack{
                Text("gram")
            }
        }
        .padding()
        .frame(width: size.width - 40)
        .background(.thinMaterial)
        .cornerRadius(10)
    }
}

#Preview {
    TestScreen()
}
