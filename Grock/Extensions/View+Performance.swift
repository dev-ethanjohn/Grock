import SwiftUI

struct PerformanceTrackingModifier: ViewModifier {
    let name: String
    let context: String
    
    func body(content: Content) -> some View {
        // Log that a view update is being processed
        // Note: This only captures the body evaluation phase, not layout/rendering
        let _ = PerformanceLogger.shared.logEvent(name: name, context: context, durationMs: 0)
        return content
    }
}

extension View {
    func trackPerformance(name: String, context: String = "") -> some View {
        modifier(PerformanceTrackingModifier(name: name, context: context))
    }
}

// Helper to time blocks of code
func measurePerformance<T>(name: String, context: String = "", operation: () -> T) -> T {
    let handle = PerformanceLogger.shared.startTrace(name: name, context: context)
    let result = operation()
    PerformanceLogger.shared.endTrace(handle)
    return result
}
