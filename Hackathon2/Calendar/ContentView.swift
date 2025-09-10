//
//  ContentView.swift
//  Hackathon
//
//  Created by 陆氏干饭王 on 01-08-2025.
//

import SwiftUI
import AVFoundation
import CallKit
import PushKit

enum CallState {
    case idle
    case ringing
    case connected
    case ended
}

struct ContentView: View {
    @StateObject private var callManager = CallManager()
    @State private var selectedTab: Tab = .calendar
    
    enum Tab: Hashable {
        case dashboard
        case insights
        case callview
        case calendar
        case profile
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                       // 页面内容
                       Group {
                           switch selectedTab {
                           case .dashboard:
                               HomeAndMentalView()
                           case .insights:
                               HealthView()
                           case .callview:
                               StandaloneCallViewWrapper()
                           case .calendar:
                               CalendarView()
                           case .profile:
                               ProfileView()
                           }
                       }
                       .transition(.opacity)
                       .overlay(
                                   CustomTabBar(selected: $selectedTab)
                               )
                   }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
 
   
}

// MARK: - Custom Tab Bar (matches design)
private struct CustomTabBar: View {
    @Binding var selected: ContentView.Tab
    private let barHeight: CGFloat = 8
    
    var body: some View {
        VStack{
            Spacer().frame(height: UIScreen.main.bounds.height * 0.88)
        ZStack(alignment: .bottom) {
            // Background bar

            Image("tabbackground")
                   .resizable()
                  
                   .aspectRatio(contentMode: .fill)
                   .frame(width: UIScreen.main.bounds.width + 70, height: barHeight)
                   .shadow(color: Color.orange.opacity(0.35), radius: 10, x: 120, y: 35)
                   .offset(y: -19)
                   .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
            // Five equidistant items (center blue pill is a non-navigation button)
            HStack(alignment: .bottom, spacing: 0) {
                tabButton(.dashboard, title: " ", selectedImage: "house", unselectedImage: "house")
                tabButton(.insights, title: " ", selectedImage: "insightfill", unselectedImage: "insight")
                centerPillButton()
                tabButton(.calendar, title: " ", selectedImage: "calendarfill", unselectedImage: "calendar")
                tabButton(.profile, title: "", selectedImage: "profilefill", unselectedImage: "profile")
            }
          
            .padding(.bottom, 50)
            .frame(width: UIScreen.main.bounds.width + 10, height: barHeight)
        }
        .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
    }
        
    }
    
   func tabButton(_ tab: ContentView.Tab, title: String, systemImage: String? = nil, selectedImage: String? = nil, unselectedImage: String? = nil) -> some View {
        let isSelected = selected == tab
        return VStack(spacing: 2) {
            ZStack {
                if let selectedImg = selectedImage, let unselectedImg = unselectedImage {
                    Image(isSelected ? selectedImg : unselectedImg)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 10, height: 10)
                } else if let sysImage = systemImage {
                    Image(systemName: sysImage)
                        .foregroundColor(isSelected ? Color.black : Color.white.opacity(0.9))
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(isSelected ? Color.white : Color.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = tab } }
    }
   
    // Center blue pill button (does not navigate)
    private func centerPillButton() -> some View {
        ZStack {
            Image("PillButton")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .offset(y: -20)
                .shadow(color: Color.orange.opacity(0.35), radius: 8, x: 0, y: 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .contentShape(Rectangle())
    }
    }


// Temporary placeholder for Profile tab
struct ProfilePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(.white)
                .font(.system(size: 64))
            Text("Profile coming soon")
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    ContentView()
}
