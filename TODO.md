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

### package_21 → chat (23 method_##, 19 var_##)
- [ ] `ChatInstance.as`
- [ ] `ChatRoomInfoPopup.as`
- [ ] `Messages.as`
- [ ] `MessagesItem.as`
- [ ] `DeleteMessageButton.as`
- [ ] `ReplyMessageButton.as`
- [ ] `ReportMessageButton.as`
- [ ] Rename package directory

### package_22 → level_browser (23 method_##, 25 var_##)
- [ ] `Best.as`
- [ ] `BestWeek.as`
- [ ] `Campaign.as`
- [ ] `Newest.as`
- [ ] `Search.as`
- [ ] `Favorites.as`
- [ ] `LevelListing.as`
- [ ] `LevelItem.as`
- [ ] `CourseMenu.as`
- [ ] `Slot.as`
- [ ] `class_250.as` — LevelListing base with pagination (rename class)
- [ ] `class_251.as` — unknown listing component (identify + rename)
- [ ] `class_286.as` — unknown listing component (identify + rename)
- [ ] Rename package directory

### package_23 → social (23 method_##, 6 var_##)
- [ ] `Friends.as`
- [ ] `Following.as`
- [ ] `Online.as`
- [ ] `Guilds.as`
- [ ] `Ignored.as`
- [ ] `PlayersTab.as`
- [ ] `PlayersTabList.as` / `PlayersTabListHolder.as`
- [ ] `PlayersTabListItem.as` / `PlayersTabListItemInfo.as`
- [ ] `PlayersTabGuildListItem.as`
- [ ] `PlayersTabUserListDataLoader.as`
- [ ] Rename package directory

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

### Standalone class files (scattered)
- [ ] `class_239.as` (root) — star graphic effect → rename
- [ ] `background/class_10.as` — level background renderer → rename
- [ ] `ui/class_229.as` — interactive UI element with hover/select → rename
- [ ] `menu/class_4.as` — command hash/auth helper → rename
- [ ] `com/jiggmin/data/class_20.as` — value encryption engine → rename
- [ ] `com/jiggmin/data/class_33.as` — static wrapper for class_20 → rename

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