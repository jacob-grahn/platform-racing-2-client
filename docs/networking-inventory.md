# PR2 Networking Inventory

This inventory summarizes the Flash networking code that the Haxe/OpenFL port
needs to preserve or replace. Source references are from the decompiled AS3
under `flash/`.

## Entry Points

- `Main.as` defines the production service roots:
  - `Main.baseURL = "https://pr2hub.com"`
  - `Main.levelsURL = "https://pr2hub.com/levels"`
- `Main.init()` calls `Security.loadPolicyFile(baseURL + "/crossdomain.xml")`
  for Flash runtime access, initializes `CommandHandler`, and calls
  `CommAuth.init()`.
- `LoginPage` starts periodic server-list loading through `CheckServers`.
- `ServerSelectPopup` stores the selected server object in `Main.server`.
- `ConnectingPopup` creates `Main.socket = new PR2Socket()` and connects to
  `Main.server.address` / `Main.server.port`.
- `LoggingInPopup` combines a socket login handshake with an HTTP login request
  before entering the lobby.

## HTTP Layer

`SuperLoader` wraps `URLLoader` for HTTP requests.

- Adds cache/auth query or form fields when `useRandomNum` is enabled:
  - `rand`
  - `token`
  - `beta=1` when `Main.beta`
- Supports two parse modes:
  - URL-encoded data via `URLVariables`
  - JSON via `JSON.parse`
- Dispatches `SuperLoader.parsedData` on success.
- Treats explicit `error` fields or false `success` fields as errors.
- For trusted standalone Flash clients, adds an encrypted
  `Request-Destination` header using `Env.URL_PASS_*`. This appears to be a
  Flash-local-loader allowance and should not be assumed necessary for a browser
  OpenFL client until tested.

Important HTTP endpoints found in the login/server path:

- `GET Main.baseURL + "/files/server_status_2.txt"`
  - Loaded by `CheckServers`.
  - JSON response with a `servers` array.
  - Each server object is expected to include `address`, `port`, `server_id`,
    `server_name`, `status`, `population`, `guild_id`, and `happy_hour`.
- `POST Main.baseURL + "/login.php"`
  - Loaded by `LoggingInPopup`.
  - Sends form fields `i` and `build`.
  - `i` is AES-CBC encrypted JSON using `Env.LOGIN_KEY` and `Env.LOGIN_IV`.
  - The encrypted JSON includes `user_name`, `user_pass`, `build`, `server`,
    `domain`, `remember`, `login_id`, and `award_kong`.

Other major HTTP families discovered by search:

- Account/profile/social: `messages_get.php`, `guild_info.php`,
  `get_player_info.php`, `user_list_get.php`, `guilds_top.php`
- Level browser/data: list files under `/files/lists/`, `search_levels.php`,
  `level_data.php`, level txt files under `Main.levelsURL`
- Level management: `upload_level.php`, `delete_level.php`,
  `favorite_levels_modify.php`, `favorite_levels_get.php`
- Moderation/admin: `ban_user.php`, `level_moderate.php`,
  `/mod/archive_report.php`
- Miscellaneous gameplay/site services: cat captcha endpoints, artifact
  placement, vault/shop endpoints, Discord verification

## Socket Layer

`PR2Socket` extends Flash `Socket`, so the live game protocol uses raw TCP.

Connection flow:

1. `ConnectingPopup` connects to the selected server.
2. On `Event.CONNECT`, `PR2Socket.requestLoginId()` sends
   `request_login_id`.
3. `ConnectingPopup` waits for `setLoginID`.
4. `LoggingInPopup` sends the encrypted HTTP `/login.php` request using that
   login id.
5. The socket side must also receive `loginSuccessful` before the lobby opens.

Outbound socket frame format:

```text
<hash3>`<sendNum>`<command>`<arg1>`...<EOT>
```

- `EOT` is character code `4`.
- `sendNum` starts at `0` per socket and increments before every write.
- `sendNum == 12` is skipped.
- `hash3` is the first three hex characters of:

```text
md5(CommAuth.getToken(Main.server.server_id) + "<sendNum>`<command>`...")
```

Inbound socket frame format matches the same hash and delimiter structure:

```text
<hash3>`<num>`<command>`<arg1>`...<EOT>
```

- `CommandHandler.addText()` buffers partial reads until `EOT`.
- `CommandHandler.handleResponse()` verifies `hash3`, rejects non-increasing
  sequence numbers, and dispatches by command name.
- The server can request resync with `resend`; the Flash client currently closes
  the socket when its local send number is behind the requested number.

Core commands registered globally:

- `ping`
- `message`
- `setRank`
- `setGroup`
- `startGame`
- `resend`
- `pmNotify`
- moderator/prizer/group flag commands
- `areYouHuman`
- `tournamentMode`
- `guildChange`
- `setServerOwner`
- `wearingHat`

High-volume gameplay and lobby command usage is spread through UI/gameplay
classes via `Main.socket.write(...)`, including chat room changes, level slot
selection, game-room changes, exact position, finish/quit race, block
activation, item/effect commands, player info requests, customization updates,
and moderation actions.

## Auth And Crypto Helpers

- `Env.as` contains the protocol keys, IVs, salts, and socket communication
  passphrase used by the Flash client.
- `Encryptor` wraps Hurlant AES-CBC with a custom `AESPad`, taking Base64 keys
  and IVs and returning Base64 ciphertext.
- `SecureStore` stores values obfuscated in memory. For socket auth,
  `CommAuth.init()` stores `Env.COMM_PASS` under server token id `1` and a
  separate hard-coded token for server id `10`.
- `CommAuth.getToken(server_id)` returns token id `10` only for server id `10`;
  all other servers use token id `1`.
- HTTP and level flows also rely on MD5 salts from `Env.as`.

## Port Implications

- Browser OpenFL cannot rely on Flash `Socket`, Flash crossdomain policy files,
  or Flash `URLLoader` security behavior.
- HTTP flows can likely be ported to `openfl.net.URLLoader` or a Haxe HTTP
  library, but CORS and response headers need to be tested against the live
  service.
- Browser OpenFL cannot open raw TCP sockets, but the gameserver now supports
  WebSocket clients on the multiplayer transport. The server sniffs the first
  bytes of each connection: legacy Flash/raw clients continue down the raw
  socket path, while WebSocket clients receive an RFC 6455 handshake and then
  have decoded frame payloads fed into the same PR2 command buffer. The port
  should keep the PR2 socket command writer/parser nearly identical to Flash and
  send the same `chr(0x04)`-terminated payloads inside WebSocket text frames.
- The next networking task should prove whether the browser build can fetch
  `server_status_2.txt` directly, open the configured gameserver WebSocket
  endpoint, send `request_login_id`, and parse `setLoginID`.

## Browser Transport Notes

- Browser access depends on CORS, WebSocket origin handling, and TLS
  configuration. Flash `crossdomain.xml` only applies to the Flash runtime.
- If the client is served over HTTPS, all HTTP requests must use HTTPS and all
  socket traffic must use WSS.
- Browser JavaScript cannot set arbitrary forbidden headers. The Flash
  `Request-Destination` header path should not be treated as portable browser
  behavior.
- Browser clients cannot safely hold secret protocol material. Existing client
  keys and salts from `Env.as` are already client-visible compatibility values,
  not server-side trust boundaries.
- The browser client should treat server-list `address` / `port` values as the
  selected multiplayer server, but it must build a `ws://` or `wss://` URL for
  browser transport instead of trying to open raw TCP.
- Production browser socket traffic should use WSS. Any same-origin path,
  reverse-proxy route, or direct `host:port` URL is a deployment concern; the
  PR2 application payload should stay unchanged after the WebSocket handshake.
- The WebSocket endpoint should accept browser upgrades over TLS, preserve PR2
  command payload semantics, and surface close/error states clearly enough for
  connection, login, and disconnection UI. Origin validation, routing, and TLS
  termination may live at the deployment/proxy layer if the multiplayer server
  is not exposed directly.
- A WebSocket frame may contain one or more PR2 messages and PR2 messages may be
  split across frames. The client-side parser should continue using the
  `chr(0x04)` delimiter after WebSocket payload decode, just as Flash did after
  socket reads.
- Initial browser networking spike order:
  1. Fetch `server_status_2.txt` from a browser build and record CORS behavior.
  2. Open a configured same-origin or local gameserver WebSocket endpoint.
  3. Send the normal `request_login_id` command over WebSocket.
  4. Parse `setLoginID`.
  5. Attempt `/login.php` only with local, uncommitted credentials.
  6. Confirm whether socket `loginSuccessful` arrives after the HTTP login step.
