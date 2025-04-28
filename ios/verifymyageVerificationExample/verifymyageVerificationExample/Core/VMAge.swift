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
 */
class VMAge {
    // MARK: - Configuration
    
    /// API base URL
    private static let baseURL = "https://sandbox.verifymyage.com"
    
    /// API key for authentication
    static var apiKey: String {
        return Bundle.main.infoDictionary?["API_KEY"] as? String ?? ""
    }
    
    /// API secret for HMAC generation
    static var apiSecret: String {
        return Bundle.main.infoDictionary?["API_SECRET"] as? String ?? ""
    }
    
    /// Redirect URL for verification completion
    static var redirectURL = Bundle.main.infoDictionary?["DEFAULT_CALLBACK_URL"] as? String ?? ""
    
    /// Verification method (e.g., AgeEstimation, Email, IDScan, IDScanFaceMatch, Mobile, CreditCard)
    static var method: String? {
        return Bundle.main.infoDictionary?["METHOD"] as? String
    }
    
    /// Auth start endpoint
    private static let authStartEndpoint = "/v2/auth/start"
    
    /// Status check endpoint
    private static func statusEndpoint(for id: String) -> String {
        return "/v2/verification/\(id)/status"
    }
    
    // MARK: - Error Types
    
    /// Errors that can occur during verification
    enum Error: Swift.Error, LocalizedError {
        /// Missing or invalid API credentials
        case invalidCredentials
        // Missing required fields
        case missingRequiredFields(String)
        /// Network or API request failed
        case requestFailed(String)
        
        /// Server returned an error
        case serverError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid API credentials. Check your API_KEY and API_SECRET in Info.plist"
            case .missingRequiredFields(let reason):
                return "Missing Required Fields: \(reason)"
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
        
        /// Is this a success status?
        var isSuccess: Bool {
            return self == .approved
        }
    }
    
    // MARK: - Start Verification Model
    
    /// start verification params
    struct VerificationRequest {
        
        ///ISO country code (e.g., "gb", "de", "fr", "us")
        let countryCode: String
        
        /// UUID to identify an user.
        let externalUserID: String?
        
        /// Id of business configuration.
        let businessSettingsID: String?
        
        /// Redirect URL for verification completion
        let redirectURL: String
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
     Start a verification process with the specified country
     
     - Parameters:
       - request: VerificationRequest to start verification
       - completion: Callback with verification URL or error
     */
    static func startVerification(request: VerificationRequest, completion: @escaping (Result<Response, Error>) -> Void) {
        // Validate credentials
        guard !apiKey.isEmpty, !apiSecret.isEmpty, !redirectURL.isEmpty else {
            completion(.failure(.invalidCredentials))
            return
        }
        
        // Validate required parameters
        if request.countryCode.isEmpty{
            completion(.failure(.missingRequiredFields("country")))
            return
        }
        
        if request.redirectURL.isEmpty{
            completion(.failure(.missingRequiredFields("redirect_url")))
            return
        }
        
        redirectURL = request.redirectURL
        
        // Create parameters
        let params: [String: String?] = [
            "country": request.countryCode,
            "redirect_url": request.redirectURL,
            "method": method,
            "business_settings_id": request.businessSettingsID,
            "external_user_id": request.externalUserID,
        ]
        
        // Start verification
        verify(params: params, completion: completion)
    }
    
    /**
     Start a verification with custom parameters
     
     - Parameters:
       - params: Custom verification parameters
       - completion: Callback with verification URL or error
     */
    static func verify(params: [String: String?], completion: @escaping (Result<Response, Error>) -> Void) {
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
        
        print("Starting verification")
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                DispatchQueue.main.async {
                    print("Request error: \(error.localizedDescription)")
                    completion(.failure(.requestFailed(error.localizedDescription)))
                }
                return
            }
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                
                DispatchQueue.main.async {
                    print("HTTP error: \(httpResponse.statusCode)")
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
                
                print("Verification created - ID: \(verificationID)")
                print("Verification URL: \(verificationURL)")
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let error = json["error"] as? String {
                DispatchQueue.main.async {
                    print("Server error: \(error)")
                    completion(.failure(.serverError(error)))
                }
            } else {
                DispatchQueue.main.async {
                    // Try to get raw response as string for debugging
                    let responseStr = String(data: data, encoding: .utf8) ?? "Unknown format"
                    print("Invalid response format: \(responseStr)")
                    completion(.failure(.serverError("Invalid response format")))
                }
            }
        }.resume()
    }
    
    /**
     Check the current status of a verification
     
     - Parameters:
       - verificationID: The ID of the verification to check
       - completion: Callback with the current status or error
     */
    static func checkStatus(verificationID: String, completion: @escaping (Result<VerificationStatus, Error>) -> Void) {
        // Validate credentials
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            completion(.failure(.invalidCredentials))
            return
        }
        
        // Validate required parameters
        if verificationID.isEmpty {
            completion(.failure(.missingRequiredFields("verification_id")))
            return
        }
        
        // Create URL and request URI (path + query)
        let requestUri = statusEndpoint(for: verificationID)
        let endpoint = baseURL + requestUri
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(.requestFailed("Invalid API URL")))
            return
        }
        
        // Generate HMAC using the request URI
        guard let hmac = generateHMAC(secret: apiSecret, data: requestUri) else {
            completion(.failure(.requestFailed("Failed to generate security signature")))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        request.addValue("hmac \(apiKey):\(hmac)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Checking status for ID: \(verificationID)")
        
        // Make request
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                DispatchQueue.main.async {
                    print("Status check error: \(error.localizedDescription)")
                    completion(.failure(.requestFailed(error.localizedDescription)))
                }
                return
            }
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                
                DispatchQueue.main.async {
                    print("HTTP error: \(httpResponse.statusCode)")
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
                
                print("Verification status: \(status.rawValue)")
                
                DispatchQueue.main.async {
                    completion(.success(status))
                }
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let error = json["error"] as? String {
                DispatchQueue.main.async {
                    print("Server error: \(error)")
                    completion(.failure(.serverError(error)))
                }
            } else {
                DispatchQueue.main.async {
                    // Try to get raw response as string for debugging
                    let responseStr = String(data: data, encoding: .utf8) ?? "Unknown format"
                    print("Invalid response format: \(responseStr)")
                    completion(.failure(.serverError("Invalid response format")))
                }
            }
        }.resume()
    }
    
    /**
     Check if a URL is a verification redirect URL
     
     - Parameters:
       - url: URL to check
       - callback: Returns true if it's a redirect URL
     
     - Returns: Whether to continue navigation (true) or cancel it (false)
     */
    static func isRedirectURL(_ url: URL, callback: (Bool) -> Bool) -> Bool {
        // If no redirect URL configured, can't check
        if redirectURL.isEmpty {
            return callback(false)
        }
        
        // Check if URL starts with our redirect URL
        if url.absoluteString.starts(with: redirectURL) {
            print("Detected redirect URL: \(url.absoluteString)")
            
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
}

// MARK: - WebView for Verification

/// WebView for displaying the verification UI
struct VMWebView: UIViewRepresentable {
    /// URL to load in the WebView
    let url: URL
    
    /// Callback for when verification is complete
    var onComplete: (() -> Void)?
    
    /// Create the WebView
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
            
        // Configure website data store to avoid cache
        let websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.websiteDataStore = websiteDataStore
        
        let webview = WKWebView(frame: .zero, configuration: configuration)
        webview.navigationDelegate = context.coordinator
        webview.uiDelegate = context.coordinator
        
        // Set scrollView properties to handle keyboard better
        webview.scrollView.keyboardDismissMode = .interactive
        webview.scrollView.contentInsetAdjustmentBehavior = .automatic
        
        return webview
    }
    
    /// Load URL
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load the request
        webView.load(URLRequest(url: url))
    }
    
    /// Create coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// WebView coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: VMWebView
        
        init(_ parent: VMWebView) {
            self.parent = parent
        }
        
        /// Handle navigation
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            if let url = navigationAction.request.url {
                if url.scheme == "mailto" {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:]) { success in
                            print("Email app open result: \(success)")
                        }
                        decisionHandler(.cancel)
                        return
                    }
                }
                
                if navigationAction.navigationType == .linkActivated {
                    // Force open in external browser
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url)
                    }
                    
                    // Cancel the WebView navigation
                    decisionHandler(.cancel)
                    return
                }
                
                // Check for redirect URL
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
        
        /// Handle load start
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("WebView started loading")
        }
        
        /// Handle load finish
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading")
        }
    }
}
