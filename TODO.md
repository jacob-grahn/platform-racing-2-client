# Phase 1: De-obfuscation TODO

De-obfuscate the codebase by renaming obfuscated packages, classes, methods, and
variables to meaningful names. Ordered from easiest to hardest based on
obfuscation density.

Run python3 check_fla_linkage.py after each rename cycle

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

### ~~package_6 → gameplay~~ ✓ DONE
- Hearts: method_798→setHearts, method_758→getHeartCount
- CourseTimer: var_308→tickInterval, var_480→paused, method_189→getElapsedSecs, method_362→getTimeLeft, method_467→tick, method_425→resume, method_588→pulseLowTime
- Game: var_202→finishedPage, var_463→pendingAwards, var_452→expOld, var_465→expNew, var_347→expToRank, method_196→maybeShowFinishedPage, method_185→markPlayerDone, method_682→submitHatFinishStat
- DrawingInfo: method_138→addPlayer
- MiniMap: var_16→blockSprite, var_49→finishSprite, method_680→addBlock, method_263→applyScale, method_182→scaleChildDots
- CatCaptcha: var_181→captchaLoader, var_191→submitLoader, method_694→loadCaptcha, method_441→onCaptchaLoad, method_561→showCatImages, method_465→onSubmitComplete, method_99→onError
- class_101→CatImage (method_566→onImgLoad); PrizePopup: var_207→epicFlash; ExpGain: var_575→expStep
- Course: var_9→localPlayer (cross-file: Slash.as, PhysicsEffect.as, TestCourse.as, Game.as)

### ~~package_8 → character~~ ✓ DONE
- Character: var_387→djinnEffects, var_140→jetSoundChannel, var_301→curAnim, var_269→recoveryFrames, var_448→updateInterval, var_215→framesSinceUpdate, var_4→store, var_375→activeEmitter
- Character methods: method_58→updateSegs, method_51→beginRecovery, method_106→recoveryTick, method_623→startSuperJumpWobble, method_820→endSuperJumpWobble, method_156→superJumpWobbleTick, method_207→jetPackTick, method_200→setEmitter, method_190→clearEmitter, method_576→beginArrowSparkles
- LocalCharacter: const_12→JUMP_VEL, var_573→epnuInterval, var_535→cowboyCheckInterval, var_390→prevParent, var_24→targetVelX, var_240→waterTicks, var_523→baseAccelFactor, var_599→baseVelFactor, var_147→accelFactor, var_524→velFactor, var_189→halfWidth, var_325→charHeight, var_407→standingSegX, var_366→standingSegY, var_157→maxSpeed, var_281→jumpHeld, var_150→crouchCharge
- LocalCharacter block refs: var_630→floorLeft, var_469→floorCenter, var_657→floorRight, var_329→wallLeft, var_658→midBlock, var_296→wallRight, var_654→ceilLeft, var_262→ceiling, var_631→ceilRight, var_306→headBlock, var_297→topBlock
- LocalCharacter net state: var_530→lastNetScaleX, var_577→lastNetState, var_623→lastNetItem
- LocalCharacter methods: method_76→processBlocks, method_261→updateGrounded, method_41→refreshBlockRefs
- RemoteCharacter: var_19→updateQueue, var_180→catchupRate; method_801→setVar, method_667→setExactPos, method_76→processBlockTouches, method_128→touchBlockAt, method_662→onHeart
- class_125→ParticleEmitter (var_416→intervalId, var_444→intervalMs, method_571→tick)
- class_126→RainbowStarEmitter; class_127→DjinnEffects; class_129→ArrowSparkleEmitter
- class_179→PositionedParticleEmitter (var_128→params, var_567→offsetX, var_608→offsetY, method_470→getTargetPoint)
- class_240→PhysicsParticle (var_578→maxLife, var_275→curAlpha, method_508→makeGraphic, method_38→randRange, method_251→onEnterFrame)
- Cross-file: var_24→targetVelX (Block.as, WaterBlock.as), var_407/366→standingSegX/Y (Block.as, SafetyBlock.as, WaterBlock.as), var_189/325→halfWidth/charHeight (Block.as, MineBlock.as), var_4→store (Block.as, CrumbleBlock.as, Course.as), const_12→JUMP_VEL (Block.as), method_576→beginArrowSparkles (Game.as)
- Dead fields skipped: var_670 (Character), var_669 (LocalCharacter)

---

## Cross-cutting tasks (do after all packages are renamed)
- [ ] Update all `import` statements across the entire codebase
- [ ] Update `platform-racing-2.fla` references (if possible)
- [ ] Verify the project still compiles
- [ ] Search for any remaining `method_##` references and rename
- [ ] Search for any remaining `var_##` references and rename
- [ ] Search for any remaining `const_##` references and rename
- [ ] Search for any remaining `_arg_#` parameter names and rename