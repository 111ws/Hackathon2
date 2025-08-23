//
//  HomeCalendarQuickView.swift
//  Hackathon2
//
//  Created by AI Assistant
//

import SwiftUI

struct HomeCalendarQuickView: View {
    
    @State private var currentScreen = 0
    @Namespace private var animation
    
    var body: some View {
        NavigationStack{
        ZStack {
            Color.clear.ignoresSafeArea()
            
            if currentScreen == 0 {
                Image("Home & Calendar")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
            } else if currentScreen == 1{
                Image("My Insights")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
            }else if currentScreen == 2{
                Image("Badges & Achievements")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
            }else if currentScreen == 3{
                Image("My Insights")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
            }else{
                Image("My Profile")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
        }
    }
        .navigationBarBackButtonHidden()
        .onTapGesture {

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                currentScreen = (currentScreen + 1)%5
            }
        }
    }
}

#Preview {
    HomeCalendarQuickView()
}
