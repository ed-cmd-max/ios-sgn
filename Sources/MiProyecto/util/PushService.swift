#if canImport(UserNotifications)
import UserNotifications

enum PushService {
    static func requestAuthorization() async -> Bool {
        await NotificationHelper.requestPermission()
    }
}
#endif