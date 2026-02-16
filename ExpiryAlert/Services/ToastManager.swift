import SwiftUI
import Combine

/// Global toast (pop-up) for success and error messages. Auto-dismisses after a short delay.
final class ToastManager: ObservableObject {
    @Published var message: String?
    @Published var isError: Bool = false
    
    private var dismissTask: Task<Void, Never>?
    
    /// Show a toast. Replaces any current toast. Auto-hides after 2.5s. Call from main actor.
    @MainActor
    func show(_ text: String, isError: Bool = false) {
        dismissTask?.cancel()
        message = text
        self.isError = isError
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            self.message = nil
            self.isError = false
        }
    }
    
    @MainActor
    func dismiss() {
        dismissTask?.cancel()
        message = nil
        isError = false
    }
}
