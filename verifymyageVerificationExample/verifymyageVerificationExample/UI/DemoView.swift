import SwiftUI

/**
 # VerifyMyAge Demo Screen
 
 This view implements the exact layout of the VerifyMyAge demo site.
 */
struct DemoView: View {
    // MARK: - State
    
    /// Selected country
    @State private var selectedCountry: Country = Country.defaultCountries[0]
    
    /// Controls whether the WebView is shown
    @State private var showVerification = false
    
    /// Controls whether the country picker is shown
    @State private var showCountryPicker = false
    
    /// URL for the verification WebView
    @State private var verificationURL: URL?
    
    /// Verification ID from the API
    @State private var verificationID: String?
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Center card
            VStack(spacing: 24) {
                // Logo
                Image("verifymyage-logo") // Replace with your actual logo asset
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .padding(.bottom, 10)
                
                // Country selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .medium))
                    
                    Button(action: {
                        showCountryPicker = true
                    }) {
                        HStack {
                            Text(selectedCountry.name)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                // Start button
                Button(action: startVerification) {
                    Text("START")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#E67E4A")) // Orange color from the demo
                        .cornerRadius(4)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 5)
            .frame(width: min(UIScreen.main.bounds.width - 40, 400))
        }
        .sheet(isPresented: $showVerification) {
            // Show WebView when verification is active
            if let url = verificationURL {
                VMWebView(url: url) {
                    // This is called when the WebView detects a redirect to our callback URL
                    handleVerificationComplete()
                }
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            // Custom country picker sheet
            countryPickerView()
        }
    }
    
    private func countryPickerView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Country.defaultCountries) { country in
                Button(action: {
                    selectedCountry = country
                    showCountryPicker = false
                }) {
                    HStack {
                        if country.id == selectedCountry.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.black)
                                .frame(width: 20)
                        } else {
                            Spacer()
                                .frame(width: 20)
                        }
                        
                        Text(country.name)
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .background(country.id == selectedCountry.id ? Color.black.opacity(0.05) : Color.clear)
            }
        }
        .background(Color.white.opacity(0.95))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    
    // MARK: - Verification Logic
    
    /// Start the verification process
    private func startVerification() {
        // Call VerifyMyAge API with country code
        VMAge.startVerification(countryCode: selectedCountry.code) { result in
            switch result {
            case .success(let response):
                // Store verification ID for reference
                self.verificationID = response.verificationID
                
                // Create URL for verification
                if let url = URL(string: response.verificationURL) {
                    self.verificationURL = url
                    self.showVerification = true
                }
                
            case .failure(let error):
                // Handle error
                print("Verification error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Called when the WebView detects a redirect to our callback URL
    private func handleVerificationComplete() {
        guard let id = verificationID else {
            showVerification = false
            return
        }
        
        // Close WebView
        showVerification = false
        
        // Check verification status
        VMAge.checkStatus(verificationID: id) { result in
            switch result {
            case .success(let status):
                // Handle the verification status
                print("Verification status: \(status.rawValue)")
                
                // In a real app, you would update your UI to show the status
                // or take the appropriate action based on the status
                
            case .failure(let error):
                // Handle error
                print("Status check error: \(error.localizedDescription)")
            }
        }
    }
}

/// Country model for country picker
struct Country: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
    
    /// Default list of countries matching the demo screenshot
    static let defaultCountries: [Country] = [
        Country(name: "France", code: "fr", flag: "🇫🇷"),
        Country(name: "Germany", code: "de", flag: "🇩🇪"),
        Country(name: "United Kingdom", code: "gb", flag: "🇬🇧"),
        Country(name: "United States of America", code: "us", flag: "🇺🇸"),
        Country(name: "Demo", code: "demo", flag: "🏳️")
    ]
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct DemoView_Previews: PreviewProvider {
    static var previews: some View {
        DemoView()
    }
}
