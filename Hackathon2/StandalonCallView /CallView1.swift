import SwiftUI
import AVFoundation
import Speech

class StandaloneCallView: ObservableObject {
    var previousTranscription: String = ""
    @Published var isVideoEnabled = true
    @Published var isFrontCamera = true
    @Published var isCallActive = true
    @Published var callDuration: TimeInterval = 0
    @Published var currentSpeechText = ""
    @Published var speechHistory: [String] = []
    @Published var isSpeaking = false
    @Published var isMuted = false
    @Published var audioPlayer: AVAudioPlayer?
    @Published var isPlayingResponse = false
    @Published var debugMessages: [String] = []
    @Published var showDebugLog = false
    @Published var audioDownloadProgress: Float = 0.0
    @Published var currentAudioDuration: TimeInterval = 0
    @Published var audioPlaybackProgress: Float = 0.0
    
    var timer: Timer?
    var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var audioEngine = AVAudioEngine()
    var speechTimer: Timer?
    var playbackTimer: Timer?
    
    // 添加VAD相关属性
    var isRecording = false
    var speechBuffer = Data()
    var silenceTimer: Timer?
    var lastSpeechTime: Date?
    var speechStartTime: Date?
    
    // VAD 配置参数
    let silenceThreshold: Float = -40.0  // 静音阈值 (dB)
    let silenceDuration: TimeInterval = 0.5  // 静音持续时间
    let minSpeechDuration: TimeInterval = 0.5  // 最小语音持续时间
    let maxSpeechDuration: TimeInterval = 10.0  // 最大语音持续时间
    
    let contactName = "Aura"
    let userId = "user_001"
    let speechSynthesizer = AVSpeechSynthesizer()
}

struct StandaloneCallViewWrapper: View {
    @StateObject   var viewModel = StandaloneCallView()
    
    var body: some View {
        StandaloneCallContent(viewModel: viewModel)
    }
}

struct StandaloneCallContent: View {
    @ObservedObject var viewModel: StandaloneCallView
    
    var body: some View {
        ZStack {
            if viewModel.isVideoEnabled {
                remoteView()
                    .ignoresSafeArea()
            } else {
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
            }
            
            VStack(spacing: 20) {
                Spacer()
                
                if !viewModel.isVideoEnabled {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 150, height: 150)
                        .overlay(
                            AdvancedGradientRippleAnimation(
                                color: viewModel.isSpeaking ? .green : .white,
                                maxSize: viewModel.isSpeaking ? 200 : 180,
                                centerColor: viewModel.isSpeaking ? Color.green : Color.white,
                                edgeColor: .clear
                            )
                            .frame(width: 300, height: 300)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.isSpeaking)
                        )
                }
                
                Text(viewModel.contactName)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .padding(.top, viewModel.isVideoEnabled ? 300 : 0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isVideoEnabled)
                Text(viewModel.timeString(from: viewModel.callDuration))
                    .font(.title2)
                    .fontWeight(.regular)
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 1)
                    .padding(.top, 8)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isVideoEnabled)

                if viewModel.isPlayingResponse {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.blue)
                        Text("Playing response...")
                            .foregroundColor(.white)
                    }
                    .animation(.easeInOut, value: viewModel.isPlayingResponse)
                }
                
                Spacer()
                
                // 通话控制按钮
                HStack(spacing: 25) {
                    // 视频开关按钮
                    Button(action: {
                        viewModel.isVideoEnabled.toggle()
                    }) {
                        Circle()
                            .fill(viewModel.isVideoEnabled ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: viewModel.isVideoEnabled ? "video.fill" : "video.slash.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    if viewModel.isVideoEnabled {
                        Button(action: {
                            viewModel.isFrontCamera.toggle()
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: "camera.rotate.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Button(action: {
                        // 扬声器功能实现
                    }) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }

                    Button(action: {
                        viewModel.endCall()
                    }) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.bottom, 50)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isVideoEnabled)
            }
            .padding()
            // 本地视频预览窗口
            if viewModel.isVideoEnabled {
                HStack {
                    SimpleCameraView()
                        .frame(width: 120, height: 160)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 0.6)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, -190)
                        .padding(.top, -330)
                }
                .zIndex(1000)
            }
            
            // 调试日志
            if viewModel.showDebugLog {
                VStack {
                    Spacer()
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.debugMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .frame(height: 200)
                    .padding()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { viewModel.showDebugLog.toggle() }) {
                        Image(systemName: "ladybug.fill")
                            .foregroundColor(.yellow)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.startCallTimer()
            viewModel.requestSpeechAuthorization()
            viewModel.setupAudioSession()
            viewModel.addDebugMessage("App started, initializing audio session")
        }
        .onDisappear {
            viewModel.stopCallTimer()
            viewModel.stopSpeechRecognition()
            viewModel.stopAudioPlayback()
            viewModel.addDebugMessage("App closed, cleaning up resources")
        }
    }
    
      var statusText: String {
        if viewModel.isMuted {
            return "Muted - \(viewModel.timeString(from: viewModel.callDuration))"
        } else {
            return viewModel.timeString(from: viewModel.callDuration)
        }
    }
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    weak var parent: StandaloneCallView?
    
    init(parent: StandaloneCallView) {
        self.parent = parent
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.parent?.addDebugMessage("🎵 Audio playback completed")
            self.parent?.isPlayingResponse = false
            self.parent?.stopPlaybackProgressTimer()
            self.parent?.restartSpeechRecognition()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.parent?.addDebugMessage("❌ Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
            self.parent?.isPlayingResponse = false
            self.parent?.restartSpeechRecognition()
        }
    }
}
#Preview {
    StandaloneCallViewWrapper()
}
