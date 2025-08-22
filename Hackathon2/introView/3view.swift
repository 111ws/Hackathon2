//
//  3view.swift
//  Aura calling
//
//  Created by Macbook pro on 2025/8/20.
//
import SwiftUI

struct AView: View {
    @State private var navigateToNext = false
    @State private var glow = false
    
    var body: some View {
        NavigationStack {
            ZStack{
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.72, blue: 0.50),
                        Color(red: 0.84, green: 0.71, blue: 0.62),
                        Color(red: 1.0, green: 0.76, blue: 0.58)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height:350)
                  
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 150, height: 150)
                        .overlay(
                            AdvancedGradientRippleAnimation(
                                color: Color.white,
                                maxSize: 180,
                                centerColor: Color.white,
                                edgeColor: .clear
                            )
                            .frame(width: 300, height: 300)
                        )
                    Spacer().frame(height: 30)

                    Text("Aura")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    
                    Spacer().frame(height: 450)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                navigateToNext = true
            }
            .navigationDestination(isPresented: $navigateToNext) {
                PrivacyToggleView()
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct Aiew_Previews: PreviewProvider {
    static var previews: some View {
        AView()
    }
}


