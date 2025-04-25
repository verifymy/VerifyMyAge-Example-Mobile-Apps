package io.verifymy.verifymywebview

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.webkit.CookieManager
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import io.verifymy.verifymywebview.ui.theme.VerifymywebviewTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            Log.d("WebView", "Camera permission granted")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            VerifymywebviewTheme {
                MainScreen(requestPermissionLauncher)
            }
        }
    }
}

@Composable
fun MainScreen(
    permissionLauncher: ActivityResultLauncher<String>
) {
    var currentScreen by remember { mutableStateOf(SCREEN_PARAMS) }
    var verificationParams by remember { mutableStateOf(VerificationParams()) }
    var basicVerification by remember { mutableStateOf<BasicVerification?>(null) }
    var redirectUrl by remember { mutableStateOf(DEFAULT_CALLBACK_URL) }
    val scope = rememberCoroutineScope()

    when (currentScreen) {
        SCREEN_PARAMS -> {
            CountrySelectionScreen(
                onVerificationParamsSet = { params ->
                    scope.launch {
                        redirectUrl = params.redirectUrl
                        runCatching { createVerification(params) }
                            .onSuccess {
                                Log.d("VerificationCreated", "Verification created: $it")
                                basicVerification = it
                                currentScreen = SCREEN_VERIFICATION
                            }.onFailure {
                                Log.e("WebView", "Failed to create verification", it)
                                basicVerification = BasicVerification(
                                    status = "failed",
                                    id = "",
                                    url = ""
                                )
                                currentScreen = SCREEN_RESULT
                            }
                    }
                }
            )
        }
        SCREEN_VERIFICATION -> {
            basicVerification?.let { url ->
                BrowserScreen(
                    permissionLauncher = permissionLauncher,
                    verificationUrl = basicVerification!!.url,
                    redirectUrl = redirectUrl,
                    onNavigateToThankYou = { id ->
                        currentScreen = SCREEN_RESULT
                    }
                )
            }
        }
        SCREEN_RESULT -> {
            ThankYouScreen(
                verificationId = basicVerification?.id,
                onRestartClick = {
                    basicVerification = null
                    verificationParams = VerificationParams()
                    currentScreen = SCREEN_PARAMS
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CountrySelectionScreen(
    onVerificationParamsSet: (VerificationParams) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    var selectedCountry by remember { mutableStateOf("United Kingdom") }
    var selectedCode by remember { mutableStateOf("gb") }
    var redirectUrl by remember { mutableStateOf(DEFAULT_CALLBACK_URL) }
    var businessSettingsId by remember { mutableStateOf("") }
    var externalUserId by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }

    val countries = listOf(
        "United Kingdom" to "gb",
        "Germany" to "de",
        "United States" to "us",
        "Demo" to "demo"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        Card(
            modifier = Modifier
                .padding(PADDING_NORMAL.dp)
                .align(Alignment.Center),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(
                modifier = Modifier
                    .padding(PADDING_LARGE.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(PADDING_LARGE.dp)
            ) {
                // Logo
                Image(
                    painter = painterResource(id = R.drawable.verifymyage_logo),
                    contentDescription = "VerifyMyAge Logo",
                    modifier = Modifier.width(LOGO_WIDTH.dp),
                    contentScale = ContentScale.FillWidth
                )

                // Country Dropdown
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = it }
                ) {
                    OutlinedTextField(
                        value = selectedCountry,
                        onValueChange = {},
                        readOnly = true,
                        placeholder = {
                            Text(
                                text = "Select a country",
                                color = COLOR_TEXT_HINT
                            )
                        },
                        trailingIcon = {
                            Icon(
                                imageVector = Icons.Default.KeyboardArrowDown,
                                contentDescription = "Show countries",
                                tint = COLOR_ICON
                            )
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(),
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedBorderColor = COLOR_BORDER,
                            focusedBorderColor = COLOR_BORDER
                        )
                    )

                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        countries.forEach { (name, code) ->
                            DropdownMenuItem(
                                text = { Text(name) },
                                onClick = {
                                    selectedCountry = name
                                    selectedCode = code
                                    expanded = false
                                }
                            )
                        }
                    }
                }

                // Redirect URL
                OutlinedTextField(
                    value = redirectUrl,
                    onValueChange = { redirectUrl = it },
                    label = { Text("Redirect URL") },
                    placeholder = { Text(DEFAULT_CALLBACK_URL) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        unfocusedBorderColor = COLOR_BORDER,
                        focusedBorderColor = COLOR_BORDER
                    )
                )

                // Business Settings ID
                OutlinedTextField(
                    value = businessSettingsId,
                    onValueChange = { businessSettingsId = it },
                    label = { Text("Business Settings ID") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        unfocusedBorderColor = COLOR_BORDER,
                        focusedBorderColor = COLOR_BORDER
                    )
                )

                // External User ID
                OutlinedTextField(
                    value = externalUserId,
                    onValueChange = { externalUserId = it },
                    label = { Text("External User ID") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        unfocusedBorderColor = COLOR_BORDER,
                        focusedBorderColor = COLOR_BORDER
                    )
                )

                // Start Button
                Button(
                    onClick = {
                        if (selectedCode.isNotEmpty()) {
                            isLoading = true
                            onVerificationParamsSet(
                                VerificationParams(
                                    country = selectedCode,
                                    redirectUrl = redirectUrl.takeIf { it != DEFAULT_CALLBACK_URL } ?: DEFAULT_CALLBACK_URL,
                                    businessSettingsId = businessSettingsId,
                                    externalUserId = externalUserId
                                )
                            )
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = COLOR_BUTTON
                    ),
                    shape = RoundedCornerShape(8.dp),
                    enabled = selectedCode.isNotEmpty() && !isLoading
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            color = Color.White,
                            modifier = Modifier.size(24.dp)
                        )
                    } else {
                        Text("Start Verification")
                    }
                }
            }
        }
    }
}

@Composable
fun BrowserScreen(
    permissionLauncher: ActivityResultLauncher<String>,
    verificationUrl: String,
    redirectUrl: String,
    onNavigateToThankYou: (String?) -> Unit
) {
    var webView by remember { mutableStateOf<WebView?>(null) }
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding() // Add padding for system bars
    ) {
        AndroidView(
            modifier = Modifier
                .fillMaxSize()
                .navigationBarsPadding(), // Add padding for navigation bar
            factory = { context ->
                WebView(context).apply {
                    webView = this
                    settings.apply {
                        javaScriptEnabled = true
                        domStorageEnabled = true
                        mediaPlaybackRequiresUserGesture = false
                        setSupportMultipleWindows(true)
                        builtInZoomControls = true
                        displayZoomControls = false
                    }

                    webViewClient = object : WebViewClient() {
                        override fun shouldOverrideUrlLoading(
                            view: WebView?,
                            url: String?
                        ): Boolean {
                            return handleCustomURLScheme(url, redirectUrl, onNavigateToThankYou)
                        }

                        override fun onPageFinished(view: WebView?, url: String?) {
                            super.onPageFinished(view, url)
                            CookieManager.getInstance().removeAllCookies {
                                Log.d("OnPageFinished", "Cookies removed") // to prevent reusing cookies to automatically approve the verification based on the previous verification
                            }
                            // Reset zoom to prevent UI overlapping
                            view?.setInitialScale(0)
                        }
                    }

                    webChromeClient = object : WebChromeClient() {
                        override fun onPermissionRequest(request: PermissionRequest?) {
                            request?.let { handlePermissionRequest(it) }
                        }
                    }

                    // Prevent content from being hidden behind system bars
                    fitsSystemWindows = true
                }
            },
            update = { view ->
                webView = view
                view.loadUrl(verificationUrl)
            }
        )

        DisposableEffect(Unit) {
            onDispose {
                webView?.apply {
                    clearCache(true)
                    clearFormData()
                    clearHistory()
                    evaluateJavascript("localStorage.clear();", null)
                    destroy()
                }
            }
        }
    }
}

fun handleCustomURLScheme(
    url: String?,
    redirectUrl: String,
    onNavigateToThankYou: (String?) -> Unit
): Boolean {
    url?.let {
        if (it.length > redirectUrl.length && it.substring(0, redirectUrl.length).contains(redirectUrl, ignoreCase = true)) {
            onNavigateToThankYou(null)
            return true
        }
    }
    return false
}

fun handlePermissionRequest(request: PermissionRequest) {
    val resources = request.resources
    if (resources.contains(PermissionRequest.RESOURCE_VIDEO_CAPTURE)) {
        request.grant(arrayOf(PermissionRequest.RESOURCE_VIDEO_CAPTURE))
    } else {
        request.deny()
    }
}

@Composable
fun ThankYouScreen(
    verificationId: String?,
    onRestartClick: () -> Unit
) {
    var status by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(verificationId) {
        if (!verificationId.isNullOrBlank()) {
            isLoading = true
            runCatching {
                fetchVerificationStatus(verificationId)
            }.onSuccess {
                status = it
            }.onFailure {
                Log.e("WebView", "Failed to fetch verification status", it)
                status = "failed"
            }.also {
                isLoading = false
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        Card(
            modifier = Modifier
                .padding(PADDING_NORMAL.dp)
                .align(Alignment.Center),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(
                modifier = Modifier.padding(PADDING_LARGE.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(PADDING_LARGE.dp)
            ) {
                // Logo
                Image(
                    painter = painterResource(id = R.drawable.verifymyage_logo),
                    contentDescription = "VerifyMyAge Logo",
                    modifier = Modifier.width(LOGO_WIDTH.dp),
                    contentScale = ContentScale.FillWidth
                )

                if (isLoading) {
                    // Loading indicator
                    CircularProgressIndicator(
                        modifier = Modifier.size(48.dp),
                        color = COLOR_BUTTON
                    )
                    Text(
                        text = "Verifying...",
                        style = TextStyle(
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                } else {
                    // Status Icon
                    Icon(
                        imageVector = if (status == "approved") Icons.Default.Check else Icons.Default.Close,
                        contentDescription = "Status Icon",
                        tint = if (status == "approved") Color.Green else Color.Red,
                        modifier = Modifier.size(48.dp)
                    )

                    // Status Text
                    Text(
                        text = when (status) {
                            "approved" -> "Verification Successful"
                            "rejected" -> "Verification Rejected"
                            "failed" -> "Verification Failed"
                            else -> ""
                        },
                        style = TextStyle(
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )

                    // Verification ID
                    if (!verificationId.isNullOrBlank()) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(
                                    color = Color(0xFFF5F5F5),
                                    shape = RoundedCornerShape(8.dp)
                                )
                                .padding(16.dp),
                            horizontalAlignment = Alignment.Start
                        ) {
                            Text(
                                text = "Verification ID:",
                                style = TextStyle(
                                    fontSize = 14.sp,
                                    color = Color.Gray
                                )
                            )
                            Text(
                                text = verificationId,
                                style = TextStyle(
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Medium
                                )
                            )
                        }
                    }

                    // Restart Button
                    Button(
                        onClick = onRestartClick,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = COLOR_BUTTON
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Start New Verification")
                    }
                }
            }
        }
    }
}

data class VerificationParams(
    val country: String = "",
    val redirectUrl: String = DEFAULT_CALLBACK_URL,
    val businessSettingsId: String = "",
    val externalUserId: String = ""
)

data class BasicVerification(
    val id: String,
    val url: String,
    val status: String
)