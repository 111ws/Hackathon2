//
//  HealthView.swift
//  Hackathon2
//
//  Created by AI Assistant
//

import SwiftUI

struct HealthData {
    let heartRate: Int
    let heartRateVariability: Double
    let stressLevel: Double
    let activityLevel: String
    let sleepQuality: Double
}

struct HealthView: View {
    let healthData = HealthData(
        heartRate: 72,
        heartRateVariability: 45.2,
        stressLevel: 0.3,
        activityLevel: "moderate",
        sleepQuality: 0.8
    )
    
    var body: some View {
        ZStack {
            WarmTheme.primaryBackground.ignoresSafeArea()
                            VStack(spacing: 0) {
                        Text("My Insights")
                            .font(.custom("Urbanist-ExtraBold", size: 40))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 72/255, green: 52/255, blue: 34/255))
                    .padding(.top, 10)
                    .frame(maxWidth:.infinity,alignment: .leading)
                    .padding(.horizontal,50)
                                ScrollView(.horizontal, showsIndicators: true) {
                                    LazyHStack(spacing: -25) {
                                        ForEach(["card1", "card2", "card3"], id: \.self) { imageName in
                                            Image(imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 210, height: 280)
                                            .clipped()
                                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                                .offset(x: imageName == "card1" ? 15 : 0)
                                        }
                                        //.border(Color.red, width: 1)
                                        .frame(width: 210, height: 280)
                                    }
                                }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 300)
                       .padding(.top,-5)
                       Spacer(minLength: 0)
                                    HStack {
                                            Text("My Achievements")
                                            .font(.custom("Urbanist-ExtraBold", size: 24))
                                                .fontWeight(.bold)
                                                .foregroundColor(Color(red: 72/255, green: 52/255, blue: 34/255))
                                                          
                                        NavigationLink(destination: ProfileView()) {
                                                Image(systemName: "chevron.right")
                                                .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(Color(red: 72/255, green: 52/255, blue: 34/255))
                                                }
                                                      }
                                                      .padding(.horizontal, -157)
                                                      .padding(.top, -450)
                                                  
                }
            
        }
    }
}


#Preview {
    HealthView()
}




