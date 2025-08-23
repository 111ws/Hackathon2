//
//  remoteView.swift
//  Hackathon2
//
//  Created by AI Assistant
//

import SwiftUI

struct remoteView: View {
    var body: some View {
        ZStack {
            // 简化的背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.72, blue: 0.50),    // FFB780
                    Color(red: 0.84, green: 0.71, blue: 0.62),   // D6B69D
                    Color(red: 1.0, green: 0.76, blue: 0.58)     // FFC395
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 中间的涟漪波纹动画
            VStack {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.18)
                AdvancedGradientRippleAnimation(
                    color: .white,
                    maxSize: 180,
                    centerColor: .white,
                    edgeColor: Color.white.opacity(0.2)
                )
                .frame(width: 300, height: 300)
                
                Spacer()
            }
        }
    }
}

#Preview {
    remoteView()
}
