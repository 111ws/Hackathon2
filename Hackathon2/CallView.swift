
import SwiftUI
import AVFoundation
import CallKit
import PushKit

struct CallView: View {
    @ObservedObject var callManager: CallManager
    @State private var isVideoEnabled = true
    @State private var isFrontCamera = true
    
    var body: some View {
        ZStack {
            // 视频背景层
            if callManager.callState == .connected && isVideoEnabled {
                // 远程视频视图（全屏背景）
                RemoteVideoView()
                    .ignoresSafeArea()
                
                // 本地视频预览（小窗口）
                VStack {
                    HStack {
                        Spacer()
                        LocalVideoPreview(isFrontCamera: $isFrontCamera)
                            .frame(width: 120, height: 160)
                            .cornerRadius(12)
                            .padding(.trailing, 20)
                            .padding(.top, 50)
                    }
                    Spacer()
                }
            } else {
                // 音频通话背景
                Color.black.ignoresSafeArea()
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                if callManager.callState != .connected || !isVideoEnabled {
                    // 联系人头像（仅在音频模式或非连接状态显示）
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 150, height: 150)
                        .overlay(
                            AdvancedGradientRippleAnimation(
                                color: .white,
                                maxSize: 180,
                                centerColor: Color.white,
                                edgeColor: .clear
                            )
                            .frame(width: 300, height: 300)
                        )
                }
                
                // 联系人姓名
                Text(callManager.contactName)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                
                // 通话状态
                Text(statusText)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                
                Spacer()
                
                // 通话控制按钮
                HStack(spacing: 40) {
                    if callManager.callState == .ringing {
                        // 接听按钮
                        Button(action: {
                            callManager.answerCall()
                        }) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    if callManager.callState == .connected {
                        // 视频开关按钮
                        Button(action: {
                            isVideoEnabled.toggle()
                        }) {
                            Circle()
                                .fill(isVideoEnabled ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: isVideoEnabled ? "video.fill" : "video.slash.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // 摄像头切换按钮
                        if isVideoEnabled {
                            Button(action: {
                                isFrontCamera.toggle()
                            }) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "camera.rotate.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        // 静音按钮
                        Button(action: {
                            // 静音功能
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "mic.slash.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // 挂断按钮
                    Button(action: {
                        callManager.endCall()
                    }) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
    }
    
    private var statusText: String {
        switch callManager.callState {
        case .idle:
            return "空闲"
        case .ringing:
            return "You look lonely , I can fix that..."
        case .connected:
            return callManager.formatDuration(callManager.callDuration)
        case .ended:
            return "通话结束"
        }
    }
}

// 远程视频视图
struct RemoteVideoView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        // 这里应该集成实际的视频渲染视图
        // 例如：WebRTC 的 RTCMTLVideoView 或其他视频框架的视图
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新视频视图
    }
}

// 本地视频预览
struct LocalVideoPreview: UIViewRepresentable {
    @Binding var isFrontCamera: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .darkGray
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        
        // 这里应该集成摄像头预览
        // 例如：AVCaptureVideoPreviewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 根据 isFrontCamera 切换摄像头
    }
}
