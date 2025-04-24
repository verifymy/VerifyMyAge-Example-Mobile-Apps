# VerifyMyAge Android Example

A polished Android app built with Kotlin and Jetpack Compose demonstrating VerifyMyAge's age verification flow integration using WebView. This example showcases a complete verification journey with modern UI and security best practices.

---

## Features
- **Secure WebView Integration:**
  - Complete age verification flow in a WebView
  - HMAC-SHA256 signatures for API requests
  - Proper camera/permissions handling
- **Modern Android Architecture:**
  - Kotlin + Jetpack Compose UI
  - MVVM architecture pattern
  - State persistence across configuration changes
- **Production-Ready Features:**
  - Error handling and retry mechanisms
  - Loading states and progress indicators
  - Comprehensive logging for debugging

---

## Getting Started

### Prerequisites
- Android Studio Hedgehog (2023.1.1) or newer
- Minimum SDK: API 21 (Android 5.0)
- Kotlin 1.9.x
- JDK 17

---

## Implementation Details

### WebView Configuration
The WebView is configured with necessary settings for optimal VerifyMyAge integration:

```kotlin
webView.apply {
    settings.javaScriptEnabled = true
    settings.domStorageEnabled = true
    settings.mediaPlaybackRequiresUserGesture = false
    settings.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
}
```