# VerifyMyWebView

A polished Android app built with Kotlin and Jetpack Compose for integrating VerifyMyAge's age verification flow using a WebView. The app demonstrates a full verification journey, from country selection to secure status retrieval, with a modern UI and robust security practices.

---

## Features
- **Secure API Integration:**
  - Uses HMAC-SHA256 signatures (hex-encoded, matching CryptoJS) for backend API requests.
  - Camera permission requested when WebView is shown.
- **State Persistence:**
  - Handles orientation changes without resetting WebView state.

---

## Getting Started

### Prerequisites
- Android Studio (latest recommended)
- Android device or emulator (API 21+)
- Internet connection

### Setup
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/verifymywebview.git
   cd verifymywebview
   ```
2. **Open in Android Studio:**
   - File > Open > Select the `verifymywebview` folder.
3. **Configure API Keys:**
   - Edit `MainActivity.kt` and set your real `apiKey` and `privateKey`.
4. **Build and Run:**
   - Click the Run button or use `Shift+F10`.

---

## Project Structure

- `MainActivity.kt` — Main UI logic, navigation, and API integration.
- `ui/theme/` — Compose theme, colors, and typography.
- `res/` — Images and resources (including the VerifyMyAge logo).

---

## Security Notes
- HMAC signatures are generated using the private key and sent as hex, matching the backend's expectation.
- Camera permission is requested only when needed by the WebView.
- No sensitive keys are committed to the repository by default.

---

## WebView & App Settings

This app demonstrates best practices for running the VerifyMyAge flow inside a WebView on Android:

### WebView Settings Used

- **JavaScript enabled**: Allows interactive verification flows.
- **DOM Storage enabled**: Supports modern web features.
- **Media playback without user gesture**: Required for camera/microphone access.
- **Custom WebViewClient**: Handles custom URL schemes and navigation.
- **Custom WebChromeClient**: Handles camera permission requests from the web content.
- **Camera permission**: Requested at runtime before showing the WebView.
- **Secure HMAC authentication**: API requests use HMAC-SHA256 signatures in hex format.
- **State restoration**: WebView state is preserved across orientation changes.

### Example WebView Configuration (Kotlin)
```kotlin
WebView(context).apply {
    settings.javaScriptEnabled = true
    settings.domStorageEnabled = true
    settings.mediaPlaybackRequiresUserGesture = false
    webViewClient = object : WebViewClient() { /* ... */ }
    webChromeClient = object : WebChromeClient() { /* ... */ }
    loadUrl(verificationUrl)
}
```

### Other App Settings
- **Edge-to-edge UI**: Modern, immersive Compose layout.
- **Country selection**: Customizable dropdown, can be extended.
- **Thank you/status screen**: Displays verification result and ID.
- **Restart flow**: User can start a new verification at any time.

---

## Customization
- To add/remove countries, edit the `countries` list in `CountrySelectionScreen`.
- To change branding or colors, edit the theme files in `ui/theme/`.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## Contact
For integration support or questions, contact [support@verifymyage.com](mailto:support@verifymyage.com).
