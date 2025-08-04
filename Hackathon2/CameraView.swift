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
                    
                    Text("摄像头权限被拒绝")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("请在设置中允许访问摄像头")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button("打开设置") {
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
                    
                    Text("正在请求摄像头权限...")
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
            self.addDebugLog("CameraManager 初始化完成")
            self.addDebugLog("当前授权状态: \(self.authorizationStatus.debugDescription)")
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
        addDebugLog("调试日志已清除")
    }
    
    @MainActor
    func requestPermission() async {
        addDebugLog("开始请求摄像头权限")
        
        switch authorizationStatus {
        case .notDetermined:
            addDebugLog("权限状态：未确定，正在请求权限")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            isAuthorized = granted
            
            addDebugLog("权限请求结果: \(granted ? "已授权" : "被拒绝")")
            
            if granted {
                await setupCamera()
            }
            
        case .authorized:
            addDebugLog("权限状态：已授权")
            isAuthorized = true
            await setupCamera()
            
        case .denied, .restricted:
            addDebugLog("权限状态：被拒绝或受限", isError: true)
            isAuthorized = false
            
        @unknown default:
            addDebugLog("权限状态：未知状态", isError: true)
            isAuthorized = false
        }
    }
    
    private func setupCamera() async {
        await addDebugLog("开始设置摄像头")
        
        let currentStatus = await MainActor.run {
            return self.authorizationStatus
        }
        
        guard currentStatus == .authorized else {
            await addDebugLog("摄像头设置失败：权限未授权", isError: true)
            return
        }
        
        // 简化相机设置，只用于预览
        await withCheckedContinuation { continuation in
            Task.detached { [captureSession] in
                captureSession.beginConfiguration()
                
                // 清除现有输入
                for input in captureSession.inputs {
                    captureSession.removeInput(input)
                }
                
                // 清除现有输出（不再需要photoOutput）
                for output in captureSession.outputs {
                    captureSession.removeOutput(output)
                }
                
                // 设置前置摄像头用于预览
                guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                    captureSession.commitConfiguration()
                    continuation.resume()
                    Task { @MainActor in
                        await self.addDebugLog("前置摄像头不可用", isError: true)
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
                        throw NSError(domain: "CameraError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法添加视频输入"])
                    }
                } catch {
                    captureSession.commitConfiguration()
                    continuation.resume()
                    Task { @MainActor in
                        await self.addDebugLog("摄像头输入设置失败: \(error.localizedDescription)", isError: true)
                    }
                    return
                }
                
                captureSession.commitConfiguration()
                continuation.resume()
                
                Task { @MainActor in
                    await self.addDebugLog("摄像头设置完成（仅预览模式）")
                }
            }
        }
    }
    
    func startSession() async {
        guard !captureSession.isRunning else {
            await addDebugLog("会话已在运行中")
            return
        }
        
        await addDebugLog("启动摄像头会话")
        
        await withCheckedContinuation { continuation in
            Task.detached { [captureSession] in
                captureSession.startRunning()
                Task { @MainActor in
                    await self.addDebugLog("摄像头会话已启动")
                }
                continuation.resume()
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        Task {
            await addDebugLog("停止摄像头会话")
        }
        
        Task.detached { [captureSession] in
            captureSession.stopRunning()
            Task { @MainActor in
                await self.addDebugLog("摄像头会话已停止")
            }
        }
    }
    
    @MainActor
    func startAutoCapture() async {
        stopAutoCapture() // 确保没有重复的定时器
        
        addDebugLog("启动自动捕获（每3秒）")
        
        captureTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task {
                await self?.capturePhoto()
            }
        }
    }
    
    @MainActor
    func stopAutoCapture() {
        if captureTimer != nil {
            addDebugLog("停止自动捕获")
            captureTimer?.invalidate()
            captureTimer = nil
        }
    }
    
    @MainActor
    private func capturePhoto() async {
        guard captureSession.isRunning,
              !isCapturing else {
            if !captureSession.isRunning {
                addDebugLog("捕获失败：会话未运行", isError: true)
            } else if isCapturing {
                addDebugLog("跳过捕获：上一次捕获仍在进行中")
            }
            return
        }
        
        isCapturing = true
        addDebugLog("开始截取屏幕图像")
        
        // 使用屏幕截图代替相机拍照
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            addDebugLog("获取窗口失败", isError: true)
            isCapturing = false
            return
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let screenshot = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        
        // 将截图转换为JPEG数据
        guard let imageData = screenshot.jpegData(compressionQuality: 0.8) else {
            addDebugLog("图像数据转换失败", isError: true)
            isCapturing = false
            return
        }
        
        addDebugLog("屏幕截图完成，开始发送到API (大小: \(imageData.count) 字节)")
        await sendPhotoToAPI(imageData: imageData)
        
        // 重置捕获状态
        isCapturing = false
        captureCount += 1
        addDebugLog("截图流程完成，总计: \(captureCount)")
    }
    
    @MainActor
    private func sendPhotoToAPI(imageData: Data) async {
        guard let url = URL(string: apiURL) else {
            addDebugLog("API URL无效", isError: true)
            return
        }
        
        isSending = true
        addDebugLog("开始发送照片到API (大小: \(imageData.count) 字节)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        // 创建multipart/form-data请求
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加图片数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        addDebugLog("请求体大小: \(body.count) 字节")
        
        do {
            let startTime = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                addDebugLog("API响应状态码: \(statusCode) (耗时: \(String(format: "%.2f", duration))秒)")
                
                if statusCode == 200 {
                    successCount += 1
                    addDebugLog("✅ 发送成功")
                } else {
                    errorCount += 1
                    addDebugLog("❌ 服务器错误: \(statusCode)", isError: true)
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    let truncatedResponse = responseString.count > 200 ? 
                        String(responseString.prefix(200)) + "..." : responseString
                    addDebugLog("API响应内容: \(truncatedResponse)")
                }
            }
        } catch {
            errorCount += 1
            addDebugLog("❌ 网络请求失败: \(error.localizedDescription)", isError: true)
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    addDebugLog("错误详情: 请求超时", isError: true)
                case .notConnectedToInternet:
                    addDebugLog("错误详情: 无网络连接", isError: true)
                case .cannotFindHost:
                    addDebugLog("错误详情: 无法找到主机", isError: true)
                default:
                    addDebugLog("错误详情: \(urlError.localizedDescription)", isError: true)
                }
            }
        }
        
        isSending = false
    }
}

// 照片捕获代理
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data) -> Void
    
    init(completion: @escaping (Data) -> Void) {
        self.completion = completion
        super.init()
        print("PhotoCaptureDelegate 已创建")
    }
    
    deinit {
        print("PhotoCaptureDelegate 已释放")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("photoOutput didFinishProcessingPhoto 被调用")
        
        if let error = error {
            print("照片捕获错误: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("无法获取照片数据")
            return
        }
        
        print("照片数据获取成功，大小: \(imageData.count) 字节")
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

// 扩展AVAuthorizationStatus以提供更好的调试描述
extension AVAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined:
            return "未确定"
        case .restricted:
            return "受限"
        case .denied:
            return "被拒绝"
        case .authorized:
            return "已授权"
        @unknown default:
            return "未知(\(rawValue))"
        }
    }
}

#Preview {
    SimpleCameraView()
}
