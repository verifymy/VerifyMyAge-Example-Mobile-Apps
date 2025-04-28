# VerifyMyAge WebView Integration Guide

This guide explains how to integrate the VerifyMyAge verification flow within a WebView for both iOS and Android applications.

## Preview
iOS

https://github.com/user-attachments/assets/35d38cc6-407b-46b7-a988-ac0a490dec71


https://github.com/user-attachments/assets/fe685118-e93f-4cfe-b07d-3666e22870f0



Android


https://github.com/user-attachments/assets/7993d988-cd53-46de-b9d1-29148cbdd697




https://github.com/user-attachments/assets/ab49b5a4-ccb4-4b03-bcbc-739be198a432





## Prerequisites

- VerifyMyAge API credentials:
  - API Key
  - Secret Key
- Your application's callback URL registered with VerifyMyAge

## General Requirements

1. WebView must have JavaScript enabled
2. Camera permissions must be requested and granted for ID verification
3. Local Storage must be enabled
4. HTTPS connections must be allowed
5. Redirect handling must be implemented for the callback URL

## Android Implementation

This implementation has been tested and is compatible with Android versions from Android 7.0 (API level 24) to the latest versions.

### Setup

1. Add your API credentials in `Constants.kt`:
```kotlin
const val API_KEY = "your_api_key"
const val API_SECRET_KEY = "your_api_secret"
```

2. Configure your callback URL:
```kotlin
const val DEFAULT_CALLBACK_URL = "https://your-app-callback-url.com"
```

3. Add required permissions to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

### API Integration

The integration consists of three main steps:

1. **Create Verification**
   ```kotlin
   // Parameters for verification
   val params = VerificationParams(
       country = "gb",                                   // Required
       redirectUrl = "https://your-callback-url.com",    // Optional
       businessSettingsId = "your_settings_id",          // Optional
       externalUserId = "user123",                      // Optional
   )

   // Create verification and handle response
   runCatching { createVerification(params) }
       .onSuccess { verification ->
           // verification.id: String - Use this to check status later
           // verification.url: String - Load this in WebView
           // verification.status: String - Initial status
       }
       .onFailure { error ->
           // Handle API errors
       }
   ```

2. **Handle Verification Flow**

   a. Basic WebView Setup
   ```kotlin
   // Configure WebView
   WebView(context).apply {
       settings.apply {
           javaScriptEnabled = true
           domStorageEnabled = true
           mediaPlaybackRequiresUserGesture = false
       }
       
       // Load verification URL
       loadUrl(verification.url)
       
       // Handle completion
       webViewClient = object : WebViewClient() {
           override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
               // Check if URL matches your callback
               if (url?.startsWith(YOUR_CALLBACK_URL) == true) {
                   // Verification completed
                   return true
               }
               return false
           }
       }
   }
   ```

   b. Camera Permission
   ```kotlin
   // Request camera permission
   val requestPermissionLauncher = registerForActivityResult(
       ActivityResultContracts.RequestPermission()
   ) { isGranted ->
       if (isGranted) {
           // Camera permission granted, WebView can access camera
       }
   }

   // Handle WebView permissions
   webChromeClient = object : WebChromeClient() {
       override fun onPermissionRequest(request: PermissionRequest?) {
           request?.let {
               if (it.resources.contains(PermissionRequest.RESOURCE_VIDEO_CAPTURE)) {
                   it.grant(arrayOf(PermissionRequest.RESOURCE_VIDEO_CAPTURE))
               } else {
                   it.deny()
               }
           }
       }
   }
   ```

3. **Check Verification Status**
   ```kotlin
   runCatching { fetchVerificationStatus(verificationId) }
       .onSuccess { status ->
           when (status) {
               "approved" -> // Verification successful
               "rejected" -> // Verification failed
               "failed" -> // Technical error
           }
       }
       .onFailure { error ->
           // Handle API errors
       }
   ```

### Stealth Mode

When enabled, stealth mode provides a streamlined verification process:

1. **Requirements**
   - User's email address is required
   - Add `stealth=true` to verification URL
   - Include user info in API request

2. **Example Request**
   ```json
   {
     "country": "gb",
     "redirect_url": "https://your-callback-url.com?stealth=true",
     "user_info": {
       "email": "user@example.com"
     }
   }
   ```

### Security Considerations

1. **API Security**
   - All requests are signed using HMAC-SHA256
   - Keep your API secret key secure
   - Use HTTPS for all API calls

2. **WebView Security**
   - Enable only required JavaScript features
   - Handle permissions appropriately
   - Validate callback URLs

3. **Data Protection**
   - Don't store verification IDs permanently
   - Clear WebView data after verification
   - Handle user data according to GDPR

### Error Handling

1. **API Errors**
   - Network errors
   - Invalid parameters
   - Authentication failures
   - Rate limiting

2. **WebView Errors**
   - Page load failures
   - Camera permission denied
   - Invalid callback URLs

3. **Status Check Errors**
   - Invalid verification ID
   - Expired verifications
   - Network timeouts

## iOS Implementation

### Setup

1. Add your API credentials, redirect URL and optional method in `Info.plist`:
```xml
<key>API_KEY</key>
<string>your_api_key</string>
<key>API_SECRET</key>
<string>your_api_secret</string>
<key>REDIRECT_URL</key>
<string>your_callback_url</string>
<key>METHOD</key> #optional
<string>your_method</string>
```

### Required Permissions

Add to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for ID verification</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone access may be required for video verification</string>
```

### WebView Configuration

```swift
let config = WKWebViewConfiguration()
config.allowsInlineMediaPlayback = true
```

### Required Permissions

Add to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for ID verification</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone access may be required for video verification</string>
```

### URL Handling

```swift
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url,
           url.absoluteString.starts(with: YOUR_CALLBACK_URL) {
            // Handle callback URL
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
```

## Best Practices

1. **Error Handling**
   - Implement proper error handling for network issues
   - Show user-friendly error messages
   - Provide retry options when appropriate

2. **Security**
   - Use HTTPS for all network communications
   - Never store API credentials in client-side code
   - Implement proper HMAC signing for API requests
   - Validate callback parameters

3. **User Experience**
   - Show loading indicators during verification
   - Handle device rotation appropriately
   - Implement proper back button handling
   - Provide clear feedback on camera permissions

4. **Testing**
   - Test with different device types and OS versions
   - Verify camera functionality
   - Test poor network conditions
   - Verify callback handling

## Common Issues

1. **Camera Not Working**
   - Ensure proper permissions are requested
   - Verify WebView settings allow camera access
   - Check for HTTPS connection

2. **Callback Not Received**
   - Verify callback URL is registered correctly
   - Check URL handling implementation
   - Verify network connectivity

3. **Session Issues**
   - Ensure cookies are enabled
   - Verify proper handling of redirects
   - Check for proper CORS settings

4. **Console Warnings**
   
   The following warnings may appear in the console: 
   - `[Violation] Permissions policy violation: accelerometer is not allowed in this document`
   - `The devicemotion events are blocked by permissions policy. See https://github.com/w3c/webappsec-permissions-policy/blob/master/features.md#sensor-features`
   - `The deviceorientation events are blocked by permissions policy. See https://github.com/w3c/webappsec-permissions-policy/blob/master/features.md#sensor-features`
   
   These warnings can be safely ignored. They do not affect the verification process since they are related to a third-party library.

## Support

For additional support or questions, contact VerifyMyAge support team or refer to the official documentation.
