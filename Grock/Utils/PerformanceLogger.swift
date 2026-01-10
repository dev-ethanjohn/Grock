import Foundation
import Darwin

class PerformanceLogger {
    static let shared = PerformanceLogger()
    
    // Feature flag
    static var isEnabled: Bool = true
    
    // Thresholds
    static let durationThresholdMs: Double = 50.0
    static let memorySpikeThresholdBytes: UInt64 = 10 * 1024 * 1024 // 10 MB
    
    private let logQueue = DispatchQueue(label: "com.grock.performanceLogger", qos: .utility)
    private var fileHandle: FileHandle?
    private let fileURL: URL
    
    private init() {
        // Setup log file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("grock_performance_log.txt")
        
        setupLogFile()
    }
    
    private func setupLogFile() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        do {
            fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle?.seekToEndOfFile()
        } catch {
            print("❌ PerformanceLogger: Failed to setup log file: \(error)")
        }
    }
    
    struct TraceHandle {
        let name: String
        let context: String
        let startTime: DispatchTime
        let startMemory: UInt64
        let componentType: String
    }
    
    func startTrace(name: String, context: String = "", componentType: String = "Operation") -> TraceHandle? {
        guard PerformanceLogger.isEnabled else { return nil }
        
        return TraceHandle(
            name: name,
            context: context,
            startTime: DispatchTime.now(),
            startMemory: getMemoryUsage(),
            componentType: componentType
        )
    }
    
    func endTrace(_ handle: TraceHandle?) {
        guard let handle = handle, PerformanceLogger.isEnabled else { return }
        
        let endTime = DispatchTime.now()
        let endMemory = getMemoryUsage()
        
        let durationNano = endTime.uptimeNanoseconds - handle.startTime.uptimeNanoseconds
        let durationMs = Double(durationNano) / 1_000_000.0
        
        let memoryDiff = Int64(endMemory) - Int64(handle.startMemory)
        
        // Log to queue
        logQueue.async { [weak self] in
            self?.processLog(handle: handle, durationMs: durationMs, memoryDiff: memoryDiff, endMemory: endMemory)
        }
    }
    
    private func processLog(handle: TraceHandle, durationMs: Double, memoryDiff: Int64, endMemory: UInt64) {
        let isExpensive = durationMs > PerformanceLogger.durationThresholdMs
        let isMemorySpike = memoryDiff > Int64(PerformanceLogger.memorySpikeThresholdBytes)
        
        var severity = "INFO"
        if isExpensive || isMemorySpike {
            severity = "WARNING"
        }
        if durationMs > 500 { // Critical threshold example
            severity = "ERROR"
        }
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        let memoryDiffStr = ByteCountFormatter.string(fromByteCount: memoryDiff, countStyle: .memory)
        let endMemoryStr = ByteCountFormatter.string(fromByteCount: Int64(endMemory), countStyle: .memory)
        
        let logMessage = String(format: "[%@] [%@] [%@] %@ - Duration: %.2fms, Memory Change: %@, Total Memory: %@ | Context: %@",
                                timestamp, severity, handle.componentType, handle.name, durationMs, memoryDiffStr, endMemoryStr, handle.context)
        
        // Console Output - Always print
        print("⏱️ \(logMessage)")
        
        // File Output
        if let data = (logMessage + "\n").data(using: .utf8) {
            fileHandle?.write(data)
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    // For manual logging without trace handle
    func logEvent(name: String, context: String, durationMs: Double) {
        guard PerformanceLogger.isEnabled else { return }
        
        let handle = TraceHandle(name: name, context: context, startTime: .now(), startMemory: 0, componentType: "Event")
        // We artificially create a handle just to reuse processLog, 
        // but we need to pass the duration directly.
        // Since processLog calculates things, we might just call it directly with dummy values for memory if we don't track it here.
        
        logQueue.async { [weak self] in
            self?.processLog(handle: handle, durationMs: durationMs, memoryDiff: 0, endMemory: 0)
        }
    }
}
