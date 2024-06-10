// In a production setting these would be set as environment variables in the Cloudflare dashboard
const SECRET = "0c55b6b18a5072a6ba83773679c6a114234798c1be4d8591f628023e9475f11300d97ccc14fd4293cfb038b1253937704e9311677610a15875a48899bc70be91"
const ORIGIN_HOST = "rails-example.staging.mynewsdesk.dev"

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

encodeText = text => new TextEncoder().encode(text) // text to ArrayBuffer
decodeText = buffer => new TextDecoder().decode(buffer) // ArrayBuffer to text

// Function to generate a crypto key from a secret key
async function generateCryptoKey(secretKey) {
  return await crypto.subtle.importKey(
      'raw',
      encodeText(secretKey),
      { name: 'AES-GCM' },
      false,
      ['encrypt', 'decrypt']
  )
}

// SHA256 the secret to ensure it's the correct length
async function hashSecretKey(secretKey) {
  return await crypto.subtle.digest('SHA-256', encodeText(secretKey))
}

function generateRandomToken() {
  return Array.from(crypto.getRandomValues(new Uint8Array(32)))
    .map(int => int.toString(16).padStart(2, '0'))
    .join('')
}

function getCookieValue(cookieString, name) {
  const cookies = cookieString.split('; ')
  for (const cookie of cookies) {
    const [cookieName, cookieValue] = cookie.split('=')
    if (cookieName === name) {
      return cookieValue
    }
  }
  return null
}

async function encryptMessage(secretKey, message) {
  const iv = crypto.getRandomValues(new Uint8Array(12)); // Initialization vector
  const key = await generateCryptoKey(secretKey)
  const encrypted = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, encodeText(message))

  // Combine iv and encrypted data
  const encryptedArray = new Uint8Array(encrypted)
  const combinedArray = new Uint8Array(iv.length + encryptedArray.length)
  combinedArray.set(iv, 0)
  combinedArray.set(encryptedArray, iv.length)

  return btoa(String.fromCharCode(...combinedArray))
}

async function decryptMessage(secretKey, encryptedMessage) {
  const combinedArray = new Uint8Array(atob(encryptedMessage).split('').map(char => char.charCodeAt(0)))
  const iv = combinedArray.slice(0, 12)
  const encryptedArray = combinedArray.slice(12)

  const key = await generateCryptoKey(secretKey)
  const decrypted = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, encryptedArray)

  return decodeText(decrypted)
}

async function handleRequest(request, env, ctx) {
  const requestUrl = new URL(request.url)
  requestUrl.hostname = ORIGIN_HOST

  const secretKey = hashSecretKey(SECRET)

  if (request.method == 'POST' || request.method == 'PUT' || request.method == 'DELETE' || request.method == 'PATCH') {
    // Read form data from a clone to avoid corrupting the original request before we forward it.
    const clonedRequest = request.clone()
    const form = await clonedRequest.formData()
    const csrfToken = form.get('authenticity_token')
    if (!csrfToken) return new Response(`CSRF token not found!\n${form}`, { status: 403 })

    const cookieToken = getCookieValue(request.headers.get('Cookie'), 'csrf_token')
    const decryptedToken = await decryptMessage(secretKey, cookieToken)

    // console.log('csrfToken:', csrfToken)
    // console.log('cookieToken:', cookieToken)
    // console.log('decryptedToken:', decryptedToken)

    if (csrfToken != decryptedToken) return new Response('CSRF validation failed!', { status: 403 })
  }

  const response = await fetch(requestUrl, request)
  let html = await response.text()

  // If the response doesn't contain a CSRF token, we don't need to do anything
  if(!html.includes('<meta name="csrf-token" content=')) return new Response(html, response)

  // Replace CSRF tokens present in <meta> and <input> tags provided by Rails with one generated by the worker
  const token = generateRandomToken()
  html = html
    .replace(/<meta name="csrf-token" content=".*"/, `<meta name="csrf-token" content="${token}"`)
    .replace(/<input type="hidden" name="authenticity_token" value=".*"/, `<input type="hidden" name="authenticity_token" value="${token}"`)

  // Encrypt the token and set it as a cookie
  const encryptedToken = await encryptMessage(secretKey, token)
  const modifiedResponse = new Response(html, response)
  modifiedResponse.headers.append('Set-Cookie', `csrf_token=${encryptedToken}; path=/; HttpOnly; Secure; SameSite=Lax`)

  return modifiedResponse
}