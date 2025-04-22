import SwiftUI

/**
 # Main Verification Screen
 
 This view demonstrates how to implement the VerifyMyAge verification flow in your app.
 
 ## How it works:
 
 1. User taps the "Verify My Age" button to start verification
 2. The app calls VMAge.startVerification to get a verification URL
 3. The app displays the VMWebView with the verification URL
 4. When the WebView redirects to our callback URL, we check the verification status
 5. We display the final verification status to the user
 
 You can copy this implementation directly or adapt it to your app's UI style.
 */
struct ContentView: View {
    // MARK: - State
    
    /// Current verification state
    @State private var state: VerificationState = .idle
    
    /// URL for the verification WebView
    @State private var verificationURL: URL?
    
    /// Verification ID from the API
    @State private var verificationID: String?
    
    /// Status received from verification
    @State private var verificationStatus: VMAge.VerificationStatus = .unknown
    
    /// Controls whether the WebView is shown
    @State private var showVerification = false
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Age Verification")
                .font(.title)
                .bold()
                .padding(.top)
            
            // Status area based on state
            statusView()
                .frame(height: 120)
                .padding()
            
            // Verification button
            Button(action: startVerification) {
                Label("Verify My Age", systemImage: "person.fill.checkmark")
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(state == .verifying)
            .padding()
            
            // Verification ID if available
            if let id = verificationID {
                Text("Verification ID: \(id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Status description if verification is complete
            if state == .completed && verificationStatus != .unknown {
                Text("Status: \(verificationStatus.rawValue)")
                    .font(.caption)
                    .foregroundColor(verificationStatus.isSuccess ? .green : .orange)
                    .padding(.top, 5)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showVerification, onDismiss: {
            // If verification is dismissed without completion, assume user cancelled
            if state == .verifying {
                state = .idle
            }
        }) {
            // Show WebView when verification is active
            if let url = verificationURL {
                VMWebView(url: url) {
                    // This is called when the WebView detects a redirect to our callback URL
                    handleVerificationComplete()
                }
            }
        }
    }
    
    // MARK: - Verification Logic
    
    /// Start the verification process
    private func startVerification() {
        // Update state to show loading indicator
        state = .verifying
        verificationStatus = .unknown
        
        // Call VerifyMyAge API
        VMAge.startVerification { result in
            switch result {
            case .success(let response):
                // Store verification ID for reference
                self.verificationID = response.verificationID
                
                // Create URL for verification
                if let url = URL(string: response.verificationURL) {
                    self.verificationURL = url
                    self.showVerification = true
                } else {
                    // Invalid URL error
                    self.state = .idle
                    self.verificationStatus = .failed
                }
                
            case .failure:
                // Show error
                self.state = .idle
                self.verificationStatus = .failed
            }
        }
    }
    
    /// Called when the WebView detects a redirect to our callback URL
    private func handleVerificationComplete() {
        // User has completed the verification flow in the WebView
        // Now we need to check the verification status
        
        guard let id = verificationID else {
            // No verification ID available
            state = .completed
            verificationStatus = .failed
            showVerification = false
            return
        }
        
        // Change state to show we're checking status
        state = .checking
        
        // Close WebView
        showVerification = false
        
        // Check verification status
        VMAge.checkStatus(verificationID: id) { result in
            switch result {
            case .success(let status):
                // Update status
                self.verificationStatus = status
                
            case .failure:
                // Set unknown status on error
                self.verificationStatus = .unknown
            }
            
            // Update state
            self.state = .completed
        }
    }
    
    // MARK: - Status View
    
    /// Generate status view based on current state
    @ViewBuilder
    private func statusView() -> some View {
        switch state {
        case .idle:
            // Initial state
            VStack {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("Tap the button to verify your age")
                    .foregroundColor(.secondary)
            }
            
        case .verifying:
            // Verification in progress
            VStack {
                ProgressView()
                    .padding(.bottom, 10)
                Text("Completing verification...")
                    .foregroundColor(.secondary)
            }
            
        case .checking:
            // Checking status after verification
            VStack {
                ProgressView()
                    .padding(.bottom, 10)
                Text("Checking verification status...")
                    .foregroundColor(.secondary)
            }
            
        case .completed:
            // Status based on verification result
            switch verificationStatus {
            case .approved:
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("Verification Approved")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
            case .failed:
                VStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Verification Failed")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                
            case .expired:
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Verification Expired")
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    Text("The verification link has expired")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .pending:
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Verification Pending")
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    Text("The verification is not complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .started:
                VStack {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Verification Started")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    Text("Please complete verification in the browser")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .unknown:
                VStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Verification Status Unknown")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                    Text("Unable to determine verification status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// Verification process states
enum VerificationState {
    /// Ready to start verification
    case idle
    
    /// Verification in progress in WebView
    case verifying
    
    /// Checking verification status after WebView completes
    case checking
    
    /// Verification process completed
    case completed
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
