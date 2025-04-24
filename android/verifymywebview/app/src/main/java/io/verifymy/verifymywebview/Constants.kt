package io.verifymy.verifymywebview

import androidx.compose.ui.graphics.Color

const val API_KEY = "YOUR_API_KEY"
const val API_SECRET_KEY = "YOUR_API_SECRET_KEY"

// URL Constants
const val BASE_URL = "https://sandbox.verifymyage.com"
const val DEFAULT_CALLBACK_URL = "https://demo-sdx.verifymyage.com/callback" // For convenience

// API Constants
const val API_VERIFICATION_CREATE_ENDPOINT = "/v2/auth/start"
const val API_VERIFICATION_STATUS_ENDPOINT = "/v2/verification/%s/status"
const val HMAC_ALGORITHM = "HmacSHA256"
const val CONTENT_TYPE_JSON = "application/json"
const val AUTH_HEADER_FORMAT = "hmac %s:%s"

// Screen Names
const val SCREEN_PARAMS = "verification-params"
const val SCREEN_VERIFICATION = "verification"
const val SCREEN_RESULT = "result"

// UI Constants
const val LOGO_WIDTH = 200
const val PADDING_NORMAL = 16
const val PADDING_LARGE = 24

// Colors
val COLOR_TEXT_HINT = Color(0xFF9E9E9E)
val COLOR_ICON = Color(0xFF757575)
val COLOR_BORDER = Color(0xFFE0E0E0)
val COLOR_BUTTON = Color(0xFFF47D31)