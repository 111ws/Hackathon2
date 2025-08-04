//
//  IdleView.swift
//  Hackathon2
//
//  Created by 陆氏干饭王 on 03-08-2025.
//


//
//  IdleViewHandle.swift
//  Hackathon
//
//  Created by 陆氏干饭王 on 02-08-2025.
//
import SwiftUI
import AVFoundation
import CallKit
import PushKit

// 空闲状态视图
struct IdleView: View {
    let callManager: CallManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "phone.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
            Text("Everything is okay...")
                .font(.title2)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}
