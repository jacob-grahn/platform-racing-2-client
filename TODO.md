# Phase 1: De-obfuscation TODO

De-obfuscate the codebase by renaming obfuscated packages, classes, methods, and
variables to meaningful names. Ordered from easiest to hardest based on
obfuscation density.

Legend: `method_##` = obfuscated method count, `var_##` = obfuscated variable count

---

## Tier 1: Low Obfuscation (good warm-up)

### ~~package_15 → level_management~~ ✓ DONE
### ~~package_17 → shop~~ ✓ DONE

### ~~package_14 → editor_sidebar~~ ✓ DONE

---

## Tier 2: Moderate Obfuscation

### ~~package_19 → editor_tools~~ ✓ DONE
- class_214 → SidebarEntry, class_215 → MenuButton, class_222 → BackgroundButton, class_228 → BlockPlacerButton

### ~~package_20 → drawing_tools~~ ✓ DONE
- class_269 → ObjectPlacer, class_275 → BlockObjectPlacer
- ObjectDeleter: var_151 → objectBG, method_152 → onEnterFrame, method_458 → updateScale
- CustomCursor: var_411 → disposable

### ~~package_21 → chat~~ ✓ DONE
- ChatInstance: var_655 → timeoutId
- Messages: var_167 → currentPage, var_564 → itemsPerPage, _arg_1 → pageNum
- MessagesItem: _arg_2 → messageId

### ~~package_22 → level_browser~~ ✓ DONE
- class_250 → PaginatedPage, class_251 → ListingPage, class_286 → ListingEntry
- LevelListing: var_280 → showCoursesTimeout
- Search: var_421 → searchTimeout
- LevelItem: confirmSlot/clearSlot _arg_1→a, _local_2/3→slotNum/slot
- CourseMenu: forceTime _local_2 → timeRemaining

### ~~package_23 → social~~ ✓ DONE
- method_138 → addUser, method_179 → addListing

---

## Tier 3: Moderate-High Obfuscation

### ~~package_18 → player_profile~~ ✓ DONE
- AccountInfo: var_510→rankBtnX, var_635→rankBtnDualX
- PartSelector: method_737→makeTriangleMask, method_809→makeDiagonalLine, var_182→epicOverlay
- PartInfoListing: method_653→getListing, method_269→onMouseOver, method_378→onMouseOut
- PartInfoPopup: var_513→itemsPerRow, var_640→itemColWidth, var_632→itemRowHeight, var_289→loadingGraphic

### ~~package_4 → dialogs~~ ✓ DONE
- class_264 → AutoDismissPopup
- GetLevelsPopup: method_539→deselectAll, method_825→clearListings, method_491→selectListing, method_401→onListingClick, method_222→onListingDoubleClick, method_394→updateButtons
- BanMenu: method_238→onBanError
- Popup: _arg_1→addOverlay, _local_2/3→ct/overlay, fadeIn/Out _arg_1→e
- AdminMenu/TempModMenu: _arg_2→popup; PlayerGuestPopup: clickClose _arg_1→e

### ~~Standalone class files~~ ✓ DONE
- class_239 → PointyStar, background/class_10 → LevelBackground (method_338→setArtBackground, method_536→drawCircleGrid)
- ui/class_229 → SelectableButton (method_368→setSelected), menu/class_4 → CommAuth (method_310→getToken)
- class_20 → SecureStore (method_350→setEntry, method_162→getEntry), class_33 → SecureData (method_98→initEncryptor)

---

## Tier 4: Heavy Obfuscation (core systems)

### ~~package_9 → effects~~ ✓ DONE
- class_81 → PhysicsEffect (gravity/bounce/wall base for Hat+Egg)
- class_178 → StarEffect (PointyStar particle at position)
- class_181 → ArrowEffect (Arrow2Graphic floating indicator)
- Effect: var_529→removeTimeout, method_2→scheduleRemove
- ShotEffect: var_154→speed, var_278→angle, var_377→rot, var_493→hitInactiveBlocks, method_62→setSpeed, method_775→setAngle, method_152→onEnterFrame, method_253/method_782/method_389/method_601→checkCollisions/getPlayerAt/updateVelocity/onLifeEnd
- IceWaveShot: var_168→activeCount, var_322→baseAngle, var_278→initialAngle, method_219→skipPastSpawn
- Egg: var_406/466/474/491→MODE_ICE/SLASH/LASER/RANDOM, var_223→nextId, var_486→squashTimeout, var_286→wallCooldown, var_382→attackCooldown, method_333→initRound, method_723→wrapPosition, method_744→remoteRemove
- Slash: var_154→reach, var_609→shooterID, method_66→hitAt
- BlockPiece: var_372→rotVel, name_3→fadeRate, params renamed
- PhysicsEffect: method_720→activate, method_205→deactivate, method_181→isNearLocalPlayer, method_311→isGrounded

### package_6 → game (111 method_##, 189 var_##)
- [ ] `Course.as`
- [ ] `Game.as`
- [ ] `CourseTimer.as`
- [ ] `FinishedPage.as`
- [ ] `MiniMap.as`
- [ ] `DrawingInfo.as`
- [ ] `PlaceArtifact.as` / `SpecialEvent.as`
- [ ] `RaceChat.as`
- [ ] `QuitButton.as`
- [ ] `Hearts.as` / `ExpGain.as` / `LuxPopup.as`
- [ ] All remaining files in package_6 (22 files total)
- [ ] Rename package directory

### package_8 → character (124 method_##, 291 var_##) ← HARDEST
- [ ] `Character.as`
- [ ] `LocalCharacter.as`
- [ ] `RemoteCharacter.as`
- [ ] `class_125.as` — particle emitter base (rename class)
- [ ] `class_126.as` — random color particle emitter (rename class)
- [ ] `class_127.as` — djinn ice effect manager (rename class)
- [ ] `class_129.as` — unknown character effect (identify + rename)
- [ ] `class_179.as` — unknown character effect (identify + rename)
- [ ] `class_240.as` — unknown character effect (identify + rename)
- [ ] Rename package directory

---

## Cross-cutting tasks (do after all packages are renamed)
- [ ] Update all `import` statements across the entire codebase
- [ ] Update `platform-racing-2.fla` references (if possible)
- [ ] Verify the project still compiles
- [ ] Search for any remaining `method_##` references and rename
- [ ] Search for any remaining `var_##` references and rename
- [ ] Search for any remaining `const_##` references and rename
- [ ] Search for any remaining `_arg_#` parameter names and rename