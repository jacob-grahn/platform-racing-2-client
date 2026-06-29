package pr2.tools;

import sys.io.File;

class SourceClassCoverageInventoryTest {
	private static var assertions:Int = 0;

	private static final BACKGROUND_CLASSES:Array<String> = [
		"Background",
		"BlockBackground",
		"BlockGridLines",
		"DrawableBackground",
		"EffectBackground",
		"LevelBackground",
		"Map",
		"ObjectBackground"
	];

	private static final ITEM_CLASSES:Array<String> = [
		"IceWave",
		"Item",
		"Items",
		"JetPack",
		"LaserGun",
		"Lightning",
		"Mine",
		"SpeedBurst",
		"SuperJump",
		"Sword",
		"Teleport"
	];

	private static final BLOCK_CLASSES:Array<String> = [
		"ArrowBlock",
		"ArrowDownBlock",
		"ArrowLeftBlock",
		"ArrowRightBlock",
		"ArrowUpBlock",
		"BasicBlock",
		"Block",
		"Blocks",
		"BrickBlock",
		"CrumbleBlock",
		"CustomStatsBlock",
		"FinishBlock",
		"HappyBlock",
		"HeartBlock",
		"IceBlock",
		"InfItemBlock",
		"ItemBlock",
		"MineBlock",
		"MoveBlock",
		"PushBlock",
		"RotateBlock",
		"RotateLeftBlock",
		"RotateRightBlock",
		"SadBlock",
		"SafetyBlock",
		"StartBlock",
		"SupplyBlock",
		"TeleportBlock",
		"TimeBlock",
		"VanishBlock",
		"WaterBlock"
	];

	private static final BLOCK_OPTION_CLASSES:Array<String> = [
		"BlockOptions",
		"CustomStatsBlockOptions",
		"ItemBlockOptions",
		"StatBlockOptions",
		"TeleportBlockOptions"
	];

	private static final CHARACTER_CLASSES:Array<String> = [
		"ArrowSparkleEmitter",
		"Character",
		"DjinnEffects",
		"LocalCharacter",
		"ParticleEmitter",
		"PhysicsParticle",
		"PositionedParticleEmitter",
		"RainbowStarEmitter",
		"RemoteCharacter"
	];

	private static final CHAT_CLASSES:Array<String> = [
		"ChatInstance",
		"ChatRoomInfoPopup",
		"DeleteMessageButton",
		"Messages",
		"MessagesItem",
		"ReplyMessageButton",
		"ReportMessageButton"
	];

	private static final DIALOG_CLASSES:Array<String> = [
		"AdminMenu",
		"AutoDismissPopup",
		"BanMenu",
		"ChangePasswordPopup",
		"ChooseLevelModModePopup",
		"ConfirmPopup",
		"CreateGuildPopup",
		"DiscordVerificationPopup",
		"ExternalLinkPopup",
		"GetLevelsPopup",
		"GuildJoinPopup",
		"GuildMemberName",
		"GuildPopup",
		"HatsMenu",
		"HoverPopup",
		"InfoPopup",
		"ItemMenu",
		"LevelInfoPopup",
		"LevelReportPopup",
		"LogoutPassPopup",
		"MessagePopup",
		"OptionsArtQualityMenu",
		"OptionsPopup",
		"OptionsSongsMenu",
		"OutfitPopup",
		"PMRFCodesPopup",
		"PlayerGuestPopup",
		"PlayerPopup",
		"Popup",
		"SendMessagePopup",
		"SetEmailPopup",
		"TempModMenu",
		"TransferGuildPopup",
		"UploadingPopup"
	];

	private static final SOCIAL_CLASSES:Array<String> = [
		"Following",
		"Friends",
		"Guilds",
		"Ignored",
		"Online",
		"PlayersTab",
		"PlayersTabGuildListItem",
		"PlayersTabList",
		"PlayersTabListHolder",
		"PlayersTabListItem",
		"PlayersTabListItemInfo",
		"PlayersTabUserListDataLoader"
	];

	private static final EFFECT_CLASSES:Array<String> = [
		"ArrowEffect",
		"BlockPiece",
		"Effect",
		"Egg",
		"Hat",
		"IceWaveShot",
		"LaserShot",
		"MineAppear",
		"MineExplode",
		"PhysicsEffect",
		"ShotEffect",
		"Slash",
		"StarEffect",
		"Sting",
		"TeleportPop",
		"Zap"
	];

	private static final GAMEPLAY_CLASSES:Array<String> = [
		"CatCaptcha",
		"CatImage",
		"Course",
		"CourseTimer",
		"DrawingInfo",
		"ExpGain",
		"FinishedPage",
		"Game",
		"Hearts",
		"ItemDisplay",
		"LuxPopup",
		"MiniMap",
		"Modes",
		"MusicSelection",
		"PlaceArtifact",
		"PrizePopup",
		"QuitButton",
		"RaceChat",
		"SpecialEvent",
		"SpectatePicker",
		"StatsDisplay",
		"TestCourse"
	];

	private static final LEVEL_BROWSER_CLASSES:Array<String> = [
		"Best",
		"BestWeek",
		"Campaign",
		"CourseMenu",
		"Favorites",
		"LevelItem",
		"LevelListing",
		"ListingEntry",
		"ListingPage",
		"Newest",
		"PaginatedPage",
		"Search",
		"Slot"
	];

	private static final LEVEL_EDITOR_CLASSES:Array<String> = [
		"BlockObject",
		"DrawObject",
		"DrawingPopup",
		"GetLevelsPopupItem",
		"GetReportedLevelsPopupItem",
		"HatPicker",
		"LevelEditor",
		"LevelEditorMenu",
		"TextObject"
	];

	private static final LEVEL_MANAGEMENT_CLASSES:Array<String> = [
		"ChooseLevelsModePopup",
		"DeletingLevelPopup",
		"GetLevelReports",
		"GetLevels",
		"HandleLevelReportPopup",
		"LoadingLevelPopup",
		"SaveLevelPopup",
		"UploadingLevelPopup"
	];

	private static final LOBBY_CLASSES:Array<String> = [
		"Lobby",
		"LobbyLeft",
		"LobbyRight",
		"LobbySide"
	];

	private static final PAGE_CLASSES:Array<String> = [
		"ArtifactHint",
		"Chat",
		"GamePage",
		"Page",
		"PageHolder"
	];

	private static final PLAYER_PROFILE_CLASSES:Array<String> = [
		"AccountInfo",
		"LoadoutsPopup",
		"PartInfo/PartInfoListing",
		"PartInfo/PartInfoPopup",
		"PartInfo/PartPopup",
		"PartSelector",
		"PlayerDisplay",
		"Preset",
		"PresetListing",
		"Presets",
		"RandomizeStyleButton"
	];

	private static final SOUND_CLASSES:Array<String> = [
		"NoodleTown",
		"SoundEffects"
	];

	private static final MENU_CLASSES:Array<String> = [
		"CheckServers",
		"CommAuth",
		"ConnectingPopup",
		"CreateAccountPopup",
		"CreditsPopup",
		"ForgotPassPopup",
		"IntroPage",
		"KongOutfitPopup",
		"LoggingInPopup",
		"LoginPage",
		"LoginPopup",
		"ServerSelectPopup"
	];

	private static final UI_CLASSES:Array<String> = [
		"ArrowButtons",
		"CustomCursor",
		"CustomScrollBar",
		"EmblemLoader",
		"GameSound",
		"GuildName",
		"LobbyTab",
		"LoginPageMenuButton",
		"MuteButton",
		"PageNavigation",
		"ProgressBar",
		"RatingSelect",
		"SelectableButton",
		"StatSlider",
		"StatsSelect",
		"TabsHolder"
	];

	private static final COM_CLASSES:Array<String> = [
		"adobe/crypto/MD5",
		"adobe/utils/IntUtil",
		"hurlant/crypto/hash/IHash",
		"hurlant/crypto/hash/MD5",
		"hurlant/crypto/prng/ARC4",
		"hurlant/crypto/prng/IPRNG",
		"hurlant/crypto/prng/Random",
		"hurlant/crypto/symmetric/AESKey",
		"hurlant/crypto/symmetric/CBCMode",
		"hurlant/crypto/symmetric/ICipher",
		"hurlant/crypto/symmetric/IMode",
		"hurlant/crypto/symmetric/IPad",
		"hurlant/crypto/symmetric/IStreamCipher",
		"hurlant/crypto/symmetric/ISymmetricKey",
		"hurlant/crypto/symmetric/IVMode",
		"hurlant/crypto/symmetric/PKCS5",
		"hurlant/util/Base64",
		"hurlant/util/Hex",
		"hurlant/util/Memory",
		"jcward/workers/BitString",
		"jcward/workers/JPEGEncoder",
		"jiggmin/ColorPicker/ColorChoices",
		"jiggmin/ColorPicker/ColorPicker",
		"jiggmin/ColorPicker/ColorPickerPopup",
		"jiggmin/ColorPicker/CursorEyedropper",
		"jiggmin/data/AESPad",
		"jiggmin/data/ColorUtil",
		"jiggmin/data/CommandHandler",
		"jiggmin/data/Data",
		"jiggmin/data/Encryptor",
		"jiggmin/data/EpicFlash",
		"jiggmin/data/GpNotification",
		"jiggmin/data/HTMLNameMaker",
		"jiggmin/data/Memory",
		"jiggmin/data/Objects",
		"jiggmin/data/PR2Socket",
		"jiggmin/data/Random",
		"jiggmin/data/SWFStats",
		"jiggmin/data/SavedAccounts",
		"jiggmin/data/SecureData",
		"jiggmin/data/SecureStore",
		"jiggmin/data/Settings",
		"jiggmin/data/Time",
		"jiggmin/data/UnreadNotif",
		"jiggmin/pixelEffects/PixelEffect1",
		"jiggmin/pixelEffects/pixels/SegPixel"
	];

	public static function main():Void {
		var inventory = File.getContent("docs/source-class-coverage.md");
		for (name in BACKGROUND_CLASSES) {
			assertContains(inventory, '`flash/background/$name.as`', 'inventory lists flash/background/$name.as');
		}
		for (name in ITEM_CLASSES) {
			assertContains(inventory, '`flash/items/$name.as`', 'inventory lists flash/items/$name.as');
		}
		for (name in BLOCK_CLASSES) {
			assertContains(inventory, '`flash/blocks/$name.as`', 'inventory lists flash/blocks/$name.as');
		}
		for (name in BLOCK_OPTION_CLASSES) {
			assertContains(inventory, '`flash/blocks/options/$name.as`', 'inventory lists flash/blocks/options/$name.as');
		}
		for (name in CHARACTER_CLASSES) {
			assertContains(inventory, '`flash/character/$name.as`', 'inventory lists flash/character/$name.as');
		}
		for (name in CHAT_CLASSES) {
			assertContains(inventory, '`flash/chat/$name.as`', 'inventory lists flash/chat/$name.as');
		}
		for (name in DIALOG_CLASSES) {
			assertContains(inventory, '`flash/dialogs/$name.as`', 'inventory lists flash/dialogs/$name.as');
		}
		for (name in SOCIAL_CLASSES) {
			assertContains(inventory, '`flash/social/$name.as`', 'inventory lists flash/social/$name.as');
		}
		for (name in EFFECT_CLASSES) {
			assertContains(inventory, '`flash/effects/$name.as`', 'inventory lists flash/effects/$name.as');
		}
		for (name in SOUND_CLASSES) {
			assertContains(inventory, '`flash/sounds/$name.as`', 'inventory lists flash/sounds/$name.as');
		}
		for (name in MENU_CLASSES) {
			assertContains(inventory, '`flash/menu/$name.as`', 'inventory lists flash/menu/$name.as');
		}
		for (name in GAMEPLAY_CLASSES) {
			assertContains(inventory, '`flash/gameplay/$name.as`', 'inventory lists flash/gameplay/$name.as');
		}
		for (name in LEVEL_BROWSER_CLASSES) {
			assertContains(inventory, '`flash/level_browser/$name.as`', 'inventory lists flash/level_browser/$name.as');
		}
		for (name in LEVEL_EDITOR_CLASSES) {
			assertContains(inventory, '`flash/levelEditor/$name.as`', 'inventory lists flash/levelEditor/$name.as');
		}
		for (name in LEVEL_MANAGEMENT_CLASSES) {
			assertContains(inventory, '`flash/level_management/$name.as`', 'inventory lists flash/level_management/$name.as');
		}
		for (name in LOBBY_CLASSES) {
			assertContains(inventory, '`flash/lobby/$name.as`', 'inventory lists flash/lobby/$name.as');
		}
		for (name in PAGE_CLASSES) {
			assertContains(inventory, '`flash/page/$name.as`', 'inventory lists flash/page/$name.as');
		}
		for (name in PLAYER_PROFILE_CLASSES) {
			assertContains(inventory, '`flash/player_profile/$name.as`', 'inventory lists flash/player_profile/$name.as');
		}
		for (name in UI_CLASSES) {
			assertContains(inventory, '`flash/ui/$name.as`', 'inventory lists flash/ui/$name.as');
		}
		for (name in COM_CLASSES) {
			assertContains(inventory, '`flash/com/$name.as`', 'inventory lists flash/com/$name.as');
		}
		assertContains(inventory, "pr2.harness.LocalPlayerController", "inventory maps item behavior to the controller");
		assertContains(inventory, "pr2.gameplay.Items", "inventory maps Items.as to the item catalog");
		assertContains(inventory, "pr2.level.ServerLevelDecoder", "inventory maps background data decoding");
		assertContains(inventory, "pr2.level.BlockType", "inventory maps block classes to block types");
		assertContains(inventory, "pr2.level.ServerLevelRenderer", "inventory maps visual block behavior to the renderer");
		assertContains(inventory, "pr2.character.Character", "inventory maps character base behavior");
		assertContains(inventory, "pr2.character.RemoteCharacter", "inventory maps remote character behavior");
		assertContains(inventory, "pr2.lobby.tabs.ChatTab", "inventory maps lobby chat tab behavior");
		assertContains(inventory, "pr2.lobby.tabs.MessagesTab", "inventory maps private message tab behavior");
		assertContains(inventory, "pr2.lobby.dialogs.Popup", "inventory maps shared dialog popup behavior");
		assertContains(inventory, "pr2.lobby.dialogs.PlayerPopup", "inventory maps member profile popup behavior");
		assertContains(inventory, "pr2.lobby.dialogs.OptionsPopup", "inventory maps options popup behavior");
		assertContains(inventory, "pr2.lobby.dialogs.UploadingPopup", "inventory maps shared upload popup behavior");
		assertContains(inventory, "pr2.lobby.tabs.PlayersTab", "inventory maps social players tab behavior");
		assertContains(inventory, "pr2.lobby.players.PlayersUserListLoader", "inventory maps social user-list loading");
		assertContains(inventory, "pr2.effects.BlockPiece", "inventory maps block-piece effects");
		assertContains(inventory, "pr2.effects.MineExplosion", "inventory maps mine explosion effects");
		assertContains(inventory, "pr2.audio.SoundEffects", "inventory maps spatial sound playback");
		assertContains(inventory, "pr2.audio.MenuMusic", "inventory maps Noodle Town menu music");
		assertContains(inventory, "pr2.net.LoginSessionGate", "inventory maps menu login handshake");
		assertContains(inventory, "pr2.net.ServerStatusClient", "inventory maps menu server selection");
		assertContains(inventory, "pr2.gameplay.GameCommandShell", "inventory maps live game command routing");
		assertContains(inventory, "pr2.page.GamePage", "inventory maps game page lifecycle");
		assertContains(inventory, "pr2.lobby.level.LevelListingPage", "inventory maps level browser listing pages");
		assertContains(inventory, "pr2.lobby.level.LevelItem", "inventory maps level browser items");
		assertContains(inventory, "pr2.lobby.level.CourseMenu", "inventory maps level browser course menu");
		assertContains(inventory, "level-editor implementation gap", "inventory records level editor implementation gaps");
		assertContains(inventory, "level-management implementation gap", "inventory records level management implementation gaps");
		assertContains(inventory, "pr2.page.LobbyPage", "inventory maps lobby shell lifecycle");
		assertContains(inventory, "pr2.lobby.LobbySide", "inventory maps lobby pane shell behavior");
		assertContains(inventory, "pr2.page.PageHolder", "inventory maps page holder lifecycle");
		assertContains(inventory, "pr2.gameplay.LevelConfig", "inventory maps page game metadata parsing");
		assertContains(inventory, "pr2.lobby.tabs.AccountTab", "inventory maps account profile customization");
		assertContains(inventory, "pr2.lobby.account.PartSelector", "inventory maps player-profile part selection");
		assertContains(inventory, "pr2.lobby.account.Presets", "inventory maps loadout presets");
		assertContains(inventory, "pr2.ui.TabsHolder", "inventory maps shared UI tab behavior");
		assertContains(inventory, "pr2.ui.PageNavigation", "inventory maps shared page navigation");
		assertContains(inventory, "pr2.lobby.account.StatsSelect", "inventory maps account stat controls");
		assertContains(inventory, "pr2.crypto.PR2Encryptor", "inventory maps PR2 encryption helpers");
		assertContains(inventory, "pr2.net.CommandHandler", "inventory maps socket command dispatch");
		assertContains(inventory, "pr2.net.LobbySocket", "inventory maps PR2 socket behavior");
		assertContains(inventory, "pr2.lobby.account.ColorPicker", "inventory maps color-picker controls");
		assertContains(inventory, "pr2.effects.PixelEffect1", "inventory maps pixel effects");
		assertContains(inventory, "ported", "inventory records status");
		trace('SourceClassCoverageInventoryTest passed $assertions assertions');
	}

	private static function assertContains(haystack:String, needle:String, message:String):Void {
		assertions++;
		if (haystack.indexOf(needle) == -1) {
			throw message + ' (missing "$needle")';
		}
	}
}
