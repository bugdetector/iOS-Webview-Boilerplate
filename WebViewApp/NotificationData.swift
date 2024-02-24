import Combine

class NotificationData: ObservableObject {
    @Published var notificationUrl: String?
    
    static let shared = NotificationData()
    
    private init() {}
}
