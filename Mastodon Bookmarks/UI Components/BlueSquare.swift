//
//  BlueSquare.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 19/04/2025.
//

import SwiftUI

struct SmallBlueSquare: View {
    let number: Int
    var size: CGFloat = 20
    var cornerRadius: CGFloat = 6
    var backgroundColor: Color = Color.blue.opacity(0.1)
    var borderColor: Color = Color.blue.opacity(1)
    var textColor: Color = .blue
    var fontSize: CGFloat = 16
    var fontWeight: Font.Weight = .bold
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 1)
                        .shadow(color: borderColor.opacity(0.8), radius: 1, x: 0, y: 1)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                )
            
            Text("\(number)")
                .font(.system(size: fontSize, weight: fontWeight))
                .fontDesign(.rounded)
                .foregroundColor(textColor)
                .padding(4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SmallBlueSquare(number: 1)
        
        SmallBlueSquare(number: 42,
                          size: 30,
                          cornerRadius: 8,
                          backgroundColor: Color.green.opacity(0.1),
                          borderColor: Color.green.opacity(1),
                          textColor: .green,
                          fontSize: 18)
        
        SmallBlueSquare(number: 100,
                          size: 40,
                          cornerRadius: 12,
                          backgroundColor: Color.red.opacity(0.1),
                          borderColor: Color.red.opacity(0.6),
                          textColor: .red,
                          fontSize: 20)
    }
    .padding()
//    .previewLayout(.sizeThatFits)
}
