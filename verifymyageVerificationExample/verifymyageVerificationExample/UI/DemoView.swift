import SwiftUI

// MARK: - Main View

/**
 # VerifyMyAge Demo Screen
 
 This view implements the exact layout of the VerifyMyAge demo site.
 */
struct DemoView: View {
    // MARK: - View Model
    
    /// The view model that handles verification logic and state
    @StateObject private var viewModel = VerificationViewModel()
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Content
            if viewModel.showResult {
                VerificationResultView(viewModel: viewModel)
            } else {
                VerificationFormView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showVerification) {
            // WebView for verification process
            if let url = viewModel.verificationURL {
                VMWebView(url: url) {
                    viewModel.handleVerificationComplete()
                }
            }
        }
        .sheet(isPresented: $viewModel.showCountryPicker) {
            CountryPickerView(
                selectedCountry: $viewModel.selectedCountry,
                isPresented: $viewModel.showCountryPicker
            )
        }
    }
}

// MARK: - Verification Form View

/**
 The main form view with country selection and start button
 */
struct VerificationFormView: View {
    @ObservedObject var viewModel: VerificationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            logoView()
            
            // Country selection
            countrySelectionView()
            
            // Start button
            startButton()
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 5)
        .frame(width: min(UIScreen.main.bounds.width - 40, 400))
    }
    
    private func logoView() -> some View {
        Image("verifymyage-logo")
            .resizable()
            .scaledToFit()
            .frame(width: 200)
            .padding(.bottom, 10)
    }
    
    private func countrySelectionView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Country")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .medium))
            
            Button(action: {
                viewModel.showCountryPicker = true
            }) {
                HStack {
                    Text(viewModel.selectedCountry.name)
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
    }
    
    private func startButton() -> some View {
        Button(action: viewModel.startVerification) {
            Text("START")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#E67E4A"))
                .cornerRadius(4)
        }
    }
}

// MARK: - Verification Result View

/**
 The result view displaying verification status and ID
 */
struct VerificationResultView: View {
    @ObservedObject var viewModel: VerificationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image("verifymyage-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
            
            // Status icon
            statusIcon()
            
            // Status text
            statusText()
            
            // Verification ID
            verificationIdView()
            
            // Back button
            backButton()
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 5)
        .frame(width: min(UIScreen.main.bounds.width - 40, 400))
    }
    
    private func statusIcon() -> some View {
        Image(systemName: viewModel.verificationStatus.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .foregroundColor(viewModel.verificationStatus.isSuccess ? .green : .red)
    }
    
    private func statusText() -> some View {
        Text(viewModel.verificationStatus.isSuccess ? "Verification Successful" : "Verification Failed")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(viewModel.verificationStatus.isSuccess ? .green : .red)
    }
    
    private func verificationIdView() -> some View {
        Group {
            if let id = viewModel.verificationID {
                VStack(alignment: .leading) {
                    Text("Verification ID:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(id)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private func backButton() -> some View {
        Button(action: viewModel.resetVerification) {
            Text("Start New Verification")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#E67E4A"))
                .cornerRadius(4)
        }
        .padding(.top, 10)
    }
}

// MARK: - Country Picker View

/**
 Custom country picker with checkmarks for selection
 */
struct CountryPickerView: View {
    @Binding var selectedCountry: Country
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Country.defaultCountries) { country in
                Button(action: {
                    selectedCountry = country
                    isPresented = false
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
}

// MARK: - View Model

/**
 ViewModel that handles all the verification logic and state
 */
class VerificationViewModel: ObservableObject {
    // Country selection
    @Published var selectedCountry: Country = Country.defaultCountries[0]
    @Published var showCountryPicker = false
    
    // Verification state
    @Published var showVerification = false
    @Published var verificationURL: URL?
    @Published var verificationID: String?
    @Published var verificationStatus: VMAge.VerificationStatus = .unknown
    @Published var showResult = false
    
    /// Start the verification process
    func startVerification() {
        // Call VerifyMyAge API with country code
        VMAge.startVerification(countryCode: selectedCountry.code) { [weak self] result in
            guard let self = self else { return }
            
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
    func handleVerificationComplete() {
        guard let id = verificationID else {
            showVerification = false
            return
        }
        
        // Close WebView
        showVerification = false
        
        // Check verification status
        VMAge.checkStatus(verificationID: id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let status):
                // Update status and show result view
                self.verificationStatus = status
                self.showResult = true
                
            case .failure(let error):
                // Handle error
                print("Status check error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Reset verification state to start a new verification
    func resetVerification() {
        // Reset all verification-related state
        showResult = false
        verificationID = nil
        verificationStatus = .unknown
        verificationURL = nil
        showVerification = false
    }
}

// MARK: - Models

/// Country model for country picker
struct Country: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    
    /// Default list of countries matching the demo screenshot
    static let defaultCountries: [Country] = [
        Country(name: "Germany", code: "DE"),
        Country(name: "United Kingdom", code: "GB"),
        Country(name: "United States of America", code: "US"),
        Country(name: "Demo", code: "DEMO")
    ]
}

// MARK: - Helpers

/// Color extension for hex conversion
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
            blue: Double(b) / 255,
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
