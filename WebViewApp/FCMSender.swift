//
//  SendFCMToServer.swift
//  WebViewApp
//
//  Created by Murat Baki Yücel on 21.02.2024.
//

import Foundation
import UserNotifications

class FCMSender{
    static func sendToServer(isGranted: Bool = false){
        if(!isGranted && !checkNotificationAuthorizationStatus()){
            return
        }
        let preferences = UserDefaults.standard
        let sessionToken = preferences.string(forKey: "session-token");
        let fcmToken = preferences.string(forKey: "firebase-token")
        if(sessionToken != nil && fcmToken != nil){
            let url = URL(string: Constants.FIREBASE_TOKEN_REGISTER_URL)!
            var request = URLRequest(
                url: url
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue( "Bearer " + sessionToken!, forHTTPHeaderField: "Authorization")
            
            let json: [String: Any] = [
                "token": fcmToken!
            ];
            request.httpBody = try? JSONSerialization.data(withJSONObject: json)
            
            let task = URLSession.shared.dataTask(with: request)
            task.resume()
        }
    }
    
    static func checkNotificationAuthorizationStatus() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isAuthorized = false
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                isAuthorized = true
            default:
                isAuthorized = false
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return isAuthorized
    }
}
