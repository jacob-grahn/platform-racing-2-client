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

### package_18 → player_profile (37 method_##, 46 var_##)
- [ ] `AccountInfo.as`
- [ ] `PlayerDisplay.as`
- [ ] `LoadoutsPopup.as`
- [ ] `Preset.as` / `PresetListing.as` / `Presets.as`
- [ ] `PartSelector.as`
- [ ] `PartInfo/` subdirectory files
- [ ] `RandomizeStyleButton.as`
- [ ] Rename package directory

### package_4 → dialogs (84 method_##, 22 var_##)
- [ ] `AdminMenu.as`
- [ ] `ConfirmPopup.as`
- [ ] `InfoPopup.as`
- [ ] `MessagePopup.as`
- [ ] `LevelInfoPopup.as`
- [ ] `GuildPopup.as` / `GuildJoinPopup.as` / `GuildMemberName.as`
- [ ] `ExternalLinkPopup.as`
- [ ] `LevelReportPopup.as` / `GetLevelsPopup.as`
- [ ] `class_264.as` — auto-dismiss InfoPopup (rename class)
- [ ] All remaining files in package_4 (34 files total)
- [ ] Rename package directory

### ~~Standalone class files~~ ✓ DONE
- class_239 → PointyStar, background/class_10 → LevelBackground (method_338→setArtBackground, method_536→drawCircleGrid)
- ui/class_229 → SelectableButton (method_368→setSelected), menu/class_4 → CommAuth (method_310→getToken)
- class_20 → SecureStore (method_350→setEntry, method_162→getEntry), class_33 → SecureData (method_98→initEncryptor)

---

## Tier 4: Heavy Obfuscation (core systems)

### package_9 → effects (70 method_##, 89 var_##)
- [ ] `Effect.as`
- [ ] `BlockPiece.as`
- [ ] `Egg.as`
- [ ] `Hat.as`
- [ ] `ZoomableAnimated.as`
- [ ] `IceWaveShot.as` / `LaserShot.as`
- [ ] `MineAppear.as` / `MineExplode.as`
- [ ] `ShotEffect.as` / `Slash.as` / `Sting.as` / `TeleportPop.as` / `Zap.as`
- [ ] `class_81.as` — projectile physics base (rename class)
- [ ] `class_178.as` — star particle effect (rename class)
- [ ] `class_181.as` — unknown effect (identify + rename)
- [ ] `class_182.as` — unknown effect (identify + rename)
- [ ] Rename package directory

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