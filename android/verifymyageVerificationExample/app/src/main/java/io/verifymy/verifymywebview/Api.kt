package io.verifymy.verifymywebview

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

fun generateHmac(secret: String, data: String): String {
    val mac = Mac.getInstance(HMAC_ALGORITHM)
    mac.init(SecretKeySpec(secret.toByteArray(), HMAC_ALGORITHM))
    val rawHmac = mac.doFinal(data.toByteArray())
    return rawHmac.joinToString("") { "%02x".format(it) }
}

suspend fun createVerification(params: VerificationParams): BasicVerification? =
    doRequest(
        API_VERIFICATION_CREATE_ENDPOINT,
        "POST",
        JSONObject().apply {
            put("country", params.country)
            put("redirect_url", params.redirectUrl)
            params.businessSettingsId.takeIf { it.isNotBlank() }
                ?.let { put("business_settings_id", it) }
            params.externalUserId.takeIf { it.isNotBlank() }?.let { put("external_user_id", it) }
        }
    ).let {
        BasicVerification(
            id = it.getString("verification_id"),
            url = it.getString("start_verification_url"),
            status = it.getString("verification_status")
        )
    }

suspend fun fetchVerificationStatus(verificationId: String): String? =
    doRequest(
        API_VERIFICATION_STATUS_ENDPOINT.format(verificationId),
        "GET",
        null
    ).optString("verification_status")

suspend fun doRequest(endpoint: String, method: String, body: JSONObject?): JSONObject =
    withContext(Dispatchers.IO) {
        Log.d("API", "$method - $endpoint - Body: $body")
        val data = body?.toString() ?: endpoint
        val hmac = generateHmac(API_SECRET_KEY, data)

        val url = URL("$BASE_URL$endpoint")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = method
        connection.setRequestProperty("Content-Type", CONTENT_TYPE_JSON)
        connection.setRequestProperty("Authorization", AUTH_HEADER_FORMAT.format(API_KEY, hmac))

        body?.let { b ->
            connection.doOutput = true
            connection.outputStream.use { it.write(b.toString().toByteArray()) }
        }

        connection.connect()

        when (connection.responseCode) {
            in 200..399 ->  return@withContext connection.inputStream.bufferedReader().readText().let {
                JSONObject(it)
            }
            else -> connection.errorStream.bufferedReader().readText().let {
                Log.d("WebView", "Failed to $method - $url -Response code: ${connection.responseCode} - Response body: $it")
                throw Exception(it)
            }
        }
    }
