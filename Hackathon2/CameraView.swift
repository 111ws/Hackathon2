import SwiftUI
import AVFoundation

struct SimpleCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraManager.isAuthorized {
                CameraPreviewView(session: cameraManager.captureSession)
                    .onAppear {
                        Task {
                            await cameraManager.startSession()
                            await cameraManager.startAutoCapture()
                        }
                    }
                    .onDisappear {
                        cameraManager.stopSession()
                        cameraManager.stopAutoCapture()
                    }
            } else if cameraManager.authorizationStatus == .denied {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Camera permission denied")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Please allow camera access in Settings")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Requesting camera permission...")
                        .foregroundColor(.white)
                }
            }
//            
//            // 调试信息显示区域
//            VStack {
//                Spacer()
//                
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 8) {
//                        // 状态信息
//                        Group {
//                            HStack {
//                                Text("状态信息")
//                                    .font(.headline)
//                                    .foregroundColor(.yellow)
//                                Spacer()
//                                Button("清除日志") {
//                                    cameraManager.clearDebugLogs()
//                                }
//                                .font(.caption)
//                                .padding(.horizontal, 8)
//                                .padding(.vertical, 4)
//                                .background(Color.red)
//                                .foregroundColor(.white)
//                                .cornerRadius(4)
//                            }
//                            
//                            Text("授权状态: \(cameraManager.authorizationStatus.debugDescription)")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                            
//                            Text("会话运行: \(cameraManager.captureSession.isRunning ? "是" : "否")")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                            
//                            HStack {
//                                Circle()
//                                    .fill(cameraManager.isCapturing ? Color.red : Color.gray)
//                                    .frame(width: 8, height: 8)
//                                Text("正在捕获: \(cameraManager.isCapturing ? "是" : "否")")
//                                    .font(.caption)
//                                    .foregroundColor(.white)
//                            }
//                            
//                            HStack {
//                                if cameraManager.isSending {
//                                    ProgressView()
//                                        .scaleEffect(0.5)
//                                        .tint(.white)
//                                }
//                                Text("正在发送: \(cameraManager.isSending ? "是" : "否")")
//                                    .font(.caption)
//                                    .foregroundColor(.white)
//                            }
//                            
//                            Text("捕获次数: \(cameraManager.captureCount)")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                            
//                            Text("成功发送: \(cameraManager.successCount)")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                            
//                            Text("发送失败: \(cameraManager.errorCount)")
//                                .font(.caption)
//                                .foregroundColor(.red)
//                        }
//                        
//                        Divider()
//                            .background(Color.gray)
//                        
//                        // 调试日志
//                        Text("调试日志")
//                            .font(.headline)
//                            .foregroundColor(.yellow)
//                        
//                        ForEach(cameraManager.debugLogs.indices, id: \.self) { index in
//                            let log = cameraManager.debugLogs[index]
//                            HStack(alignment: .top) {
//                                Text(log.timestamp)
//                                    .font(.caption2)
//                                    .foregroundColor(.gray)
//                                    .frame(width: 60, alignment: .leading)
//                                
//                                Text(log.message)
//                                    .font(.caption2)
//                                    .foregroundColor(log.isError ? .red : .white)
//                                    .multilineTextAlignment(.leading)
//                                
//                                Spacer()
//                            }
//                        }
//                    }
//                    .padding()
//                }
//                .frame(maxHeight: 300)
//                .background(Color.black.opacity(0.8))
//                .cornerRadius(10)
//                .padding()
//            }
        }
        .onAppear {
            Task {
                await cameraManager.requestPermission()
            }
        }
    }
}

// 调试日志结构
struct DebugLog {
    let timestamp: String
    let message: String
    let isError: Bool
    
    init(_ message: String, isError: Bool = false) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        self.timestamp = formatter.string(from: Date())
        self.message = message
        self.isError = isError
    }
}

class CameraManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isCapturing = false
    @Published var isSending = false
    @Published var captureCount = 0
    @Published var successCount = 0
    @Published var errorCount = 0
    @Published var debugLogs: [DebugLog] = []
    
    // 移除@MainActor，让captureSession可以在后台线程访问
    nonisolated let captureSession = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var captureTimer: Timer?
    
    // 添加这个属性来保持delegate的强引用
    private var currentPhotoDelegate: PhotoCaptureDelegate?
    
    private let apiURL = "https://emohunter-api-6106408799.us-central1.run.app/analyze_emotion"
    
    init() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        isAuthorized = authorizationStatus == .authorized
        
        // Fix: Wrap addDebugLog calls in Task { @MainActor in }
        Task { @MainActor in
            self.addDebugLog("CameraManager initialization completed")
            self.addDebugLog("Current authorization status: \(self.authorizationStatus.debugDescription)")
        }
    }
    
    @MainActor
    private func addDebugLog(_ message: String, isError: Bool = false) {
        let log = DebugLog(message, isError: isError)
        debugLogs.append(log)
        
        // 限制日志数量，保留最新的50条
        if debugLogs.count > 50 {
            debugLogs.removeFirst(debugLogs.count - 50)
        }
        
        print("[\(log.timestamp)] \(message)")
    }
    
    @MainActor
    func clearDebugLogs() {
        debugLogs.removeAll()
        addDebugLog("Debug logs cleared")
    }
    
    @MainActor
    func requestPermission() async {
        addDebugLog("Starting camera permission request")
        
        switch authorizationStatus {
        case .notDetermined:
            addDebugLog("Permission status: Not determined, requesting permission")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            isAuthorized = granted
            
            addDebugLog("Permission request result: \(granted ? "Authorized" : "Denied")")
            
            if granted {
                await setupCamera()
            }
            
        case .authorized:
            addDebugLog("Permission status: Authorized")
            isAuthorized = true
            await setupCamera()
            
        case .denied, .restricted:
            addDebugLog("Permission status: Denied or restricted", isError: true)
            isAuthorized = false
            
        @unknown default:
            addDebugLog("Permission status: Unknown status", isError: true)
            isAuthorized = false
        }
    }
    
    private func setupCamera() async {
        await addDebugLog("Starting camera setup")
        
        let currentStatus = await MainActor.run {
            return self.authorizationStatus
        }
        
        guard currentStatus == .authorized else {
            await addDebugLog("Camera setup failed: Permission not authorized", isError: true)
            return
        }
        
        // Simplified camera setup, for preview only
        await withCheckedContinuation { continuation in
            Task.detached { [captureSession] in
                captureSession.beginConfiguration()
                
                // Clear existing inputs
                for input in captureSession.inputs {
                    captureSession.removeInput(input)
                }
                
                // Clear existing outputs (no longer need photoOutput)
                for output in captureSession.outputs {
                    captureSession.removeOutput(output)
                }
                
                // Setup front camera for preview
                guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                    captureSession.commitConfiguration()
                    continuation.resume()
                    Task { @MainActor in
                        await self.addDebugLog("Front camera unavailable", isError: true)
                    }
                    return
                }
                
                do {
                    let videoInput = try AVCaptureDeviceInput(device: frontCamera)
                    if captureSession.canAddInput(videoInput) {
                        captureSession.addInput(videoInput)
                        await MainActor.run {
                            self.videoInput = videoInput
                        }
                    } else {
                        throw NSError(domain: "CameraError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])
                    }
                } catch {
                    captureSession.commitConfiguration()
                    continuation.resume()
                    Task { @MainActor in
                        await self.addDebugLog("Camera input setup failed: \(error.localizedDescription)", isError: true)
                    }
                    return
                }
                
                captureSession.commitConfiguration()
                continuation.resume()
                
                Task { @MainActor in
                    await self.addDebugLog("Camera setup completed (preview mode only)")
                }
            }
        }
    }
    
    func startSession() async {
        guard !captureSession.isRunning else {
            await addDebugLog("Session already running")
            return
        }
        
        await addDebugLog("Starting camera session")
        
        await withCheckedContinuation { continuation in
            Task.detached { [captureSession] in
                captureSession.startRunning()
                Task { @MainActor in
                    await self.addDebugLog("Camera session started")
                }
                continuation.resume()
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        Task {
            await addDebugLog("Stopping camera session")
        }
        
        Task.detached { [captureSession] in
            captureSession.stopRunning()
            Task { @MainActor in
                await self.addDebugLog("Camera session stopped")
            }
        }
    }
    
    @MainActor
    func startAutoCapture() async {
        stopAutoCapture() // Ensure no duplicate timers
        
        addDebugLog("Starting auto capture (every 3 seconds)")
        
        captureTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task {
                await self?.capturePhoto()
            }
        }
    }
    
    @MainActor
    func stopAutoCapture() {
        if captureTimer != nil {
            addDebugLog("Stopping auto capture")
            captureTimer?.invalidate()
            captureTimer = nil
        }
    }
    
    @MainActor
    private func capturePhoto() async {
        guard captureSession.isRunning,
              !isCapturing else {
            if !captureSession.isRunning {
                addDebugLog("Capture failed: Session not running", isError: true)
            } else if isCapturing {
                addDebugLog("Skipping capture: Previous capture still in progress")
            }
            return
        }
        
        isCapturing = true
        addDebugLog("Starting screen capture")
        
        // Use screenshot instead of camera photo
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            addDebugLog("Failed to get window", isError: true)
            isCapturing = false
            return
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let screenshot = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        
        // Convert screenshot to JPEG data
        guard let imageData = screenshot.jpegData(compressionQuality: 0.8) else {
            addDebugLog("Image data conversion failed", isError: true)
            isCapturing = false
            return
        }
        
        addDebugLog("Screenshot completed, starting API send (size: \(imageData.count) bytes)")
        await sendPhotoToAPI(imageData: imageData)
        
        // Reset capture state
        isCapturing = false
        captureCount += 1
        addDebugLog("Screenshot process completed, total: \(captureCount)")
    }
    
    @MainActor
    private func sendPhotoToAPI(imageData: Data) async {
        guard let url = URL(string: apiURL) else {
            addDebugLog("Invalid API URL", isError: true)
            return
        }
        
        isSending = true
        addDebugLog("Starting photo send to API (size: \(imageData.count) bytes)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        // Create multipart/form-data request
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        addDebugLog("Request body size: \(body.count) bytes")
        
        do {
            let startTime = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                addDebugLog("API response status code: \(statusCode) (duration: \(String(format: "%.2f", duration)) seconds)")
                
                if statusCode == 200 {
                    successCount += 1
                    addDebugLog("✅ Send successful")
                } else {
                    errorCount += 1
                    addDebugLog("❌ Server error: \(statusCode)", isError: true)
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    let truncatedResponse = responseString.count > 200 ? 
                        String(responseString.prefix(200)) + "..." : responseString
                    addDebugLog("API response content: \(truncatedResponse)")
                }
            }
        } catch {
            errorCount += 1
            addDebugLog("❌ Network request failed: \(error.localizedDescription)", isError: true)
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    addDebugLog("Error details: Request timeout", isError: true)
                case .notConnectedToInternet:
                    addDebugLog("Error details: No internet connection", isError: true)
                case .cannotFindHost:
                    addDebugLog("Error details: Cannot find host", isError: true)
                default:
                    addDebugLog("Error details: \(urlError.localizedDescription)", isError: true)
                }
            }
        }
        
        isSending = false
    }
}

// Photo capture delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data) -> Void
    
    init(completion: @escaping (Data) -> Void) {
        self.completion = completion
        super.init()
        print("PhotoCaptureDelegate created")
    }
    
    deinit {
        print("PhotoCaptureDelegate released")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("photoOutput didFinishProcessingPhoto called")
        
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Cannot get photo data")
            return
        }
        
        print("Photo data retrieved successfully, size: \(imageData.count) bytes")
        completion(imageData)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // 存储预览层引用
        view.layer.setValue(previewLayer, forKey: "previewLayer")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.value(forKey: "previewLayer") as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

// Extend AVAuthorizationStatus to provide better debug description
extension AVAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown(\(rawValue))"
        }
    }
}

#Preview {
    SimpleCameraView()
}
