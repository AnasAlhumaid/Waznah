//
//  Test.swift
//  Waznah
//
//  Created by Anas Hamad on 2/19/23.
//

import SwiftUI

struct Tag: Identifiable {
    var id = UUID()
    var name: String
}

struct ChipsView: View {
    @State private var tags = [
        Tag(name: "SwiftUI"),
        Tag(name: "iOS"),
        Tag(name: "macOS"),
        Tag(name: "WatchOS")
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("Tags:")
                ForEach(tags) { tag in
                    Chip(tag: tag.name)
                }
            }
            Divider()
            Button(action: {
                self.tags.append(Tag(name: "New Tag"))
            }) {
                Text("Add Tag")
            }
        }
        .padding()
    }
}

struct Chip: View {
    var tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue)
            .cornerRadius(16)
    }
}



struct Test_Previews: PreviewProvider {
    static var previews: some View {
        ChipsView()
    }
}
