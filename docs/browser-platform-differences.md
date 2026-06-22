# Browser Platform Differences

The HTML5 client permits only the three platform-required differences below.
They are transport or startup adapters, not permission to change PR2 commands,
payloads, timing after startup, visible state, or failure handling.

## Game-server transport

- **Flash behavior:** `flash/com/jiggmin/data/PR2Socket.as` extends
  `flash.net.Socket` and opens a raw TCP connection to the selected host and
  port.
- **Browser constraint:** the web platform exposes the
  [WebSocket API](https://websockets.spec.whatwg.org/) to page scripts, not
  Flash's raw TCP socket API.
- **Adapter:** `haxe/src/pr2/net/LobbySocket.hx` opens `ws://` or `wss://` using
  `ServerInfo.websocketUrl()`. The server or deployment edge must expose that
  WebSocket endpoint.
- **Parity boundary:** the WebSocket message body is still the original PR2
  frame: three-character MD5 prefix, send number, backtick-delimited command,
  and `0x04` terminator. `LoginSocketProtocol` owns this encoding. A WebSocket
  implementation must not rename commands, translate fields, or create a new
  connection during page transitions.

## HTTP origin

- **Flash behavior:** URL loaders call `https://pr2hub.com` directly.
- **Browser constraint:** script can read a cross-origin response only when the
  response opts into the
  [Fetch CORS protocol](https://fetch.spec.whatwg.org/#http-new-header-syntax).
  The PR2 endpoints do not return the required CORS headers.
- **Adapter:** `ServerConfig` accepts a same-origin path prefix such as `/api`;
  `tools/dev_proxy.py` demonstrates forwarding that prefix to pr2hub.com. A
  production deployment must provide the equivalent HTTPS reverse proxy.
- **Parity boundary:** the proxy may change only the network origin. It must
  preserve the HTTP method, path, query, form body, response status/body, and
  authentication cookie behavior. It must not reinterpret PR2 responses.

## Initial audio activation

- **Flash behavior:** sounds can start as soon as their timeline or page starts
  them.
- **Browser constraint:** a browser may keep an `AudioContext` suspended until
  it is allowed to start; Web Audio autoplay uses user activation. See the
  [Web Audio API startup rules](https://www.w3.org/TR/webaudio-1.0/#allowed-to-start)
  and [autoplay policy guidance](https://www.w3.org/TR/autoplay-detection/).
- **Adapter:** `BrowserAudioUnlock.install()` initializes the browser audio
  backend and resumes it on the first pointer, touch, click, or keyboard
  gesture, then removes its listeners.
- **Parity boundary:** audio may be silent before the first accepted gesture.
  After activation, track selection, loop points, volume, pan, mute state, and
  page-transition timing remain parity requirements.

## Explicitly not accepted as browser differences

Frame-rate throttling in a background tab, storage eviction, popup blocking,
browser-specific rendering defects, and reconnect behavior are deployment or
runtime conditions to handle and test. They do not justify changed game state,
lost settings during normal storage operation, bypassed confirmation UI,
different artwork, or altered protocol behavior.

Any newly discovered difference must identify the original Flash behavior, an
authoritative browser-platform constraint, the narrow adapter, and the exact
parity boundary before it is added here.
