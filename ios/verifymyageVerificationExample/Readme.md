# VerifyMyAge Integration Example

A simple, self-contained example of integrating age verification into iOS apps using the VerifyMyAge API.

## Quick Start

1. Add `VMAge.swift` to your project
2. Change`Info.plist` file with your API credentials
3. Add code to start verification and handle the result:

```swift
// Step 1: Start verification
VMAge.startVerification { result in
    switch result {
    case .success(let response):
        // Save verification ID for later status check
        let verificationID = response.verificationID
        
        // Show WebView with verification URL
        if let url = URL(string: response.verificationURL) {
            // Present WebView with this URL
        }
        
    case .failure(let error):
        // Handle error
        print("Verification error: \(error.localizedDescription)")
    }
}

// Step 2: After user completes verification in WebView,
// check the final verification status
VMAge.checkStatus(verificationID: "verification-id") { result in
    switch result {
    case .success(let status):
        if status == .approved {
            // User was successfully verified
            print("User verified successfully!")
        } else {
            // Handle other statuses
            print("Verification status: \(status.rawValue)")
        }
        
    case .failure(let error):
        print("Status check failed: \(error.localizedDescription)")
    }
}
```

## Configuration

The `Info.plist` file requires these values:

```
<key>API_KEY</key>
<string>YOUR-API-KEY</string>
<key>API_SECRET</key>
<string>YOUR-SECRET-KEY</string>
<key>DEFAULT_CALLBACK_URL</key>
<string>https://your-app-callback-url.com</string>
<key>METHOD</key>
<string>IDScan</string>
<key>NSCameraUsageDescription</key>
<string>Camera access is required for ID verification</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access may be required for video verification</string>
```

## Verification Statuses

The API uses these status values for the verification process:

| Status | Description |
|--------|-------------|
| `started` | The user has not started the verification process |
| `pending` | The user has started but not finished the verification process |
| `approved` | The user has completed the verification process successfully |
| `failed` | The user has not completed the verification process successfully |
| `expired` | 5 days have elapsed since the verification link was generated |

## Core Components

### VMAge.swift
Contains all the code needed for API communication, including:
- HMAC generation for security
- Environment configuration loading
- API request handling
- WebView for verification UI
- Status check functionality

### DemoView.swift
Demonstrates a complete implementation of:
- Verification button UI
- Status indicators for each verification state
- WebView presentation
- Status checking after verification completes

## Verification Flow

1. **Initiate verification**: Call `VMAge.startVerification()`
2. **Present verification UI**: Show WebView with the URL from the response
3. **Detect completion**: The WebView detects when the user is redirected to your callback URL
4. **Check verification status**: Use `VMAge.checkStatus()` with the verification ID
5. **Process result**: Update your UI based on verification status (`approved`, `failed`, etc.)


## Requirements

- iOS 14.0+
- Swift 5.3+
