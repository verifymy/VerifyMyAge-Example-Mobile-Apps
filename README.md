# VerifyMyAge WebView Integration Guide

This guide explains how to integrate the VerifyMyAge verification flow within a WebView for both iOS and Android applications.

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

### WebView Settings

```kotlin
webView.apply {
    settings.javaScriptEnabled = true
    settings.domStorageEnabled = true
    settings.mediaPlaybackRequiresUserGesture = false
}
```

### Required Permissions

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```

### Camera Permission Handling

```kotlin
private val requestPermissionLauncher = registerForActivityResult(
    ActivityResultContracts.RequestPermission()
) { isGranted ->
    if (isGranted) {
        // Camera permission granted
    }
}

// Handle WebView permission requests
webChromeClient = object : WebChromeClient() {
    override fun onPermissionRequest(request: PermissionRequest) {
        request.resources.forEach { r ->
            if (r == PermissionRequest.RESOURCE_VIDEO_CAPTURE) {
                request.grant(arrayOf(PermissionRequest.RESOURCE_VIDEO_CAPTURE))
            }
        }
    }
}
```

### URL Handling

```kotlin
webViewClient = object : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
        // Handle callback URL
        if (url.startsWith(YOUR_CALLBACK_URL)) {
            // Extract verification ID and handle completion
            return true
        }
        return false
    }
}
```

## iOS Implementation

### WebView Configuration

```swift
let config = WKWebViewConfiguration()
config.allowsInlineMediaPlayback = true
config.mediaTypesRequiringUserActionForPlayback = []

let webView = WKWebView(frame: .zero, configuration: config)
webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
```

### Required Permissions

Add to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for ID verification</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone access may be required for video verification</string>
```

### Camera Permission Handling

```swift
class ViewController: UIViewController, WKUIDelegate {
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermission: WKMediaCapturePermissionBlock) {
        requestMediaCapturePermission(.grant)
    }
}
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
   
   These warnings can be safely ignored. They do not affect the verification process since they are related to a third-party library.

## API Integration

1. Initialize verification flow:
```
GET https://dev.verifymyage.com/oauth/authorize
    ?client_id=YOUR_API_KEY
    &country=COUNTRY_CODE
    &method=
    &redirect_uri=YOUR_CALLBACK_URL
    &response_type=code
    &scope=adult
    &state=xyz
    &sdk=1
```

2. Check verification status:
```
GET https://dev.verifymyage.com/v2/verification/VERIFICATION_ID/status
Headers:
    Content-Type: application/json
    Authorization: hmac YOUR_API_KEY:GENERATED_HMAC
```

## Support

For additional support or questions, contact VerifyMyAge support team or refer to the official documentation.
