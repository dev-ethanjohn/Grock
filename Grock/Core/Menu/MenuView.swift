//
//  MenuView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/7/25.
//

import SwiftUI

struct MenuView: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack(alignment: .bottom) {
                    HStack {
                        Image("grock_logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                        
                        Text("Grock")
                            .font(.headline)
                            .bold()
                    }
                    
                    Spacer()
                }
                .frame(height: 100, alignment: .bottom)
                .padding(.horizontal, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(MenuItem.userSettingsMenuItems) { item in
                            MenuRow(item: item)
//                            Divider()
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        ForEach(MenuItem.feedbackMenuItems) { item in
                            MenuRow(item: item)
//                            Divider()
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        ForEach(MenuItem.infoMenuItems) { item in
                            MenuRow(item: item)
//                            Divider()
                        }
                    }
                    .padding(24)
                }
                .frame(width: 300, alignment: .leading)
            }
            .frame(width: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuRow: View {
    let item: MenuItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.iconName)
                .foregroundColor(Color(hex: "999"))
                .frame(width: 24, height: 24, alignment: .leading)
            
            Text(item.title)
                .font(.system(size: 16))
                .fontWeight(.medium)
                .foregroundColor(Color.black)
                .frame(alignment: .leading)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .onTapGesture {
        }
    }
}


#Preview {
    MenuView()
}
