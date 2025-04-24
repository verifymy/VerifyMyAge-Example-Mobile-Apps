package io.verifymy.verifymywebview

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.core.net.toUri
import io.verifymy.verifymywebview.ui.theme.VerifymywebviewTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

private const val API_KEY = ""
private const val API_SECRET_KEY = ""

// URL Constants
private const val BASE_URL = "https://stg.verifymyage.com"
private const val DEMO_APP_URL = "https://demo-stg.verifymyage.com/callback"
private const val BASE_VERIFICATION_URL = "$BASE_URL/oauth/authorize?client_id=$API_KEY&country=%s&method=&redirect_uri=$DEMO_APP_URL&response_type=code&scope=adult&state=xyz&sdk=1"

// API Constants
private const val API_VERIFICATION_STATUS_ENDPOINT = "/v2/verification/%s/status"
private const val HMAC_ALGORITHM = "HmacSHA256"
private const val CONTENT_TYPE_JSON = "application/json"
private const val AUTH_HEADER_FORMAT = "hmac %s:%s"

// Screen Names
private const val SCREEN_COUNTRY = "country"
private const val SCREEN_WEBVIEW = "webview"
private const val SCREEN_THANK_YOU = "thankyou"

// UI Constants
private const val LOGO_WIDTH = 200
private const val PADDING_NORMAL = 16
private const val PADDING_LARGE = 24
private const val CORNER_RADIUS = 4
private const val FONT_SIZE_NORMAL = 16

// Colors
private val COLOR_TEXT_PRIMARY = Color(0xFF212121)
private val COLOR_TEXT_HINT = Color(0xFF9E9E9E)
private val COLOR_ICON = Color(0xFF757575)
private val COLOR_BORDER = Color(0xFFE0E0E0)

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
    permissionLauncher: androidx.activity.result.ActivityResultLauncher<String>
) {
    var currentScreen by remember { mutableStateOf(SCREEN_COUNTRY) }
    var selectedCountry by remember { mutableStateOf("") }
    var verificationId by remember { mutableStateOf<String?>(null) }

    when (currentScreen) {
        SCREEN_COUNTRY -> {
            CountrySelectionScreen(
                onCountrySelected = { country ->
                    selectedCountry = country
                    currentScreen = SCREEN_WEBVIEW
                }
            )
        }
        SCREEN_WEBVIEW -> {
            BrowserScreen(
                permissionLauncher = permissionLauncher,
                country = selectedCountry,
                onNavigateToThankYou = { id ->
                    verificationId = id
                    currentScreen = SCREEN_THANK_YOU
                }
            )
        }
        SCREEN_THANK_YOU -> {
            ThankYouScreen(
                verificationId = verificationId,
                onRestartClick = {
                    verificationId = null
                    currentScreen = SCREEN_COUNTRY
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CountrySelectionScreen(onCountrySelected: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    var selectedCountry by remember { mutableStateOf("") }
    var selectedCode by remember { mutableStateOf("") }
    val countries = listOf(
        "United Kingdom" to "gb",
        "Germany" to "de",
        "United States" to "us",
        "United States 2" to "us2",
        "United States 3" to "us3"
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
                    .padding(PADDING_LARGE.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(PADDING_LARGE.dp)
            ) {
                // Logo
                Image(
                    painter = painterResource(id = R.drawable.verifymyage_logo),
                    contentDescription = "VerifyMyAge Logo",
                    modifier = Modifier
                        .width(LOGO_WIDTH.dp)
                        .padding(vertical = 8.dp),
                    contentScale = ContentScale.FillWidth
                )

                // Country Label
                Text(
                    text = "Country",
                    fontSize = FONT_SIZE_NORMAL.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.Black
                )

                // Country Dropdown
                Box(modifier = Modifier.fillMaxWidth()) {
                    OutlinedTextField(
                        value = selectedCountry,
                        onValueChange = {},
                        readOnly = true,
                        placeholder = { 
                            Text(
                                text = "United Kingdom",
                                color = COLOR_TEXT_HINT
                            ) 
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedBorderColor = COLOR_BORDER,
                            focusedBorderColor = COLOR_BORDER,
                            unfocusedContainerColor = Color.White,
                            focusedContainerColor = Color.White,
                            cursorColor = Color.Transparent
                        ),
                        shape = RoundedCornerShape(CORNER_RADIUS.dp),
                        trailingIcon = {
                            Icon(
                                imageVector = androidx.compose.material.icons.Icons.Default.KeyboardArrowDown,
                                contentDescription = "Select Country",
                                tint = COLOR_ICON
                            )
                        },
                        textStyle = TextStyle(
                            fontSize = FONT_SIZE_NORMAL.sp,
                            color = COLOR_TEXT_PRIMARY
                        )
                    )
                    // Overlay a clickable box to open dropdown
                    Box(
                        modifier = Modifier
                            .matchParentSize()
                            .background(Color.Transparent)
                            .clickable { expanded = true }
                    )
                    DropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false },
                        modifier = Modifier
                            .width(IntrinsicSize.Min)
                            .background(Color.White)
                    ) {
                        countries.forEach { (displayName, code) ->
                            DropdownMenuItem(
                                text = { 
                                    Text(
                                        text = displayName,
                                        fontSize = FONT_SIZE_NORMAL.sp,
                                        color = COLOR_TEXT_PRIMARY
                                    ) 
                                },
                                onClick = {
                                    selectedCountry = displayName
                                    selectedCode = code
                                    expanded = false
                                },
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                }

                // Start Button
                Button(
                    onClick = { 
                        if (selectedCode.isNotEmpty()) {
                            onCountrySelected(selectedCode)
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFF47D31)
                    ),
                    shape = RoundedCornerShape(8.dp),
                    enabled = selectedCode.isNotEmpty()
                ) {
                    Text(
                        text = "START",
                        fontSize = FONT_SIZE_NORMAL.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }
    }
}

@Composable
fun ThankYouScreen(
    verificationId: String?,
    onRestartClick: () -> Unit
) {
    var status by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(verificationId) {
        if (!verificationId.isNullOrBlank()) {
            val result = fetchVerificationStatus(verificationId)
            status = result
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
                modifier = Modifier
                    .padding(PADDING_LARGE.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(PADDING_LARGE.dp)
            ) {
                // Logo
                Image(
                    painter = painterResource(id = R.drawable.verifymyage_logo),
                    contentDescription = "VerifyMyAge Logo",
                    modifier = Modifier
                        .width(LOGO_WIDTH.dp)
                        .padding(vertical = 8.dp),
                    contentScale = ContentScale.FillWidth
                )
                if (status.isNullOrBlank() && verificationId != null) {
                    CircularProgressIndicator()
                } else {
                    Spacer(modifier = Modifier.height(16.dp))
                    when (status) {
                        "approved" -> {
                            // Green checkmark in circle
                            Box(
                                modifier = Modifier
                                    .size(72.dp)
                                    .background(
                                        color = Color(0xFF4CAF50),
                                        shape = RoundedCornerShape(50)
                                    )
                                    .align(Alignment.CenterHorizontally),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = androidx.compose.material.icons.Icons.Default.Check,
                                    contentDescription = "Success",
                                    tint = Color.White,
                                    modifier = Modifier.size(48.dp)
                                )
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = "Verification Successful",
                                fontSize = 22.sp,
                                color = Color(0xFF4CAF50),
                                fontWeight = FontWeight.Medium
                            )
                        }
                        "failed" -> {
                            // Red X in circle
                            Box(
                                modifier = Modifier
                                    .size(72.dp)
                                    .background(
                                        color = Color(0xFFD32F2F),
                                        shape = RoundedCornerShape(50)
                                    )
                                    .align(Alignment.CenterHorizontally),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = androidx.compose.material.icons.Icons.Default.Close,
                                    contentDescription = "Failure",
                                    tint = Color.White,
                                    modifier = Modifier.size(48.dp)
                                )
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = "Verification Failed",
                                fontSize = 22.sp,
                                color = Color(0xFFD32F2F),
                                fontWeight = FontWeight.Medium
                            )
                        }
                        else -> {
                            Text(
                                text = "Status: $status",
                                fontSize = 22.sp,
                                color = COLOR_TEXT_PRIMARY,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                    // Verification ID box
                    if (!verificationId.isNullOrBlank()) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color(0xFFF5F5F5), shape = RoundedCornerShape(8.dp))
                                .padding(12.dp)
                        ) {
                            Text(
                                text = "Verification ID:",
                                fontSize = 14.sp,
                                color = COLOR_TEXT_HINT
                            )
                            Text(
                                text = verificationId,
                                fontSize = FONT_SIZE_NORMAL.sp,
                                color = COLOR_TEXT_PRIMARY,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
                // Restart Button
                Button(
                    onClick = onRestartClick,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFF47D31)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(
                        text = "START AGAIN",
                        fontSize = FONT_SIZE_NORMAL.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrowserScreen(
    permissionLauncher: androidx.activity.result.ActivityResultLauncher<String>,
    country: String,
    onNavigateToThankYou: (String?) -> Unit
) {
    var url by remember { 
        mutableStateOf(
            BASE_VERIFICATION_URL.format(country)
        ) 
    }
    var webView by remember { mutableStateOf<WebView?>(null) }
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            WebViewComponent(
                url = url,
                modifier = Modifier.fillMaxSize(),
                onWebViewCreated = { webView = it },
                onNavigateToThankYou = onNavigateToThankYou
            )
        }
    }
}

@Composable
fun WebViewComponent(
    url: String,
    modifier: Modifier = Modifier,
    onWebViewCreated: (WebView) -> Unit = {},
    onNavigateToThankYou: (String?) -> Unit = {}
) {
    AndroidView(
        factory = { context ->
            WebView(context).apply {
                settings.apply {
                    javaScriptEnabled = true
                    domStorageEnabled = true
                    mediaPlaybackRequiresUserGesture = false
                }
                
                webViewClient = object : WebViewClient() {
                    override fun shouldOverrideUrlLoading(
                        view: WebView?,
                        url: String?
                    ): Boolean {
                        return handleCustomURLScheme(url, onNavigateToThankYou)
                    }
                }
                
                webChromeClient = object : WebChromeClient() {
                    override fun onPermissionRequest(request: PermissionRequest?) {
                        request?.let { handlePermissionRequest(it) }
                    }
                }
                
                loadUrl(url)
                onWebViewCreated(this)
            }
        },
        modifier = modifier
    )
}

private fun handleCustomURLScheme(
    url: String?,
    onNavigateToThankYou: (String?) -> Unit
) : Boolean {
    return if (url.isNullOrBlank() || !url.startsWith(DEMO_APP_URL) ) false
    else {
        Log.i("WebView", "Navigated to $url")
        val id = url.toUri().getQueryParameter("verification_id")
        onNavigateToThankYou(id)
        true
    }
}

private fun handlePermissionRequest(request: PermissionRequest) {
    request.resources.forEach { r ->
        if (r == PermissionRequest.RESOURCE_VIDEO_CAPTURE) {
            request.grant(arrayOf(PermissionRequest.RESOURCE_VIDEO_CAPTURE))
        }
    }
}

suspend fun fetchVerificationStatus(verificationId: String): String? = withContext(Dispatchers.IO) {
    val uri = API_VERIFICATION_STATUS_ENDPOINT.format(verificationId)
    Log.d("API_REQUEST", uri)

    try {
        val hmac = generateHmac(API_SECRET_KEY, uri)
        val url = URL("$BASE_URL$uri")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.setRequestProperty("Content-Type", CONTENT_TYPE_JSON)
        connection.setRequestProperty("Authorization", AUTH_HEADER_FORMAT.format(API_KEY, hmac))
        connection.connect()
        val response = connection.inputStream.bufferedReader().readText()
        val json = JSONObject(response)
        Log.d("API_RESPONSE", json.toString())
        return@withContext json.optString("verification_status")
    } catch (e: Exception) {
        e.printStackTrace()
        return@withContext null
    }
}

fun generateHmac(secret: String, data: String): String {
    val mac = Mac.getInstance(HMAC_ALGORITHM)
    mac.init(SecretKeySpec(secret.toByteArray(), HMAC_ALGORITHM))
    val rawHmac = mac.doFinal(data.toByteArray())
    return rawHmac.joinToString("") { "%02x".format(it) }
}