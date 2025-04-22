import Foundation
import CryptoKit
import SwiftUI
import WebKit

/**
 # VerifyMyAge Integration Guide
 
 This file contains everything needed to integrate age verification into your iOS app.
 
 ## Integration Steps
 
 1. Add this file to your project
 2. Use the static functions to start verification
 3. Display the verification UI using VMWebView
 4. Check verification status after user completes the flow
 
 ## Basic Usage Example
 
 ```swift
 // Start verification
 VMAge.startVerification { result in
     switch result {
     case .success(let response):
         // Show WebView with the verification URL
         if let url = URL(string: response.verificationURL) {
             // Present WebView that loads this URL
             
             // Store the verification ID for later status check
             let verificationID = response.verificationID
         }
     case .failure(let error):
         // Show error to user
         print("Verification error: \(error.localizedDescription)")
     }
 }
 
 // Later, after user completes verification in WebView,
 // check the verification status:
 VMAge.checkStatus(verificationID: "verification-id") { result in
     switch result {
     case .success(let status):
         if status == .approved {
             // User was successfully verified
             print("Verification approved!")
         } else {
             // Handle other statuses
             print("Verification status: \(status.rawValue)")
         }
     case .failure(let error):
         print("Failed to check status: \(error.localizedDescription)")
     }
 }
 ```
 */
class VMAge {
    // MARK: - Error Types
    
    /// Errors that can occur during verification
    enum Error: Swift.Error, LocalizedDescription {
        /// Missing or invalid API credentials
        case invalidCredentials
        
        /// Network or API request failed
        case requestFailed(String)
        
        /// Server returned an error
        case serverError(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidCredentials:
                return "Invalid API credentials. Check your API_KEY and API_SECRET in Info.plist"
            case .requestFailed(let reason):
                return "Verification request failed: \(reason)"
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }
    }
    
    // MARK: - Verification Status
    
    /// Status of the verification process
    enum VerificationStatus: String {
        /// The user has not started the verification process
        case started
        
        /// The user has started but not finished the verification process
        case pending
        
        /// The user has completed the verification process successfully
        case approved
        
        /// The user has not completed the verification process successfully
        case failed
        
        /// 5 days have elapsed since the verification link was generated
        case expired
        
        /// Unknown status
        case unknown
        
        /// Get a user-friendly description of the status
        var description: String {
            switch self {
            case .started:
                return "Verification not started"
            case .pending:
                return "Verification in progress"
            case .approved:
                return "Verification approved"
            case .failed:
                return "Verification failed"
            case .expired:
                return "Verification link expired"
            case .unknown:
                return "Unknown status"
            }
        }
        
        /// Is this a terminal status?
        var isTerminal: Bool {
            return self == .approved || self == .failed || self == .expired
        }
        
        /// Is this a success status?
        var isSuccess: Bool {
            return self == .approved
        }
    }
    
    // MARK: - Configuration Access
    
    /// API base URL
    private static let baseURL = "https://oauth.verifymyage.com"
    
    /// Auth start endpoint
    private static let authStartEndpoint = "/v2/auth/start"
    
    /// Status check endpoint
    private static func statusEndpoint(for id: String) -> String {
        return "/v2/verification/\(id)/status"
    }
    
    /// Get API key from environment
    static var apiKey: String {
        return getEnvValue(for: "API_KEY") ?? ""
    }
    
    /// Get API secret from environment
    static var apiSecret: String {
        return getEnvValue(for: "API_SECRET") ?? ""
    }
    
    /// Get country from environment (defaults to "gb")
    static var country: String {
        return getEnvValue(for: "COUNTRY") ?? "gb"
    }
    
    /// Get webhook URL from environment
    static var webhook: String {
        return getEnvValue(for: "WEBHOOK") ?? ""
    }
    
    /// Get redirect URL from environment
    static var redirectURL: String {
        return getEnvValue(for: "REDIRECT_URL") ?? ""
    }
    
    // MARK: - Response Model
    
    /// Response from verification start
    struct Response {
        /// URL for the verification process
        let verificationURL: String
        
        /// Unique identifier for this verification
        let verificationID: String
        
        /// Initial status (will always be "started")
        let status: VerificationStatus
    }
    
    // MARK: - Public API
    
    /**
     Start a verification process with default parameters
     
     This uses the country and webhook from your Info.plist file.
     
     - Parameter completion: Callback with verification URL or error
     
     Example:
     ```
     VMAge.startVerification { result in
         if case .success(let response) = result {
             // Show verification URL in WebView
             // Save response.verificationID for later status checks
         }
     }
     ```
     */
    static func startVerification(completion: @escaping (Result<Response, Error>) -> Void) {
        // Validate required parameters
        if webhook.isEmpty {
            completion(.failure(.invalidCredentials))
            return
        }
        
        // Create parameters
        let params: [String: String] = [
            "country": country,
            "webhook": webhook
        ]
        
        // Add redirect URL if available
        if !redirectURL.isEmpty {
            var mutableParams = params
            mutableParams["redirect_url"] = redirectURL
            verify(params: mutableParams, completion: completion)
        } else {
            verify(params: params, completion: completion)
        }
    }
    
    /**
     Start a verification with custom parameters
     
     - Parameters:
       - params: Custom verification parameters
       - completion: Callback with verification URL or error
     
     Example with custom parameters:
     ```
     let params: [String: String] = [
         "country": "us",
         "webhook": "https://myapp.com/webhook",
         "redirect_url": "https://myapp.com/callback",
         "method": "selfie"
     ]
     
     VMAge.verify(params: params) { result in
         // Handle result
     }
     ```
     */
    static func verify(params: [String: Any], completion: @escaping (Result<Response, Error>) -> Void) {
        // Validate credentials
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            completion(.failure(.invalidCredentials))
            return
        }
        
        // Create URL
        let endpoint = baseURL + authStartEndpoint
        guard let url = URL(string: endpoint) else {
            completion(.failure(.requestFailed("Invalid API URL")))
            return
        }
        
        // Create request body
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: params)
        } catch {
            completion(.failure(.requestFailed("Failed to create request: \(error.localizedDescription)")))
            return
        }
        
        // Get JSON string for HMAC
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            completion(.failure(.requestFailed("Failed to encode request body")))
            return
        }
        
        // Generate HMAC
        guard let hmac = generateHMAC(secret: apiSecret, data: jsonString) else {
            completion(.failure(.requestFailed("Failed to generate security signature")))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        // Add headers
        request.addValue("hmac \(apiKey):\(hmac)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("hmac \(apiKey):\(hmac)")
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.requestFailed(error.localizedDescription)))
                }
                return
            }
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print(httpResponse.statusCode)
                
                DispatchQueue.main.async {
                    completion(.failure(.serverError("HTTP \(httpResponse.statusCode)")))
                }
                return
            }
            
            // Ensure we have data
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.serverError("No data received")))
                }
                return
            }
            
            // Parse response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let verificationURL = json["start_verification_url"] as? String,
               let verificationID = json["verification_id"] as? String,
               let statusString = json["verification_status"] as? String {
                
                // Parse status
                let status = VerificationStatus(rawValue: statusString) ?? .unknown
                
                let response = Response(
                    verificationURL: verificationURL,
                    verificationID: verificationID,
                    status: status
                )
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let error = json["error"] as? String {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(error)))
                }
            } else {
                DispatchQueue.main.async {
                    // Try to get raw response as string for debugging
                    let responseStr = String(data: data, encoding: .utf8) ?? "Unknown format"
                    completion(.failure(.serverError("Invalid response format: \(responseStr)")))
                }
            }
        }.resume()
    }
    
    /**
     Check the current status of a verification
     
     - Parameters:
       - verificationID: The ID of the verification to check
       - completion: Callback with the current status or error
     
     Example:
     ```
     VMAge.checkStatus(verificationID: "verification-id") { result in
         switch result {
         case .success(let status):
             if status == .approved {
                 // User is verified
             } else if status == .pending {
                 // Verification still in progress
             } else {
                 // Handle other statuses
             }
         case .failure(let error):
             print("Status check failed: \(error.localizedDescription)")
         }
     }
     ```
     */
    static func checkStatus(verificationID: String, completion: @escaping (Result<VerificationStatus, Error>) -> Void) {
        // Validate credentials
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            completion(.failure(.invalidCredentials))
            return
        }
        
        // Create URL and request URI (path + query)
        let requestUri = statusEndpoint(for: verificationID)
        let endpoint = baseURL + requestUri
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.requestFailed("Invalid API URL")))
            return
        }
        
        print(requestUri)
        // Generate HMAC using the request URI
        guard let hmac = generateHMAC(secret: apiSecret, data: requestUri) else {
            completion(.failure(.requestFailed("Failed to generate security signature")))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("hmac \(apiKey):\(hmac)")
        // Add headers
        request.addValue("hmac \(apiKey):\(hmac)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.requestFailed(error.localizedDescription)))
                }
                return
            }
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print(httpResponse.statusCode)
                DispatchQueue.main.async {
                    completion(.failure(.serverError("HTTP \(httpResponse.statusCode)")))
                }
                return
            }
            
            // Ensure we have data
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.serverError("No data received")))
                }
                return
            }
            
            // Parse response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let statusString = json["verification_status"] as? String {
                
                // Parse status
                let status = VerificationStatus(rawValue: statusString) ?? .unknown
                
                DispatchQueue.main.async {
                    completion(.success(status))
                }
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let error = json["error"] as? String {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(error)))
                }
            } else {
                DispatchQueue.main.async {
                    // Try to get raw response as string for debugging
                    let responseStr = String(data: data, encoding: .utf8) ?? "Unknown format"
                    completion(.failure(.serverError("Invalid response format: \(responseStr)")))
                }
            }
        }.resume()
    }
    
    /**
     Check if a URL is a verification redirect URL
     
     This automatically handles checking the URL against your redirect_url
     and detects when the verification process has completed.
     
     - Parameters:
       - url: URL to check
       - callback: Returns true if it's a redirect URL
     
     Example:
     ```
     // In your WebView navigation delegate
     VMAge.isRedirectURL(navigationAction.request.url) { isRedirect in
         if isRedirect {
             // Verification flow has completed in the WebView
             // Time to check the status using the verification ID
             return false // Cancel navigation
         }
         return true // Continue navigation for other URLs
     }
     ```
     */
    static func isRedirectURL(_ url: URL, callback: (Bool) -> Bool) -> Bool {
        // If no redirect URL configured, can't check
        if redirectURL.isEmpty {
            return callback(false)
        }
        
        // Check if URL starts with our redirect URL
        if url.absoluteString.starts(with: redirectURL) {
            // This is a redirect URL - the verification flow in the WebView is complete
            return callback(true)
        } else {
            // Not a redirect URL
            return callback(false)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Generate HMAC for API request
    private static func generateHMAC(secret: String, data: String) -> String? {
        guard let secretData = secret.data(using: .utf8),
              let messageData = data.data(using: .utf8) else {
            return nil
        }
        
        // Create HMAC using CryptoKit
        let key = SymmetricKey(data: secretData)
        let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: key)
        
        // Convert to hex string
        let hexString = signature.compactMap { String(format: "%02x", $0) }.joined()
        
        return hexString
    }

    
    /// Get a value from the info.plist file
    private static func getEnvValue(for key: String) -> String? {
        return Bundle.main.infoDictionary?[key] as? String
    }
}

/// WebView for displaying verification UI
struct VMWebView: UIViewRepresentable {
    /// URL to load in the WebView
    let url: URL
    
    /// Callback for when verification process completes
    var onComplete: (() -> Void)?
    
    /// Create WebView
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Add this if targeting iOS 14.3+
        if #available(iOS 14.3, *) {
            webView.configuration.limitsNavigationsToAppBoundDomains = true
            webView.configuration.preferences.isElementFullscreenEnabled = true
        }
        
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    /// Load URL
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
    
    /// Create coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// WebView coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: VMWebView
        
        init(_ parent: VMWebView) {
            self.parent = parent
        }
        
        /// Handle navigation
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.scheme == "gbanonymeage"{
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:]) { success in
                            if success {
                                print("Anonymage app opened sucessfully with URL: \(url)")
                            }else{
                                print("Failed to open Anonymage app with URL: \(url)")
                            }
                        }
                        decisionHandler(.cancel) // Cancel WebView navigation
                        return
                    }
                }
                
                let shouldContinue = VMAge.isRedirectURL(url) { isRedirect in
                    if isRedirect, let onComplete = self.parent.onComplete {
                        onComplete()
                        return false // Cancel navigation
                    }
                    return true // Continue navigation
                }
                
                decisionHandler(shouldContinue ? .allow : .cancel)
                return
            }
            
            decisionHandler(.allow)
        }
    }
}

// Protocol to make Error.localizedDescription work
protocol LocalizedDescription {
    var localizedDescription: String { get }
}
