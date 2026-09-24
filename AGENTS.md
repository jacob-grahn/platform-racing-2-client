## Bash Command Constraints
- NEVER use multi-line Bash commands, multi-line heredocs, loops, or conditionals in the terminal.
- NEVER chain multiple commands using `&&`, `||`, or `|`. 
- If a task requires multiple lines or complex logic, write the commands to a temporary shell script file using the file editing tools, then execute that script file in a single line.
- Always execute commands sequentially as single-line, atomic statements.

## Test Suite Constraints
- Use focused deterministic tests for the domain you are working on. Pass one or more domain flags to `./test.sh` (for example, `./test.sh --physics --blocks`, `./test.sh --level-rendering`, or `./test.sh --lobby --items`). Multiple flags run the union of those domains.
- For small generic changes that are not tied to a specific domain, run only the default smoke suite with `./test.sh`.
- Available domain flags are `--audio`, `--blocks`, `--character`, `--crypto`, `--data`, `--effects`, `--gameplay`, `--items`, `--level-editor`, `--level-rendering`, `--lobby`, `--network`, `--physics`, `--runtime`, and `--ui`. Run `./test.sh --help` to see the current list.
- NEVER run the full deterministic suite unless the user explicitly requests it. The full suite is invoked with `./test.sh --full`.
- Do not run `tools/test_all.sh` unless the user explicitly requests full local verification; it includes the full deterministic suite.

## Parity Rules
- Treat `flash/**/*.as` and `flash/platform-racing-2-xfl/` as the behavioral and
  visual specification. Do not silently simplify a workflow because the happy
  path works.
- Temporary drawings, record-only actions, harness redirects, hard-coded data,
  and unsupported buttons are parity gaps and must remain listed here.
- A task is complete only when the real user flow works. Rendering the art or
  recording the requested action is not completion.
- Run only the related test cases for your change, the full suite is a bit slow

## Mobile UI migration gaps
- The mobile title, authentication, landscape Play/browser/search, race-entry,
  My Racer (style/colors, stats/tokens, and loadouts), and game-menu shell are
  implemented, along with the player lists, top-guild directory, Messages inbox,
  reader/composer, profiles, guild detail, account options, and credits. The Vault
  of Magics is slated for removal; do not add a mobile store UI. Detailed level
  information now has a mobile screen sharing its parser and request fields. Prize
  and Lux announcements, My Racer part details, and guild authoring are also mobile.
  The Level Editor now has a mobile canvas, tool palettes, rules, level management,
  save form, and offline test run. Remaining authored destinations include the
  advanced HSV/eyedropper picker and moderator report-list presentation.
- Player lists and the top-guild directory share roster/HTTP loading, parsing,
  duplicate suppression, and cancellation with classic. Profiles share socket/HTTP
  lookup, role/date rules, avatars, navigation, social requests, and guild action fields.
  Guild details and roster use a mobile landscape panel with shared detail
  parsing/loading, member profile links, messaging, join/leave, and role-based
  edit/delete/transfer entry points. Mobile create/edit and transfer forms share
  request construction with classic. Join/leave/delete use mobile confirmations
  and show request status in the guild panel. Staff tools have mobile moderation,
  ban, and admin layouts using the same request and socket command formats.
- Mobile options cover audio, gameplay preferences, music selection, keyboard
  bindings, and account/guild actions. Credential validation and encrypted request
  payloads are shared. Guild create/edit and transfer use mobile forms.
- Messages shares paging/loading/cancellation, filtering/formatting, reply quoting,
  validation, and request fields with classic. Compose outside Messages now reuses
  the mobile editor (profiles/chat/guild management/level sharing). Authenticated
  live inbox and self-addressed send passed with the E2E test account. Live
  report/delete remain outstanding; deterministic tests and isolated browser
  fixtures cover those actions.
- Profile relationship changes and guild invite/kick requests have deterministic
  coverage but need live member/guild-owner validation. Live guest profile browsing
  verifies loading/navigation, not privileged mutations.
- My Racer shares customization saves, rank-token commands, stat/epic rules, and
  loadout application/storage with classic. Part details use the mobile card and
  shared character preview. The optional advanced HSV/eyedropper color picker has
  a landscape mobile presentation. The main mobile color editor provides RGB controls,
  hex entry, and the shared palette.
- The landscape gameplay HUD, independent touch controls, race results, and prize/Lux
  announcements are implemented through ScreenFactory. Results share awards, XP interpolation, and
  confirmed rating submission with classic; race menu/chat/music, held-item action,
  and spectator controls use shared course behavior. The mobile editor shares
  editing and persistence behavior with classic; moderator report handling has
  a landscape presentation. Physical-device gesture validation remains outstanding.
- Multi-touch, cancellation, orientation changes, safe areas, and software keyboards
  still require physical-device validation; browser and deterministic checks are not
  a substitute for a phone test.
- Browser landscape uses a fitted title canvas and portrait rotation hint; native
  orientation, safe areas, and real-device interaction still need validation.
- Mobile Instructions has an in-client landscape guide and an HTML5 link to the
  original hosted guide. See `docs/ui-implementation.md` for the configuration
  commands and remaining presentation gaps.
- Native login socket probing is unsupported; authentication transport targets HTML5.
