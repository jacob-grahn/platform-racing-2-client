# Browser Networking Blockers

This documents the browser-specific blockers for connecting the Haxe/OpenFL
client to the existing PR2 services. It builds on `docs/networking-inventory.md`.

## Hard Browser Constraints

- Browser targets cannot open raw TCP sockets. The Flash client uses
  `flash.net.Socket` for the live PR2 game connection, so browser OpenFL needs a
  WebSocket endpoint or a WebSocket-to-TCP proxy.
- Flash `crossdomain.xml` does not grant access to browser `fetch`,
  `XMLHttpRequest`, or WebSocket APIs. Browser access depends on CORS,
  WebSocket origin handling, and TLS configuration instead.
- Secure pages cannot connect to insecure live services. If the client is
  served over HTTPS, all HTTP requests must use HTTPS and all socket traffic
  must use WSS.
- Browser JavaScript cannot set arbitrary forbidden headers. The Flash
  `Request-Destination` header path should not be treated as portable browser
  behavior.
- Browser clients cannot safely hold secret protocol material. Existing client
  keys and salts from `Env.as` are already client-visible and should be treated
  as compatibility values, not as server-side trust boundaries.

## HTTP Risks To Verify

- `https://pr2hub.com/files/server_status_2.txt` must send CORS headers that
  allow the deployed browser client origin.
- `https://pr2hub.com/login.php` must accept browser form POSTs from the client
  origin and return readable CORS responses for success and error states.
- Any level, profile, lobby-adjacent, captcha, shop, moderation, or guild
  endpoints needed by the initial browser flow must have matching HTTPS and
  CORS behavior.
- Redirects must stay on HTTPS endpoints that preserve CORS headers.
- Cookies or session headers, if introduced later, must define explicit
  `SameSite` and secure behavior for cross-origin or same-origin deployment.

## WebSocket Requirements

Production browser socket traffic should use same-origin WSS paths such as:

```text
wss://platformracing.com/servers/<server_name>
```

The server-side endpoint or proxy must:

- Accept browser WebSocket upgrades over TLS.
- Validate the request origin according to the production deployment policy.
- Map the path or selected metadata to the intended PR2 game server.
- Preserve the existing PR2 command payload semantics after the WebSocket
  connection is established.
- Frame text payloads so the client can continue using the PR2 backtick-delimited
  commands and EOT terminator.
- Propagate close and error states clearly enough for the client to show
  connection failure, login failure, and disconnected states.

## Client Contract

The browser client should treat server-list entries as selection metadata, not
as directly reachable raw TCP endpoints. For the initial implementation:

- Use a configured WebSocket base URL or same-origin path prefix.
- Derive the selected server path from stable server-list metadata such as
  `server_name` or `server_id`.
- Keep path-to-raw-server mapping outside this repo unless the production API
  explicitly exposes browser-safe WebSocket URLs.
- Keep the socket protocol parser shared with the Flash inventory semantics:
  hash prefix, sequence number, command name, backtick-delimited args, and EOT
  message terminator.

## Spike Order

1. Fetch `server_status_2.txt` from a browser build and record CORS behavior.
2. Open a configured same-origin or local WebSocket endpoint.
3. Send `request_login_id` through the WebSocket path and parse `setLoginID`.
4. Attempt the `/login.php` request only with local, uncommitted credentials.
5. Confirm whether socket `loginSuccessful` arrives after the HTTP login step.

Until server-side WebSocket support exists, the browser client cannot complete
the real PR2 lobby connection on its own.
