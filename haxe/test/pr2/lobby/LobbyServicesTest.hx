package pr2.lobby;

import com.jiggmin.data.Data;
import haxe.crypto.Md5;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.text.TextField;
import openfl.geom.Point;
import openfl.ui.Keyboard;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.app.AppStage;
import pr2.app.KongAward;
import pr2.audio.AudioManager;
import pr2.lobby.LobbyLeft;
import pr2.lobby.LobbyRight;
import pr2.lobby.players.Guilds;
import pr2.lobby.players.PlayerListSort;
import pr2.lobby.players.PlayersTabList;
import pr2.lobby.players.PlayersUserListLoader;
import pr2.lobby.players.SocialAction;
import pr2.lobby.players.SocialAction.SocialActionPlan;
import pr2.lobby.players.PlayerListSort.SortableRow;
import pr2.lobby.search.SearchQuery;
import pr2.lobby.search.SearchQuery.SearchDecision;
import pr2.lobby.level.LevelAccess;
import pr2.lobby.level.LevelAccess.LevelAccessState;
import pr2.lobby.level.LevelGridLayout;
import pr2.lobby.level.CourseMenu;
import pr2.lobby.level.LevelLaunch;
import pr2.lobby.level.LevelListingState;
import pr2.lobby.messages.MessagesPaging;
import pr2.lobby.messages.UnreadNotif;
import pr2.gameplay.LevelConfig;
import pr2.level.ServerLevelRenderer;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelDataClient;
import pr2.net.LoginAuthClient;
import pr2.net.LoginAuthClient.LoginAuthResult;
import pr2.net.LoginSessionGate.LoginSessionResult;
import pr2.net.SavedAccounts;
import pr2.net.ServerConfig;
import pr2.net.ServerInfo;
import pr2.net.ServerStatusClient;
import pr2.net.ServerStatusResult;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.account.Presets;
import pr2.page.EditorBlockOptions;
import pr2.page.LoginPage;
import pr2.page.LobbyPage;
import pr2.levelEditor.LevelEditor;
import pr2.levelEditor.ChooseLevelsModePopup;
import pr2.levelEditor.DeletingLevelPopup;
import pr2.levelEditor.GetLevelsPopup;
import pr2.levelEditor.GetLevelsPopupItem;
import pr2.levelEditor.GetReportedLevelsPopupItem;
import pr2.levelEditor.HandleLevelReportPopup;
import pr2.levelEditor.GetReportedLevelsPopup;
import pr2.levelEditor.LoadingLevelPopup;
import pr2.levelEditor.LevelEditorConnectingPopup;
import pr2.levelEditor.SaveLevelPopup;
import pr2.levelEditor.EditorSideBarEntry;
import pr2.levelEditor.EditorBrushSizePickerButton;
import pr2.levelEditor.UploadingLevelPopup;
import pr2.levelEditor.TestCoursePage;
import pr2.page.Page;
import pr2.page.PageHolder;
import pr2.lobby.account.Settings;
import pr2.lobby.account.StatSlider;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlButton;
import pr2.runtime.FlComboBox;
import pr2.ui.CustomScrollBar;
import pr2.ui.PageNavigation;
import pr2.ui.StageFocus;
import pr2.ui.TabLayout;
import pr2.ui.TabsHolder;
import pr2.util.DisplayUtil;

/**
	Deterministic coverage for the shared lobby services and tab logic that don't
	need real display art: tab overlap math, remembered tab restoration, the
	socket command recorder, the command dispatcher, and session guest/member
	state.
**/
class LobbyServicesTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTabLayoutNoCompression();
		testTabLayoutCompression();
		testTabLayoutSingleTab();
		testTabMemory();
		testScrollBarMapping();
		testPageNavigationPositions();
		testPlayerSortStateMachine();
		testPlayerSortOrdering();
		testPlayersTabListSortsOnInterval();
		testPlayerAndGuildListsIgnoreLateLoadsAfterRemove();
		testPaneTabLabels();
		testLevelListParsing();
		testLevelItemFavoriteFlow();
		testLevelItemPasswordFlow();
		testSearchFocusQuirks();
		testSearchRequestQuirks();
		testSearchPendingShowsLoadingGraphic();
		testSearchResultsStartBelowControls();
		testSearchQuery();
		testLevelAccess();
		testLevelPassResponse();
		testLevelGridLayout();
		testLevelInfoParsing();
		testSessionGuestMember();
		testSocketRecording();
		testCommandDispatch();
		testMemoryAndSecureData();
		testPmNotificationLifecycle();
		testLobbySidePanelDimensions();
		testLoginServerActivationLifecycle();
		testCheckServersComboPrompts();
		testCheckServersGuildSelectionRules();
		testLoggingInPayloadAndResetTokenFlow();
		testLoginPageAppliesPostLoginState();
		testLevelEditorRoute();
		testLobbyBottomButtonEffects();
		testLevelEditorShell();
		testLevelEditorLoadListPopup();
		testLevelEditorLoadingLevelPopup();
		testLevelEditorReportedLevelsPopup();
		testLevelEditorReportHandlePopup();
		testLevelEditorDeleteFlow();
		testLevelEditorSaveDialog();
		testUploadingLevelPopupFields();
		testUploadingLevelPopupDecodesUrlResponse();
		testUploadingLevelPopupDrawingRetryWait();
		testUploadingLevelPopupOverwriteConfirmation();
		testUploadingLevelPopupBannedConfirmation();
		testUploadingLevelPopupResultMessages();
		testUploadingLevelPopupEmptyDataMessage();
		testLevelEditorTestCourseTransition();
		testLevelEditorEggTestCourseSpawnsEggs();
		testMessagesPaging();
		testSocialActionPlan();
		testCourseMenuTiming();
		testLevelLaunch();
		testLevelLaunchTargetsRootHolder();
		trace('LobbyServicesTest passed $assertions assertions');
	}

	private static function testMessagesPaging():Void {
		// Flash chat.Messages: start = (currentPage - 1) * itemsPerPage, count = itemsPerPage.
		assertEquals(0, MessagesPaging.startIndex(1), "page 1 starts at 0");
		assertEquals(10, MessagesPaging.startIndex(2), "page 2 starts at 10");
		assertEquals(40, MessagesPaging.startIndex(5), "page 5 starts at 40");
		assertEquals(0, MessagesPaging.startIndex(0), "page 0 clamps to first page");
		assertEquals(20, MessagesPaging.startIndex(3, 10), "explicit items-per-page");
		ServerConfig.resetHost();
		assertEquals("https://pr2hub.com/messages_get.php?start=10&count=10", ServerConfig.messagesGetUrl(10, 10), "messages_get url");

		// Unread PM badge: only timestamps newer than last-read count; opening clears.
		UnreadNotif.reset();
		UnreadNotif.setLastRead(100);
		UnreadNotif.notifyUser(50);
		assertEquals(0, UnreadNotif.numUnread(), "older-than-last-read does not count");
		UnreadNotif.notifyUser(200);
		assertEquals(1, UnreadNotif.numUnread(), "newer message counts as unread");
		UnreadNotif.updateLastRead();
		assertEquals(0, UnreadNotif.numUnread(), "opening PMs clears unread");
		UnreadNotif.notifyUser(150);
		assertEquals(0, UnreadNotif.numUnread(), "message older than new last-read ignored");
		UnreadNotif.reset();
	}

	private static function testSocialActionPlan():Void {
		// Each player-popup action maps to a user_list_modify list/mode and a socket verb.
		var follow = SocialActionPlan.plan(SocialAction.Follow);
		assertEquals("following", follow.list, "follow list");
		assertEquals("add", follow.mode, "follow mode");
		assertEquals("follow_user", follow.socketVerb, "follow verb");

		var unfollow = SocialActionPlan.plan(SocialAction.Unfollow);
		assertEquals("following", unfollow.list, "unfollow list");
		assertEquals("remove", unfollow.mode, "unfollow mode");
		assertEquals("unfollow_user", unfollow.socketVerb, "unfollow verb");

		var addFriend = SocialActionPlan.plan(SocialAction.AddFriend);
		assertEquals("friends", addFriend.list, "add-friend list");
		assertEquals("add", addFriend.mode, "add-friend mode");
		assertEquals("add_friend", addFriend.socketVerb, "add-friend verb");

		var removeFriend = SocialActionPlan.plan(SocialAction.RemoveFriend);
		assertEquals("friends", removeFriend.list, "remove-friend list");
		assertEquals("remove", removeFriend.mode, "remove-friend mode");
		assertEquals("remove_friend", removeFriend.socketVerb, "remove-friend verb");

		var ignore = SocialActionPlan.plan(SocialAction.Ignore);
		assertEquals("ignored", ignore.list, "ignore list");
		assertEquals("add", ignore.mode, "ignore mode");
		assertEquals("ignore_user", ignore.socketVerb, "ignore verb");

		var unignore = SocialActionPlan.plan(SocialAction.Unignore);
		assertEquals("ignored", unignore.list, "unignore list");
		assertEquals("remove", unignore.mode, "unignore mode");
		assertEquals("unignore_user", unignore.socketVerb, "unignore verb");
	}

	private static function testLevelEditorRoute():Void {
		var previousFactory = LobbyPage.createLevelEditorPage;
		var previousLogoutPostFactory = LobbyPage.logoutPostFactory;
		var launchedAsMod:Null<Bool> = null;
		var logoutPosts:Array<{url:String, fields:Map<String, String>}> = [];
		LobbyPage.createLevelEditorPage = function(isMod:Bool):Page {
			launchedAsMod = isMod;
			return new TestPage("level-editor");
		};
		LobbyPage.logoutPostFactory = function(url:String, fields:Map<String, String>):Void {
			logoutPosts.push({url: url, fields: fields});
		};

		LobbySession.clear();
		LobbySession.group = 3;
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = false;
		var holder = new PageHolder();
		var page = new LobbyPage();
		page.pageHolder = holder;
		Reflect.callMethod(page, Reflect.field(page, "clickLevelEditor"), []);
		assertEquals(true, launchedAsMod, "permanent moderators enter editor with mod privileges");
		assertEquals(true, Std.isOfType(holder.getCurrentPage(), TestPage), "level editor route changes page");

		launchedAsMod = null;
		LobbySession.group = 3;
		LobbySession.isTempMod = true;
		LobbySession.server = serverInfo(0);
		LobbySession.userName = "Temp";
		LobbySession.remember = false;
		LobbySocket.resetSent();
		page = new LobbyPage();
		page.pageHolder = holder;
		Reflect.callMethod(page, Reflect.field(page, "clickLevelEditor"), []);
		assertEquals(null, launchedAsMod, "non-guild temporary moderators confirm before editor entry");
		var confirm = lastConfirmPopup();
		assertNotNull(confirm, "temporary moderator editor entry opens confirmation");
		assertEquals(true, LobbyArt.text(confirm, "textBox").htmlText.indexOf("Entering the level editor will log you out") >= 0,
			"temporary moderator editor confirmation copy");
		clickPopup(confirm, "ok_bt");
		assertEquals(false, launchedAsMod, "confirmed temporary moderators enter editor without mod privileges");
		assertEquals(true, Std.isOfType(holder.getCurrentPage(), TestPage), "confirmed temporary moderator editor route changes page");
		assertEquals(1, LobbySocket.closeCount, "confirmed temporary moderator editor entry closes socket");
		assertEquals(0, LobbySession.group, "confirmed temporary moderator editor entry logs out session");
		assertEquals(1, logoutPosts.length, "confirmed non-remembered temporary moderator editor entry posts logout");
		assertEquals(ServerConfig.logoutUrl(), logoutPosts[0].url, "temporary moderator editor logout endpoint");
		assertEquals(0, mapSize(logoutPosts[0].fields), "temporary moderator editor logout posts empty fields");
		assertNotNull(lastMessagePopup(), "confirmed temporary moderator editor entry shows logged-out message");
		closeAllPopups();

		launchedAsMod = null;
		LobbySession.group = 3;
		LobbySession.isTempMod = true;
		LobbySession.server = serverInfo(77);
		LobbySocket.resetSent();
		page = new LobbyPage();
		page.pageHolder = holder;
		Reflect.callMethod(page, Reflect.field(page, "clickLevelEditor"), []);
		assertEquals(false, launchedAsMod, "guild temporary moderators enter editor without demotion confirmation");
		assertEquals(1, LobbySocket.closeCount, "guild temporary moderator editor entry still closes socket");

		LobbySession.group = 2;
		LobbySession.isTempMod = true;
		LobbySession.server = serverInfo(0);
		LobbySession.userName = "Temp";
		LobbySession.remember = false;
		LobbySocket.resetSent();
		page = new LobbyPage();
		page.pageHolder = holder;
		Reflect.callMethod(page, Reflect.field(page, "clickLogout"), []);
		confirm = lastConfirmPopup();
		assertNotNull(confirm, "temporary moderator logout opens confirmation");
		assertEquals(true, LobbyArt.text(confirm, "textBox").htmlText.indexOf("Logging out will automatically demote") >= 0,
			"temporary moderator logout confirmation copy");
		clickPopup(confirm, "ok_bt");
		assertEquals(1, LobbySocket.closeCount, "confirmed temporary moderator logout closes socket");
		assertEquals(0, LobbySession.group, "confirmed temporary moderator logout clears session");
		assertEquals(2, logoutPosts.length, "confirmed non-remembered temporary moderator logout posts logout");
		assertNotNull(lastMessagePopup(), "confirmed temporary moderator logout shows logged-out message");

		LobbySession.group = 1;
		LobbySession.isTempMod = false;
		LobbySession.server = serverInfo(0);
		LobbySession.remember = false;
		LobbySocket.resetSent();
		page = new LobbyPage();
		page.pageHolder = holder;
		Reflect.callMethod(page, Reflect.field(page, "clickLogout"), []);
		assertEquals(3, logoutPosts.length, "non-remembered regular logout posts logout");
		assertEquals(ServerConfig.logoutUrl(), logoutPosts[2].url, "regular logout endpoint");
		assertEquals(0, mapSize(logoutPosts[2].fields), "regular logout posts empty fields");

		LobbySession.group = 1;
		LobbySession.isTempMod = false;
		LobbySession.server = serverInfo(0);
		LobbySession.remember = true;
		LobbySocket.resetSent();
		page = new LobbyPage();
		page.pageHolder = holder;
		Reflect.callMethod(page, Reflect.field(page, "clickLogout"), []);
		assertEquals(3, logoutPosts.length, "remembered regular logout skips logout post");

		LobbyPage.createLevelEditorPage = previousFactory;
		LobbyPage.logoutPostFactory = previousLogoutPostFactory;
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testLobbyBottomButtonEffects():Void {
		var starts = 0;
		var targets:Array<Float> = [];
		AudioManager.startPlayingHook = function():Void starts++;
		AudioManager.targetVolumeHook = function(value:Float):Void targets.push(value);
		LobbySession.clear();
		LobbySession.group = 1;
		Settings.setValue(Settings.MUSIC_VOLUME, 50);

		var page = new LobbyPage();
		page.initialize();
		assertEquals(1, starts, "lobby entry starts Noodle Town when music is enabled");
		assertEquals(0.3, targets[0], "lobby entry applies Flash Noodle Town volume scale");
		var moreGames = DisplayUtil.findByName(page, "moreGamesButton");
		moreGames.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(true, page.hasKongHoverForTests(), "Kongregate button hover opens Kong Hat popup");
		moreGames.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(false, page.hasKongHoverForTests(), "Kongregate button mouse-out closes Kong Hat popup");
		moreGames.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		page.remove();
		assertEquals(false, page.hasKongHoverForTests(), "lobby removal clears Kong Hat popup");
		assertEquals(0.0, targets[targets.length - 1], "lobby removal mutes Noodle Town");

		AudioManager.resetHooksForTests();
		Settings.setValue(Settings.MUSIC_VOLUME, 100);
		closeAllPopups();
	}

	private static function testLevelEditorShell():Void {
		LobbySession.clear();
		LobbySession.group = 0;
		var editor = new LevelEditor(null, false, true);
		editor.initialize();
		assertEquals(editor, LevelEditor.editor, "editor shell sets singleton");
		assertEquals(false, editor.isMod, "editor shell stores mod flag");
		assertEquals(true, editor.reportsMode, "editor shell applies reports mode");
		assertEquals(false, editor.overlayLayer.mouseEnabled, "overlay ignores mouse");
		assertEquals(false, editor.overlayLayer.mouseChildren, "overlay children ignore mouse");
		assertEquals(true, editor.getChildIndex(editor.overlayLayer) > editor.getChildIndex(editor.menu), "overlay is above menu");
		assertNotNull(DisplayUtil.findByName(editor.menu.art, "blocksButton"), "authored editor menu is mounted");
		assertEquals(3, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "zoomSelect"), "selectedIndex"), "editor zoom defaults to 100%");
		var zoomSelect = Std.downcast(DisplayUtil.findByName(editor.menu.art, "zoomSelect"), FlComboBox);
		zoomSelect.selectedIndex = 1;
		zoomSelect.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(0.5, editor.zoom, "editor zoom follows authored combo box data");
		assertEquals(0.5, editor.menu.tools.zoom, "editor zoom syncs to tools sidebar");
		assertEquals(0.5, @:privateAccess editor.layerContainer.scaleX, "editor world scales horizontally with zoom");
		assertEquals(0.5, @:privateAccess editor.layerContainer.scaleY, "editor world scales vertically with zoom");
		var zoomedPoint = editor.blockLayer.globalToLocal(new Point(100, 120));
		assertEquals(Std.int(100 / editor.zoom - editor.blockLayer.x), Std.int(zoomedPoint.x),
			"zoom changes editor stage-to-world x conversion");
		assertEquals(Std.int(120 / editor.zoom - editor.blockLayer.y), Std.int(zoomedPoint.y),
			"zoom changes editor stage-to-world y conversion");
		zoomSelect.selectedIndex = 3;
		zoomSelect.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(1, editor.zoom, "editor zoom returns to 100% before placement tests");
		var centeredPosX = editor.posX;
		var centeredPosY = editor.posY;
		@:privateAccess editor.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.RIGHT));
		@:privateAccess editor.keyScroll(new Event(Event.ENTER_FRAME));
		@:privateAccess editor.onKeyUp(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, Keyboard.RIGHT));
		assertEquals(true, editor.posX < centeredPosX, "editor keyboard scroll moves camera horizontally");
		assertEquals(centeredPosY, editor.posY, "horizontal keyboard scroll keeps camera y");
		assertEquals(Math.round(editor.posX), editor.blockLayer.x, "block layer follows camera x");
		assertEquals(Math.round(editor.posY), editor.blockLayer.y, "block layer follows camera y");
		editor.setPos(-300, -220);
		@:privateAccess editor.velX = 0;
		@:privateAccess editor.velY = 0;
		@:privateAccess editor.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.LEFT));
		@:privateAccess editor.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.SHIFT));
		@:privateAccess editor.keyScroll(new Event(Event.ENTER_FRAME));
		@:privateAccess editor.onKeyUp(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, Keyboard.LEFT));
		@:privateAccess editor.onKeyUp(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, Keyboard.SHIFT));
		assertEquals(-288.0, editor.posX, "shift-left scroll doubles acceleration before friction");
		editor.setZoom(0.5);
		@:privateAccess editor.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.LEFT));
		@:privateAccess editor.keyScroll(new Event(Event.ENTER_FRAME));
		@:privateAccess editor.onKeyUp(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, Keyboard.LEFT));
		assertEquals(-550.0, editor.posX, "zoomed keyboard scroll clamps with Flash inverse-scale bounds");
		editor.setPos(-999999, -999999);
		assertEquals(-59450.0, editor.posX, "editor x scroll clamps at level width");
		assertEquals(-59600.0, editor.posY, "editor y scroll clamps at level height");
		@:privateAccess editor.posX = 0;
		@:privateAccess editor.posY = 0;
		@:privateAccess editor.velX = 0;
		@:privateAccess editor.velY = 0;
		@:privateAccess editor.cameraStarted = false;
		editor.setZoom(1);
		@:privateAccess editor.applyLayerPositions();
		assertEquals(false, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "saveButton"), "enabled"), "guests cannot save");
		assertEquals(false, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "loadButton"), "enabled"), "guests cannot load");
		var undoButton = Std.downcast(DisplayUtil.findByName(editor.menu.art, "undoButton"), FlButton);
		var redoButton = Std.downcast(DisplayUtil.findByName(editor.menu.art, "redoButton"), FlButton);
		assertEquals("Undo", undoButton.label, "undo button keeps its authored label");
		assertEquals("Redo", redoButton.label, "redo button keeps its authored label");
		assertEquals(0x555555, @:privateAccess undoButton.textField.getTextFormat().color, "disabled undo label remains readable");
		assertEquals(0x555555, @:privateAccess redoButton.textField.getTextFormat().color, "disabled redo label remains readable");
		var popupCount = Popup.getOpen().length;
		clickEditorMenu(editor, "saveButton");
		clickEditorMenu(editor, "loadButton");
		assertEquals(popupCount, Popup.getOpen().length, "guest save/load buttons do not open popups");
		assertEquals("blocks", editor.menu.sideBar.id, "editor menu starts on blocks sidebar");
		assertEquals("blocks", editor.focusedEditorLayer, "editor starts focused on block layer history");
		assertEquals(editor.menu, editor.menu.sideBar.parent, "active sidebar is mounted above menu art");
		assertEquals(275, Std.int(editor.menu.x), "editor menu x matches Flash stage center");
		assertEquals(200, Std.int(editor.menu.y), "editor menu y matches Flash stage center");
		assertEquals(222, Std.int(editor.menu.sideBar.x), "editor sidebar x matches Flash");
		assertEquals(-195, Std.int(editor.menu.sideBar.y), "editor sidebar y matches Flash");
		assertEquals(4, Std.int(editor.menu.sideBar.scrollHolderForTests().y), "editor sidebar scroll holder y");
		assertEquals(35, Std.int(editor.menu.sideBar.scrollBarForTests().x), "editor sidebar scroll bar x");
		assertEquals(2, Std.int(editor.menu.sideBar.scrollBarForTests().y), "editor sidebar scroll bar y");
		assertEquals(false, editor.menu.sideBar.scrollBarForTests().timelinesPlayingForTests(), "editor scrollbar button timelines stay static");
		assertEquals(true, editor.menu.sideBar.scrollBarForTests().hasStableButtonHitAreasForTests(), "editor scrollbar buttons use stable hit areas across authored states");
		assertEquals(true, editor.menu.sideBar.scrollBarForTests().thumbHitBoundsForTests().width >= 15, "editor scrollbar thumb keeps a full-width grab target");
		assertEquals(false, editor.menu.sideBar.scrollBarForTests().trackMouseEnabledForTests(),
			"editor scrollbar track cannot steal hover or drag input from the thumb");
		editor.selectEditorTool("blocks", "brick");
		var blocksBeforeScrollbarClick = editor.blockLayer.blocks.length;
		editor.menu.sideBar.scrollBarForTests().dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, 0, 0));
		assertEquals(blocksBeforeScrollbarClick, editor.blockLayer.blocks.length, "scrollbar targets never leak clicks into block placement");
		editor.selectEditorTool("", "");
		assertEquals(30, Std.int(editor.menu.sideBar.maskWidthForTests()), "editor sidebar mask width");
		assertEquals(348, Std.int(editor.menu.sideBar.maskHeightForTests()), "editor sidebar mask height");
		assertEquals(true, editor.menu.sideBar.scrollHolderForTests().mask == editor.menu.sideBar.scrollMaskForTests(), "editor sidebar masks scroll holder");
		var deleteEntry = editor.menu.sideBar.getChildByName("deleteEntry");
		var basic1Entry = editor.menu.sideBar.getChildByName("basic1Entry");
		var brickEntry = editor.menu.sideBar.getChildByName("brickEntry");
		assertEquals(editor.menu.sideBar.scrollHolderForTests(), brickEntry.parent, "editor sidebar entries live in scroll holder");
		assertEquals(0, Std.int(deleteEntry.y), "first sidebar entry starts at y0 inside holder");
		assertEquals(40, Std.int(basic1Entry.y), "sidebar entries use 30px column plus 10px gap");
		var brickHover = Std.downcast(brickEntry, pr2.lobby.dialogs.HoverDelayPopup);
		assertEquals("Brick Block", brickHover.title, "block sidebar entry has authored hover title");
		assertEquals("A block of poorly mortared bricks that will shatter if it is bumped from below.", brickHover.content,
			"block sidebar entry has authored hover description");
		var deleteSideBarEntry = Std.downcast(deleteEntry, EditorSideBarEntry);
		var brickSideBarEntry = Std.downcast(brickEntry, EditorSideBarEntry);
		assertEquals(true, brickSideBarEntry.hasAuthoredChromeForTests(), "block sidebar entries use authored SquareBG chrome");
		assertEquals("ObjectDeleterButtonGraphic", deleteSideBarEntry.iconNameForTests(), "delete entry uses authored deleter graphic");
		assertEquals("BrickBlock", brickSideBarEntry.iconNameForTests(), "block entry uses authored block preview");
		brickEntry.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER, true));
		assertEquals(0.5, brickSideBarEntry.iconColorTransformForTests().redMultiplier, "sidebar hover dims icon red channel");
		assertEquals(128.0, brickSideBarEntry.iconColorTransformForTests().redOffset, "sidebar hover applies Flash red offset");
		brickEntry.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT, true));
		assertEquals(1.0, brickSideBarEntry.iconColorTransformForTests().redMultiplier, "sidebar hover out restores icon red channel");
		assertEquals(0.0, brickSideBarEntry.iconColorTransformForTests().redOffset, "sidebar hover out clears color offset");
		clickEditorSidebar(editor, "brickEntry");
		assertEquals("blocks", editor.selectedToolSidebar, "sidebar click records selected tool sidebar");
		assertEquals("brick", editor.selectedToolId, "sidebar click records selected tool id");
		clickEditorMenu(editor, "settingsButton");
		assertEquals("settings", editor.menu.sideBar.id, "settings button switches sidebar");
		assertEquals("", editor.focusedEditorLayer, "settings button clears focused editor layer");
		assertEquals(false, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "undoButton"), "enabled"),
			"settings button disables undo");
		var itemsEntry = Std.downcast(editor.menu.sideBar.getChildByName("itemsEntry"), EditorSideBarEntry);
		var rankEntry = Std.downcast(editor.menu.sideBar.getChildByName("rankEntry"), EditorSideBarEntry);
		assertEquals("Items", itemsEntry.title, "settings sidebar entry has authored hover title");
		assertEquals("These items will be available to players in your course's item boxes.", itemsEntry.content,
			"settings sidebar entry has authored hover description");
		assertEquals("ItemButtonGraphic", itemsEntry.iconNameForTests(), "settings item entry uses authored menu graphic");
		assertEquals("ValueButtonGraphic", rankEntry.iconNameForTests(), "settings value entry uses authored value graphic");
		itemsEntry.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true));
		assertNotNull(editor.activeItemSettingsPopup, "settings menu button click opens its authored popup");
		editor.closeItemSettingsPopup();
		assertEquals(null, editor.menu.blocks.parent, "old sidebar is removed when switching");
		assertEquals("", editor.selectedToolId, "switching sidebars clears stale selected tool");
		clickEditorMenu(editor, "bgButton");
		assertEquals("backgrounds", editor.menu.sideBar.id, "background button switches sidebar");
		assertEquals("", editor.focusedEditorLayer, "background button clears focused editor layer");
		assertEquals(false, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "redoButton"), "enabled"),
			"background button disables redo");
		var bg1Entry = Std.downcast(editor.menu.sideBar.getChildByName("bg1Entry"), EditorSideBarEntry);
		assertEquals("BG1", bg1Entry.iconNameForTests(), "background entry uses authored background art");
		assertEquals(true, bg1Entry.iconVisibleInButtonForTests(), "background entry art is fitted inside its button");
		clickEditorMenu(editor, "layer1Button");
		assertEquals("stamps", editor.menu.sideBar.id, "layer buttons switch to stamps sidebar");
		assertEquals(1, editor.activeObjectLayer.layerNum, "layer 1 selects the matching object layer");
		assertEquals("objects", editor.focusedEditorLayer, "object layer button focuses current object layer");
		var stampBrushEntry = Std.downcast(editor.menu.sideBar.getChildByName("brushEntry"), EditorSideBarEntry);
		var stamp0Entry = Std.downcast(editor.menu.sideBar.getChildByName("stamp0Entry"), EditorSideBarEntry);
		var stamp1Entry = Std.downcast(editor.menu.sideBar.getChildByName("stamp1Entry"), EditorSideBarEntry);
		var stamp5Entry = Std.downcast(editor.menu.sideBar.getChildByName("stamp5Entry"), EditorSideBarEntry);
		var stamp4Entry = Std.downcast(editor.menu.sideBar.getChildByName("stamp4Entry"), EditorSideBarEntry);
		var stamp9Entry = Std.downcast(editor.menu.sideBar.getChildByName("stamp9Entry"), EditorSideBarEntry);
		assertEquals("BrushGraphic", stampBrushEntry.iconNameForTests(), "stamp brush entry uses authored brush graphic");
		if (Assets.exists(ServerLevelRenderer.stampAssetPath(0), AssetType.IMAGE)) {
			assertEquals("Tree", stamp0Entry.iconNameForTests(), "stamp entry uses bitmap object preview");
			assertEquals(true, stamp0Entry.iconVisibleInButtonForTests(), "tree stamp entry renders inside the button");
			assertEquals(true, stamp1Entry.iconVisibleInButtonForTests(), "second tree stamp entry renders inside the button");
			assertEquals(true, stamp5Entry.iconVisibleInButtonForTests(), "rock stamp entry renders inside the button");
		}
		assertEquals(true, stamp4Entry.iconVisibleInButtonForTests(), "Fred stamp linkage renders inside the button");
		assertEquals(true, stamp9Entry.iconVisibleInButtonForTests(), "building stamp linkage renders inside the button");
		clickEditorSidebar(editor, "brushEntry");
		assertEquals("tools", editor.menu.sideBar.id, "stamp brush entry switches to draw tools");
		assertEquals("draw", editor.focusedEditorLayer, "stamp brush entry focuses current draw layer");
		assertEquals("tools", editor.selectedToolSidebar, "draw mode selects the tools sidebar by default");
		assertEquals("brush", editor.selectedToolId, "draw mode selects the brush by default");
		var toolBrushEntry = Std.downcast(editor.menu.sideBar.getChildByName("brushEntry"), EditorSideBarEntry);
		var eraserEntry = Std.downcast(editor.menu.sideBar.getChildByName("eraserEntry"), EditorSideBarEntry);
		assertEquals("Brush", toolBrushEntry.title, "tools sidebar entry has authored hover title");
		assertEquals("Draw things, yay!", toolBrushEntry.content, "tools sidebar entry has authored hover description");
		assertEquals("BrushButtonGraphic", toolBrushEntry.iconNameForTests(), "tools brush entry uses authored button graphic");
		assertEquals("EraserButtonGraphic", eraserEntry.iconNameForTests(), "tools eraser entry uses authored button graphic");
		assertEquals(toolBrushEntry, editor.menu.tools.selectedEntry, "draw mode highlights the brush button by default");
		clickEditorSidebar(editor, "brushEntry");
		assertEquals("tools", editor.selectedToolSidebar, "tools brush entry records selected tool sidebar");
		assertEquals("brush", editor.selectedToolId, "tools brush entry records selected tool id");
		assertEquals(true, editor.beginSelectedBrushAt(10, 12), "brush starts on the active draw layer");
		assertEquals(true, editor.continueSelectedBrushAt(15, 18), "brush extends while drawing");
		assertEquals(true, editor.endSelectedBrush(), "brush stroke finishes");
		assertEquals("d10;12;5;6", editor.activeDrawLayer.getSaveString(), "brush stores Flash draw action deltas");
		assertEquals(1, editor.activeDrawLayer.drawActions.length, "brush records one draw action");
		assertEquals(1, editor.activeDrawLayer.rasterCanvas.numChildren, "brush rasterizes visible art");
		clickEditorSidebar(editor, "sizeEntry");
		assertEquals("brush", editor.selectedToolId, "brush size picker keeps the active drawing tool");
		assertNotNull(editor.activeBrushSizeMenu, "brush size entry opens the authored picker menu");
		Reflect.callMethod(editor.activeBrushSizeMenu, Reflect.field(editor.activeBrushSizeMenu, "setSize"), [12]);
		assertEquals(12, editor.brushSize, "brush size menu commits the selected brush size");
		var sizeMenu = editor.activeBrushSizeMenu;
		var sizeSlider = @:privateAccess sizeMenu.slider;
		var sliderBounds = sizeSlider.getBounds(sizeMenu);
		assertNear(0, Std.int(sliderBounds.x + sliderBounds.width / 2), 4, "brush size slider stays centered in its popup");
		var popupBounds = sizeMenu.getBounds(editor);
		var popupX = popupBounds.x + popupBounds.width / 2;
		var popupY = popupBounds.y + popupBounds.height / 2;
		assertEquals(true, editor.isPointOverMenu(popupX, popupY), "brush popup counts as editor chrome for drawing input");
		assertEquals(false, editor.canStartBrushFromTargetForTests(editor, popupX, popupY), "brush cannot start through its size popup");
		var sizeEntry = Std.downcast(editor.menu.sideBar.getChildByName("sizeEntry"), EditorBrushSizePickerButton);
		editor.setBrushSize(255);
		sizeEntry.updateCircle();
		assertEquals(true, sizeEntry.previewSizeForTests() < 29, "maximum Flash brush size stays inside its button preview");
		editor.setBrushSize(12);
		sizeEntry.updateCircle();
		@:privateAccess sizeMenu.autoDismiss.armForTests();
		@:privateAccess sizeMenu.autoDismiss.stageMouseDownForTests(-1000, -1000);
		assertEquals(null, editor.activeBrushSizeMenu, "brush size popup closes on an outside click");
		var brushColorEntry = editor.menu.sideBar.getChildByName("colorEntry");
		Reflect.callMethod(brushColorEntry, Reflect.field(brushColorEntry, "setPickedColor"), [0x336699]);
		assertEquals(0x336699, editor.brushColor, "brush color picker commits the selected brush color");
		assertEquals(true, editor.beginSelectedBrushAt(30, 40), "brush still starts after size/color changes");
		assertEquals(true, editor.continueSelectedBrushAt(35, 47), "customized brush extends while drawing");
		assertEquals(true, editor.endSelectedBrush(), "customized brush stroke finishes");
		assertEquals("d10;12;5;6,c336699,t12,d30;40;5;7", editor.activeDrawLayer.getSaveString(),
			"brush size and color controls record Flash draw actions before the stroke");
		clickEditorSidebar(editor, "landscapeEntry");
		assertEquals("stamps", editor.menu.sideBar.id, "landscape entry switches back to stamps sidebar");
		assertEquals("objects", editor.focusedEditorLayer, "landscape entry focuses current object layer");
		clickEditorMenu(editor, "bgButton");
		clickEditorMenu(editor, "layer1Button");
		clickEditorSidebar(editor, "textEntry");
		assertEquals("stamps", editor.selectedToolSidebar, "stamp sidebar entry records selected tool sidebar");
		assertEquals("text", editor.selectedToolId, "stamp sidebar entry records selected tool id");
		assertEquals(null, editor.placeSelectedToolAt(100, 120), "text tool does not stamp objects");
		var label = editor.placeSelectedTextAt(100, 120);
		assertNotNull(label, "text tool places an editable text object");
		label.setEditingText("hello, world; #1");
		label.finishEditing();
		assertEquals(95, Std.int(label.x), "text placement applies Flash cursor x offset");
		assertEquals(104, Std.int(label.y), "text placement applies Flash cursor y offset");
		assertEquals("hello, world; #1", label.text, "text editing commits the typed content");
		editor.activeObjectLayer.selectTextObjectForTests(-1);
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0", editor.activeObjectLayer.getActionString(), "text placement records Flash add/change actions");
		label.beginDragAt(100, 120);
		label.endDragAt(100, 120);
		assertEquals(true, label.isEditing(), "clicking existing text reopens editing");
		label.setEditingText("edited text");
		label.setColor(0x336699);
		label.finishEditing();
		assertEquals("edited text", label.text, "re-editing commits the updated text");
		assertEquals(0x336699, label.color, "text color edit commits the selected color");
		editor.activeObjectLayer.selectTextObjectForTests(-1);
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601", editor.activeObjectLayer.getActionString(),
			"text re-edit records a Flash change action with color");
		assertEquals(true, label.hasAuthoredDeleteButtonForTests(), "text draw object uses authored delete button");
		assertEquals(true, label.hasAuthoredResizeButtonForTests(), "text draw object uses authored resize button");
		var outlineBounds = label.selectionOutlineBoundsForTests();
		var displayBounds = label.displayBoundsForTests();
		assertNear(Std.int(displayBounds.x), Std.int(outlineBounds.x), 2, "text selection outline starts at real display x");
		assertNear(Std.int(displayBounds.y), Std.int(outlineBounds.y), 2, "text selection outline starts at real display y");
		assertNear(Std.int(displayBounds.width), Std.int(outlineBounds.width), 8, "text selection outline follows real display width");
		assertNear(Std.int(displayBounds.height), Std.int(outlineBounds.height), 8, "text selection outline follows real display height");
		label.beginDragAt(100, 120);
		assertEquals(0.75, label.alpha, "text drag fades the moved object like Flash");
		label.dragTo(117.4, 146.6);
		label.endDragAt(117.4, 146.6);
		assertEquals(1, label.alpha, "text drag restores alpha on release");
		var resizeHandle = label.getChildByName("ResizeButton");
		assertNotNull(resizeHandle, "text object exposes a resize handle");
		label.beginResizeAt(label.x + resizeHandle.x, label.y + resizeHandle.y);
		label.resizeDragTo(label.x + resizeHandle.x * 1.236, label.y + resizeHandle.y * 0.754);
		label.endResizeAt(label.x + resizeHandle.x * 1.236, label.y + resizeHandle.y * 0.754);
		assertEquals(112, Std.int(label.x), "text move rounds x like Flash drag release");
		assertEquals(131, Std.int(label.y), "text move rounds y like Flash drag release");
		assertEquals(1.24, label.scaleX, "text resize rounds scale x to hundredths");
		assertEquals(0.75, label.scaleY, "text resize rounds scale y to hundredths");
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601,m0;112;131,r0;1.24;0.75",
			editor.activeObjectLayer.getActionString(), "text move and resize record Flash object actions");
		label.beginDragAt(112, 131);
		label.endDragAt(112, 131);
		label.setEditingText("   ");
		label.finishEditing();
		assertEquals(0, editor.activeObjectLayer.textObjects.length, "empty text edit removes the text object");
		assertEquals(null, label.parent, "empty text edit unmounts the display object");
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601,m0;112;131,r0;1.24;0.75,d0", editor.activeObjectLayer.getActionString(),
			"empty text edit records a Flash delete action");
		clickEditorMenu(editor, "undoButton");
		assertEquals(1, editor.activeObjectLayer.textObjects.length, "undo restores the deleted text object");
		label = editor.activeObjectLayer.textObjects[0];
		assertEquals("edited text", label.text, "undo rebuilds the previous text content");
		assertEquals(112, Std.int(label.x), "undo rebuilds the previous text x");
		assertEquals(131, Std.int(label.y), "undo rebuilds the previous text y");
		assertEquals(1.24, label.scaleX, "undo rebuilds the previous text scale x");
		assertEquals(0.75, label.scaleY, "undo rebuilds the previous text scale y");
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601,m0;112;131,r0;1.24;0.75",
			editor.activeObjectLayer.getActionString(), "undo removes the last Flash text action");
		clickEditorMenu(editor, "redoButton");
		assertEquals(0, editor.activeObjectLayer.textObjects.length, "redo reapplies the deleted text action");
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601,m0;112;131,r0;1.24;0.75,d0",
			editor.activeObjectLayer.getActionString(), "redo restores the last Flash text action");
		clickEditorMenu(editor, "undoButton");
		assertEquals(1, editor.activeObjectLayer.textObjects.length, "undo after redo restores the text object again");
		label = editor.activeObjectLayer.textObjects[0];
		clickEditorSidebar(editor, "deleteEntry");
		var textHit = label.localToGlobal(new Point(5, 5));
		assertEquals(true, editor.deleteSelectedObjectAt(textHit.x, textHit.y), "stamps delete tool removes touched text objects");
		assertEquals(0, editor.activeObjectLayer.textObjects.length, "text delete tool removes the text object");
		assertEquals(null, label.parent, "text delete tool unmounts the display object");
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601,m0;112;131,r0;1.24;0.75,d0",
			editor.activeObjectLayer.getActionString(), "text delete tool records a Flash delete action");
		clickEditorMenu(editor, "undoButton");
		assertEquals(1, editor.activeObjectLayer.textObjects.length, "undo restores text deleted with the delete tool");
		label = editor.activeObjectLayer.textObjects[0];
		editor.activeObjectLayer.removeTextObject(label);
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601,m0;112;131,r0;1.24;0.75,d0",
			editor.activeObjectLayer.getActionString(), "re-deleting restored text records a fresh delete action");
		assertEquals(0, editor.activeObjectLayer.redoArray.length, "fresh text actions clear the redo stack");
		clickEditorSidebar(editor, "stamp0Entry");
		var tree = editor.placeSelectedToolAt(100, 120);
		assertEquals(0, tree.code, "stamp placement stores the selected stamp code");
		assertEquals(-14, tree.x, "stamp placement centers by authored display width");
		assertEquals(34, tree.y, "stamp placement centers by authored display height");
		assertEquals(1, editor.activeObjectLayer.placedObjects.length, "stamp placement records object on active layer");
		assertEquals(1, editor.activeObjectLayer.numChildren, "stamp placement mounts a display object after deleted text");
		assertEquals("-14;34", editor.activeObjectLayer.getSaveString(), "stamp placement exports Flash relative object coordinates");
		editor.activeObjectLayer.selectPlacedStampForTests(0);
		assertEquals(true, editor.activeObjectLayer.placedStampHasAuthoredHandlesForTests(0), "stamp draw object uses authored delete and resize buttons");
		var stampOutline = editor.activeObjectLayer.placedStampOutlineBoundsForTests(0);
		assertEquals(true, stampOutline.width > 0 && stampOutline.height > 0, "stamp draw object shows a selection outline");
		clickEditorSidebar(editor, "deleteEntry");
		assertEquals("delete", editor.selectedToolId, "stamps delete entry selects the delete tool");
		assertEquals(true, editor.deleteSelectedObjectAt(100, 120), "stamps delete tool removes touched stamp objects");
		assertEquals(0, editor.activeObjectLayer.placedObjects.length, "stamp deletion removes the model object");
		assertEquals(0, editor.activeObjectLayer.numChildren, "stamp deletion unmounts the display object");
		clickEditorSidebar(editor, "stamp0Entry");
		tree = editor.placeSelectedToolAt(100, 120);
		assertEquals(1, editor.activeObjectLayer.placedObjects.length, "stamp can be placed again after deletion");
		clickEditorMenu(editor, "layer2Button");
		clickEditorSidebar(editor, "stamp5Entry");
		var rock = editor.placeSelectedToolAt(100, 120);
		assertEquals(2, editor.activeObjectLayer.layerNum, "layer 2 selects the second object layer");
		assertEquals(5, rock.code, "stamp placement follows the latest selected stamp");
		assertEquals(156, rock.x, "scaled layers convert stage x through globalToLocal");
		assertEquals(195, rock.y, "scaled layers convert stage y through globalToLocal");
		assertEquals("156;195;5", editor.activeObjectLayer.getSaveString(), "nonzero stamp codes export in the object layer save string");
		editor.selectEditorTool("tools", "eraser");
		assertEquals(true, editor.beginSelectedBrushAt(100, 120), "eraser starts on the active draw layer");
		assertEquals(true, editor.continueSelectedBrushAt(105, 120), "eraser extends while drawing");
		assertEquals(true, editor.endSelectedBrush(), "eraser stroke finishes");
		assertEquals("cffffff,t12,merase,d100;120;5;0", editor.activeDrawLayer.getSaveString(),
			"eraser stores selected size, erase color, mode, and unscaled drawable coordinates");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "undoButton"), "enabled"), "draw stroke enables undo");
		clickEditorMenu(editor, "undoButton");
		assertEquals("", editor.activeDrawLayer.getSaveString(), "draw undo removes the last stroke and setup actions");
		assertEquals(0, editor.activeDrawLayer.drawActions.length, "draw undo rebuilds decoded actions");
		assertEquals(0, editor.activeDrawLayer.rasterCanvas.numChildren, "draw undo clears rasterized art");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "redoButton"), "enabled"), "draw undo enables redo");
		clickEditorMenu(editor, "redoButton");
		assertEquals("cffffff,t12,merase,d100;120;5;0", editor.activeDrawLayer.getSaveString(), "draw redo restores the stroke group");
		assertEquals(4, editor.activeDrawLayer.drawActions.length, "draw redo rebuilds decoded setup, mode, and stroke actions");
		assertEquals(0, editor.activeDrawLayer.redoArray.length, "draw redo consumes the redo stack");
		assertEquals(1, editor.objectLayers[0].placedObjects.length, "layer 1 does not receive layer 2 stamp");
		assertEquals(1, editor.objectLayers[1].placedObjects.length, "layer 2 receives its own placed stamp");
		clickEditorMenu(editor, "blocksButton");
		assertEquals("blocks", editor.menu.sideBar.id, "blocks button restores blocks sidebar");
		clickEditorSidebar(editor, "itemEntry");
		var itemBlock = editor.placeSelectedBlockAt(100, 120);
		assertNotNull(itemBlock, "block sidebar places a block object");
		assertEquals(110, itemBlock.code, "item block placement stores the Flash block code");
		assertEquals(3, itemBlock.segX, "block placement snaps x to Flash grid");
		assertEquals(4, itemBlock.segY, "block placement snaps y to Flash grid");
		assertEquals(itemBlock, editor.selectedBlock, "newly placed block is selected");
		assertNotNull(itemBlock.getChildByName("optionsButton"), "option-capable selected blocks show the options button");
		itemBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(itemBlock, editor.lastBlockOptionsRequest, "options button records the selected block for popup wiring");
		assertNotNull(editor.activeBlockOptionsPopup, "item block opens the item option popup");
		var itemOneCheck = Std.downcast(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "check1"), FlCheckBox);
		var itemTwoCheck = Std.downcast(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "check2"), FlCheckBox);
		var itemFourCheck = Std.downcast(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "check4"), FlCheckBox);
		assertEquals(true, itemOneCheck.selected, "item popup selects level-default items");
		for (itemId in 1...10) {
			Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setItemSelected"), [itemId, false]);
		}
		itemOneCheck.selected = true;
		itemFourCheck.selected = true;
		editor.closeBlockOptionsPopup();
		assertEquals("1-4", itemBlock.options, "closing the item popup commits normalized item options");
		itemBlock.setOptions("none");
		itemBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		itemTwoCheck = Std.downcast(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "check2"), FlCheckBox);
		assertEquals(false, itemTwoCheck.selected, "item popup loads none as no selected items");
		editor.closeBlockOptionsPopup();
		assertEquals("none", itemBlock.options, "closing an empty item popup preserves the none option");
		clickEditorSidebar(editor, "brickEntry");
		var rejectedBrick = editor.placeSelectedBlockAt(100, 120);
		assertEquals(null, rejectedBrick, "placing over an existing block is ignored");
		assertEquals(5, editor.blockLayer.blocks.length, "ignored occupied placement keeps the existing blocks");
		assertEquals(itemBlock, editor.blockLayer.getBlockAtSeg(3, 4), "occupied placement preserves the existing block");
		assertNotNull(itemBlock.parent, "occupied placement leaves the existing block mounted");
		var brickBlock = editor.placeSelectedBlockAt(130, 120);
		assertEquals(104, brickBlock.code, "placing on an empty segment creates the selected block");
		assertEquals(6, editor.blockLayer.blocks.length, "empty placement adds a block beside the item block");
		assertEquals(null, brickBlock.getChildByName("optionsButton"), "plain selected blocks do not show options");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "undoButton"), "enabled"), "block placement enables undo");
		clickEditorMenu(editor, "settingsButton");
		assertEquals(false, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "undoButton"), "enabled"),
			"settings sidebar hides block undo state");
		clickEditorMenu(editor, "blocksButton");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "undoButton"), "enabled"),
			"blocks button restores block undo state");
		clickEditorMenu(editor, "undoButton");
		var restoredItemBlock = editor.blockLayer.getBlockAtSeg(3, 4);
		assertNotNull(restoredItemBlock, "block undo keeps the existing item block");
		assertEquals(110, restoredItemBlock.code, "block undo restores the replaced block code");
		assertEquals("none", restoredItemBlock.options, "block undo restores the replaced block options");
		assertEquals(null, editor.blockLayer.getBlockAtSeg(4, 4), "block undo removes the newly placed brick block");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "redoButton"), "enabled"), "block undo enables redo");
		clickEditorMenu(editor, "redoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(4, 4);
		assertNotNull(brickBlock, "block redo restores the replacement block");
		assertEquals(104, brickBlock.code, "block redo restores the replacement block code");
		brickBlock.setOptions("legacy");
		assertEquals("444;335;11,1;0;12,1;0;13,1;0;14,-444;-331;10;none,1;0;4;legacy", editor.blockLayer.getSaveString(),
			"block save string uses Flash relative grid coordinates and option suffixes");
		clickEditorMenu(editor, "undoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(4, 4);
		assertEquals("", brickBlock.options, "block undo reverts option changes");
		clickEditorMenu(editor, "redoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(4, 4);
		assertEquals("legacy", brickBlock.options, "block redo restores option changes");
		clickEditorSidebar(editor, "deleteEntry");
		assertEquals("delete", editor.selectedToolId, "blocks delete entry selects the delete tool");
		brickBlock.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(5, editor.blockLayer.blocks.length, "blocks delete tool removes the target block");
		assertEquals(null, brickBlock.parent, "deleted block is unmounted");
		assertEquals(null, editor.selectedBlock, "deleted selected block clears selection");
		assertEquals("444;335;11,1;0;12,1;0;13,1;0;14,-444;-331;10;none", editor.blockLayer.getSaveString(),
			"block save string updates after deleting a placed block");
		clickEditorMenu(editor, "undoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(4, 4);
		assertNotNull(brickBlock, "block undo restores deleted blocks");
		assertEquals("legacy", brickBlock.options, "block undo restores deleted block options");
		clickEditorMenu(editor, "redoButton");
		assertEquals(null, editor.blockLayer.getBlockAtSeg(4, 4), "block redo reapplies deletion");
		assertEquals(0, editor.blockLayer.redoArray.length, "block redo consumes the redo stack");
		clickEditorSidebar(editor, "happyEntry");
		var happyBlock = editor.placeSelectedBlockAt(160, 120);
		happyBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertNotNull(editor.activeBlockOptionsPopup, "happy block opens the stat option popup");
		assertNotNull(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "slider"), "stat popup uses the authored slider");
		assertEquals("-- Happy Block --", Reflect.getProperty(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "titleBox"), "text"),
			"happy stat popup keeps the authored title text");
		Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setStatMagnitude"), [25]);
		editor.closeBlockOptionsPopup();
		assertEquals("25", happyBlock.options, "closing the happy stat popup commits normalized options");
		clickEditorSidebar(editor, "sadEntry");
		var sadBlock = editor.placeSelectedBlockAt(190, 120);
		sadBlock.setOptions("-35");
		sadBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals("-- Sad Block --", Reflect.getProperty(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "titleBox"), "text"),
			"sad stat popup rewrites the authored title text");
		Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setStatMagnitude"), [5]);
		editor.closeBlockOptionsPopup();
		assertEquals("", sadBlock.options, "closing the sad stat popup commits default as empty options");
		clickEditorSidebar(editor, "teleportEntry");
		var teleportBlock = editor.placeSelectedBlockAt(220, 120);
		assertEquals(true, teleportBlock.teleportBackgroundVisibleForTests(), "editor teleport block renders its solid color backing");
		assertEquals(EditorBlockOptions.TELEPORT_DEFAULT_COLOR, teleportBlock.teleportColorForTests(),
			"editor teleport block starts with the Flash coral backing color");
		teleportBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertNotNull(editor.activeBlockOptionsPopup, "teleport block opens the teleport option popup");
		assertNotNull(DisplayUtil.findByName(editor.activeBlockOptionsPopup, "colorPicker"), "teleport popup mounts the color picker");
		Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setTeleportColor"), [0x00FF00]);
		editor.closeBlockOptionsPopup();
		assertEquals("65280", teleportBlock.options, "closing the teleport popup commits normalized color options");
		assertEquals(0x00FF00, teleportBlock.teleportColorForTests(), "editor teleport backing refreshes after changing options");
		teleportBlock.setOptions("65280");
		teleportBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setTeleportColor"),
			[EditorBlockOptions.TELEPORT_DEFAULT_COLOR]);
		editor.closeBlockOptionsPopup();
		assertEquals("", teleportBlock.options, "closing the teleport popup stores the default color as empty options");
		clickEditorSidebar(editor, "customEntry");
		var customBlock = editor.placeSelectedBlockAt(250, 120);
		customBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertNotNull(editor.activeBlockOptionsPopup, "custom stats block opens the custom stat popup");
		var speedSlider = Std.downcast(editor.activeBlockOptionsPopup.getChildByName("speedSlider"), StatSlider);
		var resetCheck = Std.downcast(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "resetChk"), FlCheckBox);
		assertNotNull(speedSlider, "custom stat popup mounts the authored speed slider");
		assertNotNull(resetCheck, "custom stat popup uses the authored reset checkbox");
		assertEquals(50, speedSlider.value, "custom stat popup loads default speed");
		Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setCustomStats"), [20, 30, 40]);
		editor.closeBlockOptionsPopup();
		assertEquals("20-30-40", customBlock.options, "closing the custom stat popup commits normalized stats");
		customBlock.setOptions("reset");
		customBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		speedSlider = Std.downcast(editor.activeBlockOptionsPopup.getChildByName("speedSlider"), StatSlider);
		resetCheck = Std.downcast(DisplayUtil.findByName(editor.activeBlockOptionsPopup.art, "resetChk"), FlCheckBox);
		assertEquals(true, resetCheck.selected, "custom stat popup loads the reset marker");
		assertEquals(false, speedSlider.mouseEnabled, "reset disables the custom stat sliders");
		Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setResetSelected"), [true]);
		editor.closeBlockOptionsPopup();
		assertEquals("reset", customBlock.options, "closing the reset custom stat popup commits the reset marker");
		editor.remove();
		assertEquals(null, LevelEditor.editor, "editor shell clears singleton");

		LobbySession.group = 1;
		LobbySession.userName = "EditorUser";
		LobbySession.token = "editor-token";
		LobbySession.remember = true;
		LobbySession.server = serverInfo(0);
		editor = new LevelEditor(null, true, false);
		editor.initialize();
		assertEquals(true, editor.isMod, "editor shell stores permanent mod flag");
		assertEquals(false, editor.reportsMode, "editor shell starts outside reports mode");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "saveButton"), "enabled"), "members can save");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "loadButton"), "enabled"), "members can load");
		editor.menu.setReportsMode(true);
		assertEquals(false, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "saveButton"), "enabled"), "reports mode disables save");
		assertEquals(true, editor.reportsMode, "menu reports mode updates editor");
		popupCount = Popup.getOpen().length;
		clickEditorMenu(editor, "saveButton");
		assertEquals(popupCount, Popup.getOpen().length, "reports mode save button does not open a popup");
		editor.title = "Dirty";
		editor.note = "unsaved";
		editor.setColor(0x123456);
		editor.menu.setReportsMode(false);
		editor.selectEditorTool("blocks", "brick");
		var dirtyBlock = editor.placeSelectedBlockAt(100, 120);
		assertNotNull(dirtyBlock, "new button setup places a dirty block");
		clickEditorMenu(editor, "newButton");
		var confirm = lastConfirmPopup();
		assertNotNull(confirm, "new button opens a confirmation prompt");
		assertEquals(true, LobbyArt.text(confirm, "textBox").htmlText.indexOf("clear this level") >= 0,
			"new button confirmation matches Flash copy");
		clickPopup(confirm, "ok_bt");
		assertEquals("", editor.title, "confirmed new clears title");
		assertEquals("", editor.note, "confirmed new clears note");
		assertEquals(LevelConfig.DEFAULT_COLOR, editor.color, "confirmed new restores default background color");
		assertEquals(4, editor.blockLayer.blocks.length, "confirmed new restores only default start blocks");
		assertEquals(null, editor.blockLayer.getBlockAtSeg(3, 4), "confirmed new removes placed blocks");
		assertEquals("blocks", editor.focusedEditorLayer, "confirmed new resets focus to block layer");
		clickEditorMenu(editor, "exitButton");
		confirm = lastConfirmPopup();
		assertNotNull(confirm, "exit button opens a confirmation prompt");
		assertEquals(true, LobbyArt.text(confirm, "textBox").htmlText.indexOf("Are you sure you want exit?") >= 0,
			"exit button confirmation matches Flash copy");
		clickPopup(confirm, "ok_bt");
		var connectingPopup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], LevelEditorConnectingPopup);
		assertEquals(true, connectingPopup != null,
			"confirmed exit opens the connecting popup");
		assertEquals(true, connectingPopup.connectionAttempted, "editor exit starts the Flash lobby reconnection handshake");
		editor.remove();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function clickEditorMenu(editor:LevelEditor, name:String):Void {
		DisplayUtil.findByName(editor.menu.art, name).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function clickEditorSidebar(editor:LevelEditor, name:String):Void {
		editor.menu.sideBar.getChildByName(name).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function testLevelEditorLoadListPopup():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.token = "load-token";
		ServerConfig.setHost("http://example.test");
		var previousPostFactory = GetLevelsPopup.postFactory;
		var previousLoadFactory = GetLevelsPopup.loadFactory;
		var requestedUrl:Null<String> = null;
		var requestedToken:Null<String> = null;
		var loaded:Null<String> = null;
		GetLevelsPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			requestedUrl = url;
			requestedToken = fields.get("token");
			onResult({
				levels: [
					{
						level_id: "7",
						version: "1234",
						title: "Alpha <One>",
						live: "1",
						type: "e",
						time: "1609502400",
						play_count: "12345",
						rating: "4.5",
						note: "line <one>\nsecond & line"
					},
					{level_id: "8", version: "4", title: "Beta", live: "0", type: "d", play_count: "2", rating: "3", note: ""}
				]
			});
		};
		GetLevelsPopup.loadFactory = function(levelId:Int, version:Int):Void {
			loaded = levelId + ":" + version;
		};

		var editor = new LevelEditor(null, false, false);
		editor.initialize();
		clickEditorMenu(editor, "loadButton");
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], GetLevelsPopup);
		assertNotNull(popup, "load button opens the editor levels popup");
		assertNotNull(Reflect.field(popup, "scroll"), "load popup mounts the authored scrollbar");
		assertEquals("http://example.test/levels_get.php", requestedUrl, "load popup posts to levels_get");
		assertEquals("load-token", requestedToken, "load popup sends the session token");
		assertEquals(2, popup.listings.length, "load popup renders returned listings");
		assertEquals("Alpha <One>", LobbyArt.text(popup.listings[0].art, "titleBox").text, "listing renders title");
		assertEquals("Published", LobbyArt.text(popup.listings[0].art, "statusBox").text, "listing renders published state");
		assertEquals(1, popup.listings[0].art.currentFrame, "load listing row starts on the authored up frame");
		popup.listings[0].art.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, popup.listings[0].art.currentFrame, "load listing row does not auto-play through button states");
		popup.listings[0].dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER, true));
		assertEquals("Alpha <One>", popup.listings[0].titleTextForTests(), "hover state preserves the saved level title");
		assertEquals("Published", popup.listings[0].statusTextForTests(), "hover state preserves the saved level status");
		popup.listings[0].dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT, true));
		assertEquals("Alpha <One>", popup.listings[0].titleTextForTests(), "mouse out restores data instead of the authored placeholder");
		assertEquals("-- Alpha &lt;One&gt; --", GetLevelsPopupItem.hoverTitleForTests(popup.listings[0].level),
			"owned listing hover title escapes HTML");
		assertEquals("Game Mode: Alien Eggs<br/>"
			+ "Version: 1,234<br/>"
			+ "Updated: " + Data.getShortDateStr(1609502400.0) + "<br/>"
			+ "Plays: 12,345<br/>"
			+ "Rating: 4.5<br/>-----<br/><i>line &lt;one&gt;\nsecond &amp; line</i>",
			GetLevelsPopupItem.hoverBodyForTests(popup.listings[0].level), "owned listing hover body matches Flash formatting");
		popup.listings[0].showHoverForTests();
		assertEquals(550, Std.int(popup.listings[0].hoverXForTests() + popup.listings[0].hoverWidthForTests()),
			"owned listing hover right-aligns to Flash x position");

		var reported = new GetReportedLevelsPopupItem({
			level_id: "9",
			version: "1",
			title: "Reported",
			report_time: "0",
			creator: "Case",
			note: "",
			reporter: "Mod",
			reason: "test"
		}, null);
		assertEquals(1, reported.art.currentFrame, "reported listing row starts on the authored up frame");
		reported.art.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, reported.art.currentFrame, "reported listing row does not auto-play through button states");

		popup.selectListing(popup.listings[0]);
		DisplayUtil.findByName(popup.art, "load_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals("7:1234", loaded, "loading a listing hands off id and version");
		assertEquals(true, popup.fadeOutStarted, "loading a listing closes the list popup");

		popup.remove();
		editor.remove();
		GetLevelsPopup.loadFactory = previousLoadFactory;
		GetLevelsPopup.postFactory = previousPostFactory;
		ServerConfig.resetHost();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testLevelEditorLoadingLevelPopup():Void {
		closeAllPopups();
		var previousFetchFactory = LoadingLevelPopup.fetchFactory;
		var requested:Null<String> = null;
		var successCallbacks:Array<pr2.net.ServerLevelData->Void> = [];
		var errorCallbacks:Array<String->Void> = [];
		LoadingLevelPopup.fetchFactory = function(levelId:Int, version:Int, onResult:pr2.net.ServerLevelData->Void,
				onError:String->Void):Void {
			requested = levelId + ":" + version;
			successCallbacks.push(onResult);
			errorCallbacks.push(onError);
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		var popup = new LoadingLevelPopup(31, 4, true);
		assertEquals("31:4", requested, "loading popup requests selected level version");
		assertEquals("Loading level...", LobbyArt.text(popup.art, "textBox").text, "loading popup shows Flash copy");
		assertEquals(1, successCallbacks.length, "loading popup stores success callback");
		assertEquals(1, errorCallbacks.length, "loading popup stores error callback");

		var loadedData = [
			"m4",
			"abcdef",
			"",
			"10;20;0;150;75,5;6;t;hello#44world;16711935;120;80",
			"",
			"",
			"c123456,d1;2",
			"",
			"",
			"",
			"",
			"",
			"",
			""
		].join("`");
		var levelData = "level_id=31&version=4&title=Loaded+Via+Popup&live=1&data=" + loadedData;
		successCallbacks[0](LevelDataClient.parseEditorLoad(signedLevel(levelData, 31, 4), 31, 4));
		assertEquals("Loaded Via Popup", editor.title, "loading popup applies validated editor variables");
		assertEquals(true, editor.reportsMode, "loading popup preserves reported-level mode");
		assertEquals(1, editor.objectLayers[0].placedObjects.length, "loading popup hydrates placed stamp objects");
		assertEquals(0, editor.objectLayers[0].placedObjects[0].code, "loaded stamp preserves code");
		assertEquals(10, editor.objectLayers[0].placedObjects[0].x, "loaded stamp preserves local x");
		assertEquals(20, editor.objectLayers[0].placedObjects[0].y, "loaded stamp preserves local y");
		assertEquals(1.5, editor.objectLayers[0].placedObjects[0].scaleX, "loaded stamp preserves width scale");
		assertEquals(0.75, editor.objectLayers[0].placedObjects[0].scaleY, "loaded stamp preserves height scale");
		assertEquals(1, editor.objectLayers[0].textObjects.length, "loading popup hydrates text objects");
		assertEquals("hello,world", editor.objectLayers[0].textObjects[0].text, "loaded text parses escaped content");
		assertEquals(15, editor.objectLayers[0].textObjects[0].x, "loaded text preserves relative cursor x");
		assertEquals(26, editor.objectLayers[0].textObjects[0].y, "loaded text preserves relative cursor y");
		assertEquals(0xFF00FF, editor.objectLayers[0].textObjects[0].color, "loaded text preserves color");
		assertEquals(1.2, editor.objectLayers[0].textObjects[0].scaleX, "loaded text preserves width scale");
		assertEquals(0.8, editor.objectLayers[0].textObjects[0].scaleY, "loaded text preserves height scale");
		assertEquals("10;20;150;75,5;6;t;hello#44world;16711935;120;80", editor.objectLayers[0].getSaveString(),
			"loaded object layer exports equivalent save string");
		assertEquals("c123456,d1;2", editor.drawLayers[0].getSaveString(), "loading popup still hydrates draw layers");
		assertEquals(true, popup.fadeOutStarted, "loading popup fades after level load");

		popup.remove();
		popup = new LoadingLevelPopup(32, 5, false);
		errorCallbacks[1]("network went away");
		var errorMessage = lastMessagePopup();
		assertNotNull(errorMessage, "loading popup opens a MessagePopup on fetch errors");
		assertEquals(true, LobbyArt.text(errorMessage, "textBox").htmlText.indexOf("Error: network went away") >= 0,
			"loading popup prefixes raw fetch failures like Flash SuperLoader");
		assertEquals(true, popup.fadeOutStarted, "loading popup fades after fetch error");

		popup.remove();
		editor.remove();
		LoadingLevelPopup.fetchFactory = previousFetchFactory;
		closeAllPopups();
	}

	private static function testLevelEditorReportedLevelsPopup():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.token = "report-token";
		ServerConfig.setHost("http://example.test");
		var previousPostFactory = GetReportedLevelsPopup.postFactory;
		var previousLoadFactory = GetReportedLevelsPopup.loadFactory;
		var requestedUrl:Null<String> = null;
		var requestedToken:Null<String> = null;
		var loaded:Null<String> = null;
		GetReportedLevelsPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			requestedUrl = url;
			requestedToken = fields.get("token");
			onResult({
				levels: [
					{
						level_id: "51",
						version: "12345",
						title: "Reported <One>",
						creator: "Maker & Co",
						report_time: "1363478400",
						reporter: "Concerned <Mod>",
						reason: "Bad <art>",
						note: "check <this>\nsecond & line"
					}
				]
			});
		};
		GetReportedLevelsPopup.loadFactory = function(levelId:Int, version:Int):Void {
			loaded = levelId + ":" + version;
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		clickEditorMenu(editor, "loadButton");
		var choice = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], ChooseLevelsModePopup);
		assertNotNull(choice, "moderator load opens the authored level-mode chooser");
		DisplayUtil.findByName(choice.art, "reports_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, choice.fadeOutStarted, "choosing reported levels closes the chooser");
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], GetReportedLevelsPopup);
		assertNotNull(popup, "reported-level choice opens the reported levels popup");
		assertEquals("http://example.test/levels_get_reported.php", requestedUrl, "reported popup posts to levels_get_reported");
		assertEquals("report-token", requestedToken, "reported popup sends the session token");
		assertEquals("-- Reported Levels --", LobbyArt.text(popup.art, "titleBox").text, "reported popup title matches Flash");
		assertEquals(1, popup.listings.length, "reported popup renders returned listings");
		assertEquals("Reported <One>", LobbyArt.text(popup.listings[0].art, "titleBox").text, "reported listing renders title");
		assertEquals("16/Mar/2013", LobbyArt.text(popup.listings[0].art, "timeBox").text, "reported listing renders report date");
		assertEquals("-- Reported &lt;One&gt; --", GetReportedLevelsPopupItem.hoverTitleForTests(popup.listings[0].level),
			"reported listing hover title escapes HTML");
		assertEquals("Creator: Maker &amp; Co<br/>"
			+ "Version: 12,345<br/>"
			+ "Note: <i>check &lt;this&gt;\nsecond &amp; line</i><br/>"
			+ "-----<br/>"
			+ "Reported: " + Data.getShortDateStr(1363478400.0) + "<br/>"
			+ "^ By: Concerned &lt;Mod&gt;<br/>"
			+ "Reason: <i>Bad &lt;art&gt;</i>", GetReportedLevelsPopupItem.hoverBodyForTests(popup.listings[0].level),
			"reported listing hover body matches Flash formatting");
		popup.listings[0].showHoverForTests();
		assertEquals(550, Std.int(popup.listings[0].hoverXForTests() + popup.listings[0].hoverWidthForTests()),
			"reported listing hover right-aligns to Flash x position");
		popup.listings[0].hideHoverForTests();
		assertEquals(false, popup.listings[0].hasHoverForTests(), "reported listing hover cleans up on mouse out");

		popup.selectListing(popup.listings[0]);
		DisplayUtil.findByName(popup.art, "load_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals("51:12345", loaded, "reported listing load hands off id and version");
		assertEquals(true, popup.fadeOutStarted, "loading a reported listing closes the list popup");

		popup.remove();
		choice.remove();
		editor.remove();
		GetReportedLevelsPopup.loadFactory = previousLoadFactory;
		GetReportedLevelsPopup.postFactory = previousPostFactory;
		ServerConfig.resetHost();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testLevelEditorReportHandlePopup():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		ServerConfig.setHost("http://example.test");
		var previousPostFactory = GetReportedLevelsPopup.postFactory;
		var previousUploadFactory = HandleLevelReportPopup.uploadFactory;
		var previousReopenFactory = HandleLevelReportPopup.reopenFactory;
		var uploads:Array<UploadLevelCall> = [];
		var reopenCount = 0;
		GetReportedLevelsPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			onResult({
				levels: [
					{
						level_id: "51",
						version: "6",
						title: "Reported One",
						creator: "Maker",
						creator_group: "1",
						report_time: "1363478400",
						reporter: "Concerned",
						reason: "Bad art",
						note: "check this"
					}
				]
			});
		};
		HandleLevelReportPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			onResult(url.indexOf("ban_user.php") >= 0 ? {message: "Ban recorded"} : {success: true});
			return null;
		};
		HandleLevelReportPopup.reopenFactory = function():Void {
			reopenCount++;
		};

		var reports = new GetReportedLevelsPopup();
		reports.selectListing(reports.listings[0]);
		DisplayUtil.findByName(reports.art, "delete_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var handle = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], HandleLevelReportPopup);
		assertNotNull(handle, "handle button opens the authored report handling popup");
		var title = LobbyArt.text(handle.art, "titleBox");
		assertEquals(true, title != null && title.htmlText.indexOf("Reported One") >= 0 && title.htmlText.indexOf("Maker") >= 0,
			"report handling title links the level and creator");

		DisplayUtil.findByName(handle.art, "archive_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var confirm = lastConfirmPopup();
		assertNotNull(confirm, "archive opens confirmation");
		clickPopup(confirm, "ok_bt");
		assertEquals(1, uploads.length, "confirming archive posts once");
		assertEquals("http://example.test/mod/archive_report.php", uploads[0].url, "archive endpoint matches Flash");
		assertEquals("51", uploads[0].fields.get("level_id"), "archive posts level id");
		assertEquals("6", uploads[0].fields.get("version"), "archive posts version");
		assertEquals("Archiving report...", uploads[0].label, "archive progress label matches Flash");
		assertEquals(true, reports.fadeOutStarted, "archiving closes the reported list");
		assertEquals(true, handle.fadeOutStarted, "archiving closes the handling popup");
		assertEquals(1, reopenCount, "archiving refreshes the reported list");
		handle.remove();
		reports.remove();

		uploads = [];
		reopenCount = 0;
		reports = new GetReportedLevelsPopup();
		reports.selectListing(reports.listings[0]);
		DisplayUtil.findByName(reports.art, "delete_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		handle = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], HandleLevelReportPopup);
		var duration = Std.downcast(DisplayUtil.findByName(handle.art, "duration"), FlComboBox);
		duration.selectedIndex = 2;
		var reason = Std.downcast(DisplayUtil.findByName(handle.art, "reason"), FlComboBox);
		reason.selectedIndex = 1;
		DisplayUtil.findByName(handle.art, "ban_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		confirm = lastConfirmPopup();
		assertNotNull(confirm, "ban opens confirmation");
		clickPopup(confirm, "ok_bt");
		assertEquals(2, uploads.length, "confirmed social ban posts ban then archive");
		assertEquals("http://example.test/ban_user.php", uploads[0].url, "ban endpoint matches Flash");
		assertEquals("Unpublishing and banning...", uploads[0].label, "ban progress label matches Flash");
		assertEquals("Maker", uploads[0].fields.get("banned_name"), "ban posts reported level creator");
		assertEquals("86400", uploads[0].fields.get("duration"), "ban posts selected duration");
		assertEquals("Inappropriate Level -- Vulgar Language", uploads[0].fields.get("reason"), "ban prefixes the selected reason");
		assertEquals("social", uploads[0].fields.get("scope"), "ban is social scoped");
		assertEquals(true, uploads[0].fields.get("record").indexOf("Level ID: 51") >= 0, "ban posts a level record");
		assertEquals("http://example.test/mod/archive_report.php", uploads[1].url, "ban success archives the report");
		assertEquals(1, reopenCount, "ban archive refreshes the reported list");
		assertNotNull(lastMessagePopup(), "ban response message is shown after archive");

		handle.remove();
		reports.remove();
		HandleLevelReportPopup.reopenFactory = previousReopenFactory;
		HandleLevelReportPopup.uploadFactory = previousUploadFactory;
		GetReportedLevelsPopup.postFactory = previousPostFactory;
		ServerConfig.resetHost();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testLevelEditorDeleteFlow():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.token = "delete-token";
		ServerConfig.setHost("http://example.test");
		var previousListFactory = GetLevelsPopup.postFactory;
		var previousLoadFactory = GetLevelsPopup.loadFactory;
		var previousDeleteFactory = DeletingLevelPopup.postFactory;
		var listRequests = 0;
		var requestedToken:Null<String> = null;
		var loads = 0;
		var uploads:Array<UploadLevelCall> = [];
		GetLevelsPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			listRequests++;
			requestedToken = fields.get("token");
			onResult({
				levels: [
					{level_id: "42", version: "5", title: "Delete <Me>", live: "0", type: "r", play_count: "1", rating: "0", note: ""}
				]
			});
		};
		GetLevelsPopup.loadFactory = function(levelId:Int, version:Int):Void {
			loads++;
		};
		DeletingLevelPopup.postFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			onResult({success: true});
			return null;
		};

		var editor = new LevelEditor(null, false, false);
		editor.initialize();
		clickEditorMenu(editor, "loadButton");
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], GetLevelsPopup);
		assertNotNull(popup, "delete flow opens the editor levels popup");
		assertEquals("delete-token", requestedToken, "delete flow list request sends the session token");
		popup.selectListing(popup.listings[0]);
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(popup.art, "delete_bt"), "enabled"), "selecting a level enables delete");
		DisplayUtil.findByName(popup.art, "delete_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var confirm = lastConfirmPopup();
		assertNotNull(confirm, "delete button opens confirmation");
		var text = LobbyArt.text(confirm, "textBox");
		assertEquals(true, text != null && text.htmlText.indexOf("Delete &lt;Me&gt;") >= 0, "delete confirmation escapes the title");
		clickPopup(confirm, "ok_bt");

		assertEquals(0, loads, "deleting does not trigger the load handoff");
		assertEquals(1, uploads.length, "confirming delete posts once");
		assertEquals("http://example.test/delete_level.php", uploads[0].url, "delete endpoint matches Flash");
		assertEquals("Deleting level...", uploads[0].label, "delete progress label matches Flash");
		assertEquals("42", uploads[0].fields.get("level_id"), "delete posts selected level id");
		assertEquals("delete-token", uploads[0].fields.get("token"), "delete posts SuperLoader token");
		var rand = Std.parseInt(uploads[0].fields.get("rand"));
		assertEquals(true, rand != null && rand >= 0 && rand < 10000000, "delete posts SuperLoader rand");
		assertEquals(true, popup.fadeOutStarted, "confirmed delete closes the original list popup");
		assertEquals(2, listRequests, "successful delete reopens the levels list");

		editor.remove();
		DeletingLevelPopup.postFactory = previousDeleteFactory;
		GetLevelsPopup.loadFactory = previousLoadFactory;
		GetLevelsPopup.postFactory = previousListFactory;
		ServerConfig.resetHost();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testLevelEditorSaveDialog():Void {
		LobbySession.clear();
		LobbySession.group = 1;
		var previousFactory = SaveLevelPopup.uploadFactory;
		var uploadedEditor:Null<LevelEditor> = null;
		SaveLevelPopup.uploadFactory = function(editor:LevelEditor):Null<pr2.lobby.dialogs.Popup> {
			uploadedEditor = editor;
			return null;
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		editor.title = "Old Title";
		editor.note = "old note";
		editor.live = 1;
		editor.toNewest = false;

		clickEditorMenu(editor, "saveButton");
		var popup = Std.downcast(pr2.lobby.dialogs.Popup.getOpen()[pr2.lobby.dialogs.Popup.getOpen().length - 1], SaveLevelPopup);
		assertNotNull(popup, "save button opens the authored save dialog");
		assertEquals("Old Title", LobbyArt.text(popup.art, "titleBox").text, "save dialog loads title");
		assertEquals("old note", LobbyArt.text(popup.art, "noteBox").text, "save dialog loads note");
		assertEquals(50, LobbyArt.text(popup.art, "titleBox").maxChars, "save dialog preserves title input limit");
		assertEquals(255, LobbyArt.text(popup.art, "noteBox").maxChars, "save dialog preserves note input limit");
		var publish = Std.downcast(DisplayUtil.findByName(popup.art, "publish_chk"), FlCheckBox);
		var newest = Std.downcast(DisplayUtil.findByName(popup.art, "newest_chk"), FlCheckBox);
		assertEquals(true, publish.selected, "save dialog loads published state");
		assertEquals(true, newest.enabled, "published levels enable newest checkbox");
		assertEquals(false, newest.selected, "save dialog loads to-newest state");

		publish.selected = false;
		publish.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(false, newest.enabled, "unpublishing disables newest checkbox");
		assertEquals(false, newest.selected, "unpublishing clears newest checkbox");
		publish.selected = true;
		publish.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(true, newest.enabled, "publishing re-enables newest checkbox");
		assertEquals(true, newest.selected, "publishing selects newest like Flash");

		LobbyArt.text(popup.art, "titleBox").text = "";
		DisplayUtil.findByName(popup.art, "save_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(null, uploadedEditor, "empty title blocks save upload");
		var message = Std.downcast(pr2.lobby.dialogs.Popup.getOpen()[pr2.lobby.dialogs.Popup.getOpen().length - 1], pr2.lobby.dialogs.MessagePopup);
		assertNotNull(message, "empty title opens the Flash validation message");
		message.remove();

		LobbyArt.text(popup.art, "titleBox").text = "New Title";
		LobbyArt.text(popup.art, "noteBox").text = "new note";
		DisplayUtil.findByName(popup.art, "save_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(editor, uploadedEditor, "valid save launches upload handoff");
		assertEquals("New Title", editor.title, "save dialog commits title");
		assertEquals("new note", editor.note, "save dialog commits note");
		assertEquals(1.0, editor.live, "save dialog commits publish state");
		assertEquals(true, editor.toNewest, "save dialog commits newest state");
		assertEquals("1", editor.getLevelVars().get("to_newest"), "editor vars export newest flag");
		popup.remove();
		editor.remove();
		SaveLevelPopup.uploadFactory = previousFactory;
		LobbySession.clear();
	}

	private static function testUploadingLevelPopupFields():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.userName = "CaseUser";
		LobbySession.token = "session-token";
		ServerConfig.setHost("http://example.test");
		var previousFactory = UploadingLevelPopup.postFactory;
		var uploads:Array<UploadLevelCall> = [];
		UploadingLevelPopup.postFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			onResult({success: true});
			return null;
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		editor.title = "Hash Me";
		editor.note = "saved note";
		editor.live = 1;
		editor.toNewest = false;
		var data = editor.getSaveString();
		new UploadingLevelPopup(editor, true, true);

		assertEquals(1, uploads.length, "level upload posts once");
		assertEquals("http://example.test/upload_level.php", uploads[0].url, "level upload endpoint matches Flash");
		assertEquals("Uploading level...", uploads[0].label, "level upload progress label");
		assertEquals("Hash Me", uploads[0].fields.get("title"), "level title posts");
		assertEquals("saved note", uploads[0].fields.get("note"), "level note posts");
		assertEquals(data, uploads[0].fields.get("data"), "serialized level data posts");
		assertEquals(Md5.encode("Hash Me" + "caseuser" + data + ServerConfig.LEVEL_SALT), uploads[0].fields.get("hash"), "upload hash matches Flash formula");
		assertEquals("0", uploads[0].fields.get("to_newest"), "to-newest posts from editor state");
		assertEquals("1", uploads[0].fields.get("override_banned"), "ban override flag posts");
		assertEquals("1", uploads[0].fields.get("overwrite_existing"), "overwrite flag posts");
		assertEquals("session-token", uploads[0].fields.get("token"), "session token posts like SuperLoader");
		var rand = Std.parseInt(uploads[0].fields.get("rand"));
		assertEquals(true, rand != null && rand >= 0 && rand < 10000000, "rand field matches SuperLoader range");

		editor.remove();
		UploadingLevelPopup.postFactory = previousFactory;
		ServerConfig.resetHost();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testUploadingLevelPopupDecodesUrlResponse():Void {
		var previousRequestFactory = pr2.lobby.dialogs.UploadingPopup.requestFactory;
		var capturedRequest:Dynamic = null;
		var parsed:Dynamic = null;
		pr2.lobby.dialogs.UploadingPopup.requestFactory = function(request, onResult, onError):Void {
			capturedRequest = request;
			onResult("status=exists&message=Level%20already%20exists");
		};
		var fields = ["title" => "URL response"];
		var popup = UploadingLevelPopup.defaultPost("/api/upload_level.php", fields, "Uploading level...", function(result):Void {
			parsed = result;
		}, function(_):Void {});

		assertEquals("POST", Std.string(capturedRequest.method), "level upload keeps the Flash POST method");
		assertEquals("URL response", Std.string(Reflect.field(capturedRequest.data, "title")), "level upload posts URL variables");
		assertEquals("exists", Std.string(Reflect.field(parsed, "status")), "level upload decodes URL-variable status responses");
		assertEquals("Level already exists", Std.string(Reflect.field(parsed, "message")), "level upload decodes URL-variable messages");
		popup.remove();
		pr2.lobby.dialogs.UploadingPopup.requestFactory = previousRequestFactory;
		closeAllPopups();
	}

	private static function testUploadingLevelPopupDrawingRetryWait():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.userName = "CaseUser";
		LobbySession.token = "session-token";
		var previousPostFactory = UploadingLevelPopup.postFactory;
		var previousRetryFactory = UploadingLevelPopup.retryFactory;
		var uploads:Array<UploadLevelCall> = [];
		var retryCallbacks:Array<Void->Void> = [];
		var retryDelays:Array<Int> = [];
		UploadingLevelPopup.postFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			onResult({success: true});
			return null;
		};
		UploadingLevelPopup.retryFactory = function(callback:Void->Void, delayMs:Int):Null<haxe.Timer> {
			retryCallbacks.push(callback);
			retryDelays.push(delayMs);
			return null;
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		editor.title = "Waiting Save";
		editor.selectEditorTool("tools", "brush");
		assertEquals(true, editor.beginSelectedBrushAt(10, 12), "brush drawing starts before save");
		var popup = new UploadingLevelPopup(editor);
		assertEquals(0, uploads.length, "save upload waits while editor is drawing");
		assertEquals(false, popup.fadeOutStarted, "waiting save popup stays alive for retry");
		assertEquals(1, retryDelays.length, "drawing save arms one retry");
		assertEquals(1000, retryDelays[0], "drawing save retries after Flash one-second wait");

		retryCallbacks.shift()();
		assertEquals(0, uploads.length, "drawing retry keeps waiting while brush is still active");
		assertEquals(2, retryDelays.length, "drawing retry re-arms the wait");
		assertEquals(1000, retryDelays[1], "drawing retry keeps Flash one-second wait");
		assertEquals(true, editor.endSelectedBrush(), "brush drawing finishes before upload retry");
		retryCallbacks.shift()();
		assertEquals(1, uploads.length, "save upload posts after drawing finishes");
		assertEquals("Waiting Save", uploads[0].fields.get("title"), "deferred upload uses editor level vars");
		assertEquals(true, popup.fadeOutStarted, "deferred save popup fades after upload posts");

		editor.remove();
		UploadingLevelPopup.retryFactory = previousRetryFactory;
		UploadingLevelPopup.postFactory = previousPostFactory;
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testUploadingLevelPopupOverwriteConfirmation():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.userName = "CaseUser";
		LobbySession.token = "session-token";
		var previousFactory = UploadingLevelPopup.postFactory;
		var uploads:Array<UploadLevelCall> = [];
		var results:Array<Dynamic> = [{success: false, status: "exists"}, {success: true}];
		UploadingLevelPopup.postFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			onResult(results.shift());
			return null;
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		editor.title = "Existing Title";
		new UploadingLevelPopup(editor);
		assertEquals(1, uploads.length, "existing-title response posts once before confirmation");
		assertEquals("0", uploads[0].fields.get("overwrite_existing"), "first upload does not overwrite existing level");
		var confirm = lastConfirmPopup();
		assertNotNull(confirm, "existing-title response opens overwrite confirmation");
		var text = LobbyArt.text(confirm, "textBox");
		assertEquals(true, text != null && text.htmlText.indexOf("overwrite the existing level") >= 0, "overwrite confirmation uses Flash copy");
		clickPopup(confirm, "ok_bt");

		assertEquals(2, uploads.length, "confirming overwrite retries upload");
		assertEquals("1", uploads[1].fields.get("overwrite_existing"), "retry posts overwrite confirmation flag");
		assertEquals("0", uploads[1].fields.get("override_banned"), "retry preserves ban override state");

		editor.remove();
		UploadingLevelPopup.postFactory = previousFactory;
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testUploadingLevelPopupBannedConfirmation():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.userName = "CaseUser";
		LobbySession.token = "session-token";
		ServerConfig.setHost("http://example.test");
		var previousFactory = UploadingLevelPopup.postFactory;
		var uploads:Array<UploadLevelCall> = [];
		var results:Array<Dynamic> = [{success: false, status: "banned", scope: "s", ban_id: 4321}, {success: true}];
		UploadingLevelPopup.postFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			onResult(results.shift());
			return null;
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		editor.title = "Banned Save";
		new UploadingLevelPopup(editor, false, true);
		assertEquals(1, uploads.length, "banned response posts once before confirmation");
		assertEquals("0", uploads[0].fields.get("override_banned"), "first upload does not override ban");
		assertEquals("1", uploads[0].fields.get("overwrite_existing"), "first upload preserves overwrite confirmation");
		var confirm = lastConfirmPopup();
		assertNotNull(confirm, "banned response opens override confirmation");
		var text = LobbyArt.text(confirm, "textBox");
		assertEquals(true, text != null && text.htmlText.indexOf("socially banned") >= 0, "ban confirmation includes scoped ban copy");
		assertEquals(true, text != null && text.htmlText.indexOf("bans/show_record.php?ban_id=4321") >= 0, "ban confirmation links the ban record");
		clickPopup(confirm, "ok_bt");

		assertEquals(2, uploads.length, "confirming ban override retries upload");
		assertEquals("1", uploads[1].fields.get("override_banned"), "retry posts ban override flag");
		assertEquals("1", uploads[1].fields.get("overwrite_existing"), "retry preserves overwrite confirmation");

		editor.remove();
		UploadingLevelPopup.postFactory = previousFactory;
		ServerConfig.resetHost();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testUploadingLevelPopupResultMessages():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.userName = "CaseUser";
		LobbySession.token = "session-token";
		var previousFactory = UploadingLevelPopup.postFactory;
		var results:Array<Dynamic> = [
			{success: true, message: "Level saved!"},
			{success: false, error: "That title is not allowed."}
		];
		UploadingLevelPopup.postFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			onResult(results.shift());
			return null;
		};

		var editor = new LevelEditor(null, true, false);
		editor.initialize();
		editor.title = "Result Messages";
		new UploadingLevelPopup(editor);
		var successMessage = lastMessagePopup();
		assertNotNull(successMessage, "successful save result opens server message");
		var successText = LobbyArt.text(successMessage, "textBox");
		assertEquals(true, successText != null && successText.htmlText.indexOf("Level saved!") >= 0, "successful save message uses server text");
		closeAllPopups();

		new UploadingLevelPopup(editor);
		var errorMessage = lastMessagePopup();
		assertNotNull(errorMessage, "failed save result opens error message");
		var errorText = LobbyArt.text(errorMessage, "textBox");
		assertEquals(true, errorText != null && errorText.htmlText.indexOf("Error: That title is not allowed.") >= 0, "failed save error uses server error text");

		editor.remove();
		UploadingLevelPopup.postFactory = previousFactory;
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testUploadingLevelPopupEmptyDataMessage():Void {
		closeAllPopups();
		LobbySession.clear();
		LobbySession.group = 1;
		LobbySession.userName = "CaseUser";
		LobbySession.token = "session-token";
		var previousFactory = UploadingLevelPopup.postFactory;
		var uploads = 0;
		UploadingLevelPopup.postFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):pr2.lobby.dialogs.UploadingPopup {
			uploads++;
			return null;
		};

		var editor = new EmptyDataLevelEditor();
		editor.initialize();
		new UploadingLevelPopup(editor);

		assertEquals(0, uploads, "empty serialized data does not upload");
		var message = lastMessagePopup();
		assertNotNull(message, "empty serialized data opens the Flash client-glitch message");
		var text = LobbyArt.text(message, "textBox");
		assertEquals(true, text != null && text.htmlText.indexOf("Could not save your level") >= 0,
			"empty data message uses Flash copy");

		editor.remove();
		UploadingLevelPopup.postFactory = previousFactory;
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testLevelEditorTestCourseTransition():Void {
		Settings.useMemoryStoreForTests();
		Settings.init("Editor Tester");
		Settings.setValue(Settings.LE_TEST_STATS, {speed: 61, acceleration: 72, jumping: 83});
		Settings.setValue(Settings.LE_TEST_HAT, 13);
		LobbySession.clear();
		LobbySession.group = 1;
		var holder = new PageHolder();
		var editor = new LevelEditor(null, true, true);
		holder.changePage(editor);
		editor.title = "Testable Level";
		editor.setSong("0");
		editor.setGravity("2");
		editor.setMaxTime("90");
		editor.setGameMode("deathmatch");
		editor.selectEditorTool("blocks", "brick");
		var brick = editor.placeSelectedBlockAt(100, 120);
		assertNotNull(brick, "test-course source editor places a block");
		editor.selectEditorTool("tools", "brush");
		assertEquals(true, editor.beginSelectedBrushAt(20, 30), "test-course gating setup starts a brush stroke");
		clickEditorMenu(editor, "testButton");
		assertEquals(editor, holder.getCurrentPage(), "test button ignores clicks while the editor is drawing");
		assertEquals(true, editor.endSelectedBrush(), "test-course gating setup finishes the brush stroke");
		var sourceData = editor.getLevelVars().get("data");

		LobbySocket.resetSent();
		clickEditorMenu(editor, "testButton");
		var testCourse = Std.downcast(holder.getCurrentPage(), TestCoursePage);
		assertNotNull(testCourse, "editor test button opens the test-course page");
		assertEquals(true, testCourse.isMod, "test course preserves editor mod flag");
		assertEquals(true, testCourse.reportsMode, "test course preserves reports mode");
		assertEquals(sourceData, testCourse.variables.get("data"), "test course receives serialized editor data");
		assertNotNull(testCourse.course, "test course mounts a playable Course");
		assertEquals(null, testCourse.course.raceChat, "test course omits the race chat UI");
		assertNotNull(DisplayUtil.findByName(testCourse.art, "back_bt"), "test course mounts authored back button");
		assertNotNull(DisplayUtil.findByName(testCourse.art, "restart_bt"), "test course mounts authored restart button");
		assertNotNull(testCourse.statsSelect, "test course mounts the StatsSelect control");
		assertNotNull(testCourse.hatPicker, "test course mounts the HatPicker control");
		assertEquals(testCourse.course, testCourse.art.parent, "test course graphic mounts inside the Course holder");
		assertEquals(testCourse.course, testCourse.statsSelect.parent, "test course stat picker mounts inside the Course holder");
		assertEquals(testCourse.course, testCourse.hatPicker.parent, "test course hat picker mounts inside the Course holder");
		assertEquals(10.0, testCourse.statsSelect.x, "test course stat picker x includes the Flash holder offset");
		assertEquals(290.0, testCourse.statsSelect.y, "test course stat picker y includes the Flash holder offset");
		assertEquals(0.66, testCourse.statsSelect.scaleX, "test course stat picker scale matches Flash");
		assertEquals(15.0, testCourse.hatPicker.x, "test course hat picker x includes the Flash holder offset");
		assertEquals(265.0, testCourse.hatPicker.y, "test course hat picker y includes the Flash holder offset");
		assertEquals(0.7, testCourse.hatPicker.scaleX, "test course hat picker scale matches Flash");
		assertEquals(145.0, testCourse.course.musicSelection.x, "test course music selector x includes the Flash holder offset");
		if (AppStage.stage != null) {
			AppStage.stage.focus = null;
			testCourse.dispatchEvent(new Event(Event.ENTER_FRAME));
			assertEquals(AppStage.stage, AppStage.stage.focus, "test course keeps stage focus every frame");
		}
		var initialStats = testCourse.course.localCharacter.debugState();
		assertEquals(61, Math.round(initialStats.speedStat), "test course applies saved speed stat");
		assertEquals(72, Math.round(initialStats.accelerationStat), "test course applies saved acceleration stat");
		assertEquals(83, Math.round(initialStats.jumpStat), "test course applies saved jump stat");
		assertEquals(13, testCourse.course.localCharacter.hat1, "test course applies saved test hat");
		assertEquals(true, LobbySocket.sentCommands.length > 0 && StringTools.startsWith(LobbySocket.sentCommands[0], "exact_pos`"),
			"test course starts the race countdown like Flash");

		var clickPoint = new Point(230, 240);
		var targetWorld = testCourse.course.levelRenderer.screenToWorld(clickPoint.x, clickPoint.y);
		testCourse.course.levelRenderer.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true, false, clickPoint.x, clickPoint.y));
		var teleportedStats = testCourse.course.localCharacter.debugState();
		var serverFixture = @:privateAccess testCourse.course.serverFixture;
		var expectedFixtureX = targetWorld.x - serverFixture.originTileX * 30;
		var expectedFixtureY = targetWorld.y - serverFixture.originTileY * 30;
		assertEquals(Math.round(expectedFixtureX), Math.round(teleportedStats.x), "test course click teleports local player to clicked x");
		assertEquals(Math.round(expectedFixtureY), Math.round(teleportedStats.y), "test course click teleports local player to clicked y");
		assertEquals(2, testCourse.course.levelRenderer.teleportPopCountForTests(), "test course click adds source and destination teleport pops");

		var firstCourse = testCourse.course;
		var firstStatsSelect = testCourse.statsSelect;
		var firstHatPicker = testCourse.hatPicker;
		DisplayUtil.findByName(testCourse.hatPicker, "right").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(15, testCourse.course.localCharacter.hat1, "hat picker skips artifact hat moving right");
		assertEquals(15, Settings.getValue(Settings.LE_TEST_HAT, 2), "hat picker persists the selected hat");
		testCourse.statsSelect.setStats(91, 82, 73);
		testCourse.statsSelect.noteUserStatChange();
		testCourse.statsSelect.saveLEStats();
		var changedStats = testCourse.course.localCharacter.debugState();
		assertEquals(91, Math.round(changedStats.speedStat), "stat picker updates live speed stat");
		assertEquals(82, Math.round(changedStats.accelerationStat), "stat picker updates live acceleration stat");
		assertEquals(73, Math.round(changedStats.jumpStat), "stat picker updates live jump stat");
		var statsSync = testCourse.course.onStatsSelectSyncRequest;
		assertEquals(true, statsSync != null, "test course wires block stat sync callback");
		testCourse.course.localCharacter.setStats(44, 55, 66);
		if (statsSync != null) {
			statsSync();
		}
		var syncedStats = testCourse.statsSelect.getStats();
		assertEquals(44, syncedStats.speed, "block stat sync updates StatsSelect speed from character");
		assertEquals(55, syncedStats.acceleration, "block stat sync updates StatsSelect acceleration from character");
		assertEquals(66, syncedStats.jumping, "block stat sync updates StatsSelect jumping from character");
		testCourse.course.setLife(1);
		@:privateAccess testCourse.course.localCharacter.controller.courseRotation = 90;
		@:privateAccess testCourse.course.localCharacter.controller.courseTweenRotation = 12;
		@:privateAccess testCourse.course.localCharacter.controller.courseTime = 12;
		testCourse.course.levelRenderer.setCourseRotation(90, 12);
		if (AppStage.stage != null) {
			AppStage.stage.focus = null;
		}
		DisplayUtil.findByName(testCourse.art, "restart_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(firstCourse, testCourse.course, "restart resets the existing test course like Flash");
		assertEquals(firstStatsSelect, testCourse.statsSelect, "restart keeps the existing StatsSelect control");
		assertEquals(firstHatPicker, testCourse.hatPicker, "restart keeps the existing HatPicker control");
		assertEquals(testCourse.course, firstStatsSelect.parent, "restart leaves StatsSelect on the Course holder");
		assertEquals(testCourse.course, firstHatPicker.parent, "restart leaves HatPicker on the Course holder");
		assertEquals(0, testCourse.course.levelRenderer.teleportPopCountForTests(), "restart clears teleport pop effects");
		var restartedStats = testCourse.course.localCharacter.debugState();
		assertEquals(0, restartedStats.courseRotation, "restart resets course rotation");
		assertEquals(90, restartedStats.courseTime, "restart resets the course timer to max time");
		assertEquals(3, restartedStats.lives, "restart resets deathmatch lives");
		assertEquals(91, Math.round(restartedStats.speedStat), "restart applies saved speed stat");
		assertEquals(82, Math.round(restartedStats.accelerationStat), "restart applies saved acceleration stat");
		assertEquals(73, Math.round(restartedStats.jumpStat), "restart applies saved jump stat");
		assertEquals(15, testCourse.course.localCharacter.hat1, "restart applies saved test hat");
		if (AppStage.stage != null) {
			assertEquals(AppStage.stage, AppStage.stage.focus, "restart restores stage focus");
		}

		DisplayUtil.findByName(testCourse.art, "back_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var returnedEditor = Std.downcast(holder.getCurrentPage(), LevelEditor);
		assertNotNull(returnedEditor, "back button returns to the level editor");
		assertEquals(true, returnedEditor.isMod, "returned editor preserves mod flag");
		assertEquals(true, returnedEditor.reportsMode, "returned editor preserves reports mode");
		assertEquals("Testable Level", returnedEditor.title, "returned editor restores level vars");
		assertEquals("2.0", returnedEditor.gravity, "returned editor restores normalized gravity");
		assertEquals(sourceData, returnedEditor.getLevelVars().get("data"), "returned editor re-stages serialized level data");
		assertNotNull(returnedEditor.blockLayer.getBlockAtSeg(brick.segX, brick.segY), "returned editor re-stages placed blocks");
		returnedEditor.remove();
		LobbySession.clear();
	}

	private static function testLevelEditorEggTestCourseSpawnsEggs():Void {
		Settings.useMemoryStoreForTests();
		Settings.init("Egg Tester");
		LobbySession.clear();
		LobbySession.group = 1;
		var holder = new PageHolder();
		var editor = new LevelEditor(null, true, false);
		holder.changePage(editor);
		editor.title = "Egg Test";
		editor.setGameMode("egg");

		clickEditorMenu(editor, "testButton");
		var testCourse = Std.downcast(holder.getCurrentPage(), TestCoursePage);
		assertNotNull(testCourse, "egg editor test button opens the test-course page");
		assertEquals(10, testCourse.course.eggRound.count(), "egg test course spawns Flash's initial ten eggs");
		var firstEgg = testCourse.course.eggRound.ids()[0];
		assertEquals(true, testCourse.course.eggRound.collectEgg(firstEgg), "egg test course can collect a spawned egg");
		assertEquals(11, testCourse.course.eggRound.count(), "egg test course adds one replacement egg on collect");
		var course = testCourse.course;

		DisplayUtil.findByName(testCourse.art, "back_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(null, course.parent, "egg test course back cleanup removes the Course display");
		assertEquals(null, course.eggRound, "egg test course back cleanup clears the egg round");
		var returnedEditor = Std.downcast(holder.getCurrentPage(), LevelEditor);
		assertNotNull(returnedEditor, "egg test course back returns to the editor");
		returnedEditor.remove();
		LobbySession.clear();
	}

	private static function testCourseMenuTiming():Void {
		// Flash CourseMenu.forceTime seeds (15 - timeRemaining) + 1, then ticks once;
		// the first value the player sees is therefore 15 - timeRemaining.
		assertEquals(16, CourseMenu.initialTimer(0), "full wait seeds 16");
		assertEquals(1, CourseMenu.initialTimer(15), "one second left seeds 1");
		assertEquals(6, CourseMenu.initialTimer(10), "ten seconds left seeds 6");
	}

	private static function testLevelLaunch():Void {
		// The selected slot is only entered after the matching server startGame.
		var captured:Null<String> = null;
		LevelLaunch.handler = function(levelId:Int, version:Int):Void {
			captured = levelId + ":" + version;
		};
		LevelLaunch.select(4271, 9);
		LevelLaunch.startGame(["9999"]);
		assertEquals(null, captured, "unrelated startGame is ignored");
		LevelLaunch.startGame(["4271"]);
		assertEquals("4271:9", captured, "matching startGame enters selected level");
		assertEquals("4271`9", LevelLaunch.lastLaunch, "accepted launch is recorded");
		LevelLaunch.startGame(["4271"]);
		assertEquals("4271:9", captured, "selection is consumed once");
		LevelLaunch.select(4271, 9);
		LevelLaunch.clear(4271, 9);
		captured = null;
		LevelLaunch.startGame(["4271"]);
		assertEquals(null, captured, "cleared slot cannot enter a game");
		LevelLaunch.handler = null;
	}

	private static function testLevelLaunchTargetsRootHolder():Void {
		// Regression: every PageHolder used to claim the startGame launch in its
		// constructor, so the lobby's nested holders (PlayersTab's inner list
		// holder, LobbySide) stole the target and the game mounted inside an
		// offset lobby panel. Only the stage-root holder may host the game.
		var root = new pr2.page.PageHolder(null, true);
		assertEquals(true, LevelLaunch.launchHolder() == root, "root holder claims the launch target");
		var nestedA = new pr2.page.PageHolder();
		var nestedB = new pr2.page.PageHolder();
		assertEquals(true, nestedA != null && nestedB != null, "nested holders construct");
		assertEquals(true, LevelLaunch.launchHolder() == root, "nested holders do not steal the launch target");
	}

	private static function testTabLayoutNoCompression():Void {
		// Row narrower than the pane: tabs stay at their cumulative offsets.
		var xs = TabLayout.positions([40, 50, 30], 200);
		assertEquals(0.0, xs[0], "first tab x");
		assertEquals(40.0, xs[1], "second tab x");
		assertEquals(90.0, xs[2], "third tab x");
	}

	private static function testTabLayoutCompression():Void {
		// total = 120, maxW = 90 -> overflow 30 split across (n-1)=2 => tabW = 15.
		// tab[1] -= 15*1, tab[2] -= 15*2.
		var xs = TabLayout.positions([40, 40, 40], 90);
		assertEquals(0.0, xs[0], "compressed first x");
		assertEquals(25.0, xs[1], "compressed second x");
		assertEquals(50.0, xs[2], "compressed third x");
	}

	private static function testTabLayoutSingleTab():Void {
		// One tab wider than the pane must not divide by zero.
		var xs = TabLayout.positions([300], 100);
		assertEquals(1, xs.length, "single tab count");
		assertEquals(0.0, xs[0], "single tab x");
	}

	private static function testTabMemory():Void {
		TabsHolder.clearMemory();
		// No memory yet: falls back to the supplied default.
		assertEquals(2, TabsHolder.resolveSelected("lobbyLeft", 2, 4), "default selected");
		TabsHolder.setLastTab("lobbyLeft", 1);
		assertEquals(1, TabsHolder.resolveSelected("lobbyLeft", 2, 4), "remembered selected");
		// Remembered index out of range for a smaller tab set falls back.
		assertEquals(0, TabsHolder.resolveSelected("lobbyLeft", 0, 1), "stale memory ignored");
		TabsHolder.clearMemory();
	}

	private static function testScrollBarMapping():Void {
		// Thumb spans [20, 120]; target overflow = 400 - 300 = 100 px.
		// At the top the target sits at its initial y; at the bottom it scrolls up
		// by the full overflow.
		assertEquals(0.0, CustomScrollBar.thumbToTargetY(20, 20, 120, 0, 400, 300), "thumb top -> initial");
		assertEquals(-100.0, CustomScrollBar.thumbToTargetY(120, 20, 120, 0, 400, 300), "thumb bottom -> full scroll");
		assertEquals(-50.0, CustomScrollBar.thumbToTargetY(70, 20, 120, 0, 400, 300), "thumb middle -> half scroll");
		// Out-of-range thumb is clamped; target never scrolls below initial.
		assertEquals(0.0, CustomScrollBar.thumbToTargetY(-50, 20, 120, 0, 400, 300), "above top clamps to initial");
		assertEquals(-100.0, CustomScrollBar.thumbToTargetY(999, 20, 120, 0, 400, 300), "below bottom clamps to full");
	}

	private static function testPageNavigationPositions():Void {
		// Three 40px buttons across a 90px strip overlap exactly like the tab strip.
		var xs = PageNavigation.buttonPositions([40, 40, 40], 90);
		assertEquals(0.0, xs[0], "page button first x");
		assertEquals(25.0, xs[1], "page button second x");
		assertEquals(50.0, xs[2], "page button third x");
		// Fewer/narrower buttons than the strip spread apart (negative startingPos).
		var spread = PageNavigation.buttonPositions([20, 20], 100);
		assertEquals(0.0, spread[0], "spread first x");
		assertEquals(80.0, spread[1], "spread second x");
	}

	private static function testPlayerSortStateMachine():Void {
		// A numeric header sorts descending first; re-clicking it toggles to asc.
		var state = PlayerListSort.nextSort({mode: "rank", order: "desc"}, "rank", "userName");
		assertEquals("rank", state.mode, "re-click keeps mode");
		assertEquals("asc", state.order, "re-click toggles order");
		// Switching to another numeric header resets to descending.
		state = PlayerListSort.nextSort(state, "hats", "userName");
		assertEquals("hats", state.mode, "switch column");
		assertEquals("desc", state.order, "new numeric column is desc");
		// The name header sorts ascending.
		state = PlayerListSort.nextSort(state, "userName", "userName");
		assertEquals("userName", state.mode, "name column");
		assertEquals("asc", state.order, "name column is asc");
		// Re-clicking the name header toggles to descending.
		state = PlayerListSort.nextSort(state, "userName", "userName");
		assertEquals("desc", state.order, "name re-click toggles");
		// Tiebreak columns pair up as in the originals.
		assertEquals("hats", PlayerListSort.tiebreak("rank"), "rank tiebreak");
		assertEquals("activeMembers", PlayerListSort.tiebreak("gpToday"), "gp tiebreak");
	}

	private static function testPlayerSortOrdering():Void {
		// Descending rank, with hats as the tiebreak and name as the final tiebreak.
		var rows:Array<SortableRow> = [
			new TestRow("alice", 5, 2),
			new TestRow("bob", 9, 1),
			new TestRow("carol", 5, 7),
			new TestRow("dave", 5, 2)
		];
		PlayerListSort.apply(rows, {mode: "rank", order: "desc"}, "userName");
		assertEquals("bob", rows[0].sortName(), "highest rank first");
		assertEquals("carol", rows[1].sortName(), "rank tie broken by hats");
		assertEquals("alice", rows[2].sortName(), "remaining tie broken by name");
		assertEquals("dave", rows[3].sortName(), "name order after alice");
		// Ascending name sort.
		PlayerListSort.apply(rows, {mode: "userName", order: "asc"}, "userName");
		assertEquals("alice", rows[0].sortName(), "name asc first");
		assertEquals("dave", rows[3].sortName(), "name asc last");
	}

	private static function testPlayersTabListSortsOnInterval():Void {
		var list = new PlayersTabList();
		list.initialize();
		@:privateAccess list.addUserEntry("alice", "1", 5, 2);
		@:privateAccess list.addUserEntry("bob", "1", 9, 1);
		@:privateAccess list.addUserEntry("carol", "1", 5, 7);
		assertEquals("alice,bob,carol", @:privateAccess list.listingSortNamesForTests().join(","),
			"new player rows keep insertion order before interval sort");
		assertEquals(true, @:privateAccess list.updateSort, "new player rows mark pending sort");
		@:privateAccess list.sortListener();
		assertEquals("bob,carol,alice", @:privateAccess list.listingSortNamesForTests().join(","),
			"interval sort applies current rank sort");
		assertEquals(false, @:privateAccess list.updateSort, "interval sort clears pending flag");
		list.remove();
	}

	private static function testPlayerAndGuildListsIgnoreLateLoadsAfterRemove():Void {
		var previousUserFetch = PlayersUserListLoader.fetchFactory;
		var previousGuildFetch = Guilds.fetchFactory;
		var userSuccess:Null<String->Void> = null;
		var guildSuccess:Null<String->Void> = null;
		var userResource = new FakeAsyncListResource();
		var guildResource = new FakeAsyncListResource();
		PlayersUserListLoader.fetchFactory = function(url:String, onData:String->Void, onError:String->Void) {
			userSuccess = onData;
			return userResource;
		};
		Guilds.fetchFactory = function(url:String, onData:String->Void, onError:String->Void) {
			guildSuccess = onData;
			return guildResource;
		};

		var users = new PlayersUserListLoader("friends");
		users.initialize();
		users.remove();
		userSuccess('{"users":[{"name":"Late","group":"1","rank":50,"hats":4,"status":"online"}]}');
		assertEquals(1, userResource.removes, "removed user list cancels tracked loader");
		assertEquals("", @:privateAccess users.listingSortNamesForTests().join(","), "removed user list ignores late user response");

		var guilds = new Guilds();
		guilds.initialize();
		guilds.remove();
		guildSuccess('{"guilds":[{"guild_name":"Late Guild","guild_id":7,"active_count":3,"gp_today":99}]}');
		assertEquals(1, guildResource.removes, "removed guild list cancels tracked loader");
		assertEquals("", @:privateAccess guilds.listingSortNamesForTests().join(","), "removed guild list ignores late guild response");

		PlayersUserListLoader.fetchFactory = previousUserFetch;
		Guilds.fetchFactory = previousGuildFetch;
	}

	private static function testPaneTabLabels():Void {
		// Members see PMs (left) and Favorites (right); guests don't.
		var leftMember = LobbyLeft.tabLabels(2);
		assertEquals(4, leftMember.length, "member left tab count");
		assertEquals("PMs", leftMember[1], "member left has PMs");
		var leftGuest = LobbyLeft.tabLabels(0);
		assertEquals(3, leftGuest.length, "guest left tab count");
		assertEquals("Players", leftGuest[1], "guest left drops PMs");

		var rightMember = LobbyRight.tabLabels(1);
		assertEquals(6, rightMember.length, "member right tab count");
		assertEquals("♥", rightMember[5], "member right has favorites");
		var rightGuest = LobbyRight.tabLabels(0);
		assertEquals(5, rightGuest.length, "guest right tab count");
		assertEquals("Campaign", rightGuest[0], "right defaults to campaign");
	}

	private static function testLevelListParsing():Void {
		pr2.lobby.tabs.ListingTab.resetHooksForTests();
		// Campaign page formula `((server_id + day) % 6) + 1`, 1..6.
		assertEquals(1, pr2.net.LevelListClient.campaignPage(0, 0), "campaign page base");
		assertEquals(3, pr2.net.LevelListClient.campaignPage(5, 3), "campaign page wraps within 6");
		assertEquals(6, pr2.net.LevelListClient.campaignPage(2, 3), "campaign page upper");
		LobbySession.clear();
		LobbySession.lastAuthTime.setTime(172800);
		assertEquals(2, pr2.lobby.tabs.ListingTab.currentServerDayForTests(), "campaign day comes from login auth time");
		LobbySession.server = new ServerInfo("127.0.0.1", 9160, 5, "Campaign Server", "open", 0, 0, false);
		var campaign = new pr2.lobby.tabs.ListingTab("campaign");
		assertEquals(2, campaign.getPageNum(), "campaign initial page uses session server id and auth day");
		assertEquals(2, LobbySocket.campaignPage, "campaign socket cache tracks selected campaign page");
		LobbySession.clear();

		var freshLevels = [new CampaignLevelInfo(11, 1, "Fresh Campaign", "Tester", 0, 4, 10)];
		var freshCalls = 0;
		var freshSuccess:Null<pr2.net.LevelListClient.LevelListResult->Void> = null;
		pr2.lobby.tabs.ListingTab.fetchFactory = function(mode:String, page:Int, onResult:pr2.net.LevelListClient.LevelListResult->Void,
				onError:String->Void) {
			freshCalls++;
			assertEquals("campaign", mode, "fresh campaign fetch mode");
			assertEquals(2, page, "fresh campaign fetch page");
			freshSuccess = onResult;
			return new FakeAsyncListResource();
		};
		LobbySession.lastAuthTime.setTime(172800);
		LobbySession.server = new ServerInfo("127.0.0.1", 9160, 5, "Campaign Server", "open", 0, 0, false);
		Memory.clear();
		campaign = new pr2.lobby.tabs.ListingTab("campaign");
		campaign.initialize();
		var nav = campaign.pageNavigationForTests();
		assertEquals(6, nav.pageCountForTests(), "campaign uses six-page vertical navigation");
		assertEquals(328, Std.int(nav.x), "campaign page navigation x");
		assertEquals(26, Std.int(nav.y), "campaign page navigation y");
		assertEquals(1, freshCalls, "uncached campaign fetches once");
		freshSuccess(new pr2.net.LevelListClient.LevelListResult(freshLevels, true));
		assertEquals(freshLevels, Memory.get("campaignInfo2"), "fresh campaign response is cached by page");
		assertEquals(1, campaign.levelItemCountForTests(), "fresh campaign response renders immediately");
		campaign.remove();

		var cachedLevels = [new CampaignLevelInfo(12, 1, "Cached Campaign", "Tester", 0, 5, 20)];
		var cachedCalls = 0;
		pr2.lobby.tabs.ListingTab.fetchFactory = function(mode:String, page:Int, onResult:pr2.net.LevelListClient.LevelListResult->Void,
				onError:String->Void) {
			cachedCalls++;
			return new FakeAsyncListResource();
		};
		Memory.clear();
		Memory.set("campaignInfo2", cachedLevels);
		campaign = new pr2.lobby.tabs.ListingTab("campaign");
		campaign.initialize();
		assertEquals(0, cachedCalls, "cached campaign info avoids a network request");
		assertEquals(0, campaign.levelItemCountForTests(), "cached campaign info waits before showing courses");
		@:privateAccess campaign.onCampaignRenderTimer();
		assertEquals(1, campaign.levelItemCountForTests(), "cached campaign info renders after delayed show");
		campaign.remove();
		pr2.lobby.tabs.ListingTab.resetHooksForTests();
		LobbySession.clear();

		var delayedLevels = [new CampaignLevelInfo(13, 1, "Delayed Rank", "Tester", 0, 5, 30)];
		var delayedSuccess:Null<pr2.net.LevelListClient.LevelListResult->Void> = null;
		pr2.lobby.tabs.ListingTab.fetchFactory = function(mode:String, page:Int, onResult:pr2.net.LevelListClient.LevelListResult->Void,
				onError:String->Void) {
			assertEquals("best", mode, "rank-delayed listing fetch mode");
			assertEquals(1, page, "rank-delayed listing fetch page");
			delayedSuccess = onResult;
			return new FakeAsyncListResource();
		};
		Memory.clear();
		SecureData.setNumber("userRank", -1);
		var delayed = new pr2.lobby.tabs.ListingTab("best");
		delayed.initialize();
		delayedSuccess(new pr2.net.LevelListClient.LevelListResult(delayedLevels, true));
		assertEquals(0, delayed.levelItemCountForTests(), "level listing waits while SecureData userRank is negative");
		SecureData.setNumber("userRank", 3);
		@:privateAccess delayed.onShowCoursesTimer();
		assertEquals(1, delayed.levelItemCountForTests(), "level listing shows courses after delayed rank check passes");
		delayed.remove();
		pr2.lobby.tabs.ListingTab.resetHooksForTests();
		SecureData.clear();

		var lifecycleLevels = [new CampaignLevelInfo(14, 1, "Lifecycle", "Other", 10, 5, 40)];
		var lifecycleSuccess:Null<pr2.net.LevelListClient.LevelListResult->Void> = null;
		pr2.lobby.tabs.ListingTab.fetchFactory = function(mode:String, page:Int, onResult:pr2.net.LevelListClient.LevelListResult->Void,
				onError:String->Void) {
			assertEquals("best", mode, "lifecycle listing fetch mode");
			assertEquals(4, page, "lifecycle listing fetch page");
			lifecycleSuccess = onResult;
			return new FakeAsyncListResource();
		};
		Memory.clear();
		Memory.set("coursePageNumbest", 4);
		SecureData.setNumber("userRank", 3);
		LobbySession.clear();
		LobbySession.begin("Player", 1);
		LevelListingState.currentPageNum = 99;
		CourseMenu.instance = null;
		var launched = false;
		LevelLaunch.handler = function(levelId:Int, version:Int):Void {
			launched = true;
		};
		var lifecycle = new pr2.lobby.tabs.ListingTab("best");
		lifecycle.initialize();
		assertEquals(4, LevelListingState.currentPageNum, "listing seeds global page before slots can fill");
		lifecycleSuccess(new pr2.net.LevelListClient.LevelListResult(lifecycleLevels, true));
		var lifecycleItem = lifecycle.levelItemForTests(0);
		assertNotNull(lifecycleItem, "lifecycle listing rendered a level item");
		assertEquals(true, lifecycleItem.coverShownForTests(), "rank-gated item shows access cover before cleanup");
		LobbySocket.resetSent();
		lifecycleItem.sendFillSlot(2);
		assertEquals("fill_slot`14_1`2`4", LobbySocket.lastSent(), "slot fill uses initialized listing page");
		CommandHandler.commandHandler.dispatch("fillSlot14_1", ["0", "Player", "3", "me"]);
		assertEquals(true, CourseMenu.instance != null, "local slot fill opens a course menu");
		lifecycle.remove();
		assertEquals(null, CourseMenu.instance, "listing cleanup removes local course menu");
		assertEquals("clear_slot`", LobbySocket.lastSent(), "listing cleanup clears the server slot");
		assertEquals(0, lifecycleItem.slotCountForTests(), "listing cleanup removes item slots");
		assertEquals(false, lifecycleItem.coverShownForTests(), "listing cleanup detaches access cover state");
		LevelLaunch.startGame(["14"]);
		assertEquals(false, launched, "listing cleanup clears selected level launch");
		LevelLaunch.handler = null;
		pr2.lobby.tabs.ListingTab.resetHooksForTests();
		SecureData.clear();
		LobbySession.clear();

		// Parsing pulls the levels array; an arbitrary body has an invalid hash.
		var body = '{"hash":"zzz","levels":[{"level_id":"7","title":"Alpha","user_name":"Jo"},{"level_id":"8","title":"Beta","user_name":"Al"}]}';
		var result = pr2.net.LevelListClient.parse(body);
		assertEquals(2, result.levels.length, "parsed level count");
		assertEquals(7, result.levels[0].levelId, "first level id");
		assertEquals("Beta", result.levels[1].title, "second level title");
		assertEquals(false, result.hashValid, "arbitrary hash is invalid");

		var hoverInfo = new CampaignLevelInfo(15, 12345, "Title <One>", "User & Co", 7, 4.5, 1234567, "0",
			"Line 1\nLine <2>", false, "r", null, 1609502400);
		assertEquals("-- Title &lt;One&gt; --", pr2.lobby.level.LevelItem.infoHoverTitleForTests(hoverInfo), "level item hover title escapes HTML");
		assertEquals("By: User &amp; Co<br/>"
			+ "Version: 12,345<br/>"
			+ "Updated: " + Data.getShortDateStr(1609502400) + "<br/>"
			+ "Min Rank: 7<br/>"
			+ "Plays: 1,234,567<br/>"
			+ "Rating: 4.5<br/>"
			+ "-----<br/><i>Line 1\nLine &lt;2&gt;</i><br/>"
			+ "-----<br/>(click the \"?\" for more info)", pr2.lobby.level.LevelItem.infoHoverBodyForTests(hoverInfo),
			"level item hover body matches Flash formatting");
	}

	private static function testLevelItemFavoriteFlow():Void {
		pr2.lobby.level.LevelItem.resetHooksForTests();
		closeAllPopups();
		LobbySession.clear();
		LobbySession.begin("Player", 1);
		LobbySession.favoriteLevels = [];

		var hoverCallback:Null<Void->Void> = null;
		var hoverDelay = 0;
		pr2.lobby.level.LevelItem.favoriteHoverDelayFactory = function(callback:Void->Void, delayMs:Int):Null<haxe.Timer> {
			hoverCallback = callback;
			hoverDelay = delayMs;
			return null;
		};

		var upload = new FakeFavoriteUploadingPopup();
		var uploadCalls = 0;
		var uploadResult:Null<Dynamic->Void> = null;
		pr2.lobby.level.LevelItem.favoriteUploadFactory = function(url:String, fields:Map<String, String>, label:String,
				onResult:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploadCalls++;
			assertEquals(ServerConfig.favoriteModifyUrl(), url, "favorite upload endpoint");
			assertEquals("add", fields.get("mode"), "favorite add upload mode");
			assertEquals("16", fields.get("level_id"), "favorite upload level id");
			assertEquals("Adding to favorites...", label, "favorite add upload label");
			uploadResult = onResult;
			return upload;
		};

		var item = new pr2.lobby.level.LevelItem(new CampaignLevelInfo(16, 1, "Favorite", "Other", 0, 5, 0));
		assertEquals("Add to Favorites", pr2.lobby.level.LevelItem.favoriteHoverTitleForTests("add"), "favorite add hover title");
		assertEquals("Add this level to your favorites list.", pr2.lobby.level.LevelItem.favoriteHoverMessageForTests("add"),
			"favorite add hover message");
		assertEquals("Remove from Favorites", pr2.lobby.level.LevelItem.favoriteHoverTitleForTests("remove"), "favorite remove hover title");
		assertEquals("Remove this level from your favorites list.", pr2.lobby.level.LevelItem.favoriteHoverMessageForTests("remove"),
			"favorite remove hover message");

		@:privateAccess item.overFavorite();
		assertEquals(500, hoverDelay, "favorite hover waits 500ms");
		assertEquals(false, item.favoriteHoverVisibleForTests(), "favorite hover is delayed");
		hoverCallback();
		assertEquals(true, item.favoriteHoverVisibleForTests(), "favorite hover shows after delay callback");
		@:privateAccess item.outFavorite();
		assertEquals(false, item.favoriteHoverVisibleForTests(), "favorite hover clears on mouse out");

		@:privateAccess item.clickFavorite("add");
		assertEquals(1, uploadCalls, "favorite add starts one upload");
		assertEquals(true, item.uploadingForTests() == upload, "favorite add tracks pending upload");
		@:privateAccess item.clickFavorite("add");
		assertEquals(1, uploadCalls, "favorite click is ignored while upload is pending");
		uploadResult({mode: "add"});
		assertEquals("16", LobbySession.favoriteLevels.join(","), "favorite add result updates session favorites");
		assertEquals(1, upload.fadeOuts, "favorite add result fades upload popup");

		var removeUpload = new FakeFavoriteUploadingPopup();
		var removeResult:Null<Dynamic->Void> = null;
		pr2.lobby.level.LevelItem.favoriteUploadFactory = function(url:String, fields:Map<String, String>, label:String,
				onResult:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			assertEquals("remove", fields.get("mode"), "favorite remove upload mode");
			assertEquals("Removing from favorites...", label, "favorite remove upload label");
			removeResult = onResult;
			return removeUpload;
		};
		@:privateAccess item.clickFavorite("remove");
		removeResult({mode: "remove"});
		assertEquals("", LobbySession.favoriteLevels.join(","), "favorite remove result updates session favorites");
		assertEquals(1, removeUpload.fadeOuts, "favorite remove result fades upload popup");

		var pendingUpload = new FakeFavoriteUploadingPopup();
		pr2.lobby.level.LevelItem.favoriteUploadFactory = function(url:String, fields:Map<String, String>, label:String,
				onResult:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			return pendingUpload;
		};
		@:privateAccess item.clickFavorite("add");
		item.remove();
		assertEquals(1, pendingUpload.removes, "favorite item cleanup removes pending upload popup");

		pr2.lobby.level.LevelItem.resetHooksForTests();
		LobbySession.clear();
		closeAllPopups();
	}

	private static function testLevelItemPasswordFlow():Void {
		pr2.lobby.level.LevelItem.resetHooksForTests();
		LobbySession.clear();
		LobbySession.begin("Player", 1);
		SecureData.setNumber("userRank", 50);
		var postCalls = 0;
		var passSuccess:Null<String->Void> = null;
		var passError:Null<String->Void> = null;
		pr2.lobby.level.LevelItem.passPostFactory = function(url:String, fields:Map<String, String>, onResult:String->Void,
				onError:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable {
			postCalls++;
			assertEquals(ServerConfig.levelPassCheckUrl(), url, "level pass check endpoint");
			assertEquals("17", fields.get("course_id"), "level pass check course id");
			assertEquals(Md5.encode("secret" + ServerConfig.LEVEL_PASS_SALT), fields.get("hash"), "level pass check hash");
			passSuccess = onResult;
			passError = onError;
			return new FakeAsyncListResource();
		};

		var item = new pr2.lobby.level.LevelItem(new CampaignLevelInfo(17, 1, "Password", "Other", 0, 5, 0, "0", "", true));
		item.setPassTextForTests("secret");
		assertEquals(true, item.passButtonEnabledForTests(), "pass button starts enabled");
		assertEquals(true, item.passBoxEnabledForTests(), "pass input starts enabled");
		@:privateAccess item.clickPassEnter();
		assertEquals(1, postCalls, "pass click sends one request");
		assertEquals(true, item.passPendingForTests(), "pass request stays pending");
		assertEquals("checking...", item.passTextForTests(), "pass input shows checking while pending");
		assertEquals(false, item.passButtonEnabledForTests(), "pass button disables while pending");
		assertEquals(false, item.passBoxEnabledForTests(), "pass input disables while pending");
		@:privateAccess item.clickPassEnter();
		assertEquals(1, postCalls, "pass click is ignored while pending");
		passError("network");
		assertEquals(false, item.passPendingForTests(), "pass error clears pending state");
		assertEquals("", item.passTextForTests(), "pass error clears checking text");
		assertEquals(true, item.passButtonEnabledForTests(), "pass error re-enables button");
		assertEquals(true, item.passBoxEnabledForTests(), "pass error re-enables input");

		item.setPassTextForTests("secret");
		@:privateAccess item.clickPassEnter();
		passSuccess('{"success":false}');
		assertEquals(false, item.passPendingForTests(), "bad pass response clears pending state");
		assertEquals("nope!", item.passTextForTests(), "bad pass response shows nope");
		assertEquals(true, item.passButtonEnabledForTests(), "bad pass response re-enables button");
		assertEquals(true, item.passBoxEnabledForTests(), "bad pass response re-enables input");
		item.remove();
		pr2.lobby.level.LevelItem.resetHooksForTests();
		SecureData.clear();
		LobbySession.clear();
	}

	private static function testSearchFocusQuirks():Void {
		Memory.clear();
		var focusResets = 0;
		StageFocus.resetHook = function():Void {
			focusResets++;
		};
		var search = new pr2.lobby.tabs.SearchTab();
		search.initialize();
		@:privateAccess search.modeCb.dispatchEvent(new Event(Event.CLOSE));
		assertEquals(1, focusResets, "search mode combo close returns focus to stage");
		@:privateAccess search.orderCb.dispatchEvent(new Event(Event.CLOSE));
		assertEquals(2, focusResets, "search order combo close returns focus to stage");
		@:privateAccess search.dirCb.dispatchEvent(new Event(Event.CLOSE));
		assertEquals(3, focusResets, "search direction combo close returns focus to stage");
		@:privateAccess search.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.SPACE));
		assertEquals(3, focusResets, "search non-enter key does not reset focus");
		@:privateAccess search.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ENTER));
		assertEquals(4, focusResets, "search Enter key returns focus to stage");
		search.remove();
		StageFocus.resetHooks();
		Memory.clear();
	}

	private static function testSearchRequestQuirks():Void {
		pr2.lobby.tabs.SearchTab.resetHooksForTests();
		Memory.clear();
		var searchCalls:Array<Map<String, String>> = [];
		pr2.lobby.tabs.SearchTab.searchFactory = function(params:Map<String, String>, onResult:pr2.net.LevelListClient.LevelListResult->Void,
				onError:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable {
			searchCalls.push(params);
			return new FakeAsyncListResource();
		};

		var blank = new pr2.lobby.tabs.SearchTab();
		blank.initialize();
		assertEquals(0, searchCalls.length, "blank search sends no request");
		assertEquals(false, blank.loadingVisibleForTests(), "blank search does not show loading");
		blank.remove();

		Memory.clear();
		Memory.set("coursePageNumsearch", 3);
		var idSearch = new pr2.lobby.tabs.SearchTab("123", "id");
		idSearch.initialize();
		assertEquals(1, searchCalls.length, "id search initialized past page 1 sends only reset request");
		assertEquals("1", searchCalls[0].get("page"), "id search reset request uses page 1");
		assertEquals("id", searchCalls[0].get("mode"), "id search reset request keeps id mode");
		assertEquals("123", searchCalls[0].get("search_str"), "id search reset request keeps query");
		assertEquals(1, idSearch.getPageNum(), "id search initialized past page 1 resets displayed page");
		assertEquals(1, Memory.getInt("coursePageNumsearch"), "id search reset persists page 1");
		assertEquals(true, idSearch.loadingVisibleForTests(), "id search shows loading for the sent page 1 request");
		idSearch.remove();

		pr2.lobby.tabs.SearchTab.resetHooksForTests();
		Memory.clear();
	}

	private static function testSearchPendingShowsLoadingGraphic():Void {
		pr2.lobby.tabs.SearchTab.resetHooksForTests();
		Memory.clear();
		pr2.lobby.tabs.SearchTab.searchFactory = function(params:Map<String, String>, onResult:pr2.net.LevelListClient.LevelListResult->Void,
				onError:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable {
			return new FakeAsyncListResource();
		};

		var search = new pr2.lobby.tabs.SearchTab("pending", "user");
		search.initialize();
		var loading = search.loadingGraphicForTests();
		assertEquals(true, search.loadingVisibleForTests(), "pending search shows loading");
		assertNotNull(loading, "pending search creates loading graphic");
		assertEquals(true, loading.numChildren > 0, "loading graphic renders child art");
		assertNotNull(findTextDescendant(loading, "Loading"), "loading graphic renders Loading text");
		search.remove();
		pr2.lobby.tabs.SearchTab.resetHooksForTests();
		Memory.clear();
	}

	private static function testSearchResultsStartBelowControls():Void {
		pr2.lobby.tabs.SearchTab.resetHooksForTests();
		Memory.clear();
		SecureData.setNumber("userRank", 3);
		pr2.lobby.tabs.SearchTab.searchFactory = function(params:Map<String, String>, onResult:pr2.net.LevelListClient.LevelListResult->Void,
				onError:String->Void):pr2.util.AsyncRemovalGuard.AsyncRemovable {
			onResult(new pr2.net.LevelListClient.LevelListResult([new CampaignLevelInfo(18, 1, "Search Result", "Other", 0, 5, 0)], true));
			return new FakeAsyncListResource();
		};

		var search = new pr2.lobby.tabs.SearchTab("search terms", "user");
		search.initialize();
		var item = search.levelItemForTests(0);
		assertNotNull(item, "search renders returned level");
		assertEquals(true, item.y >= 90, "search result starts below the search controls");
		search.remove();
		pr2.lobby.tabs.SearchTab.resetHooksForTests();
		SecureData.clear();
		Memory.clear();
	}

	private static function testSearchQuery():Void {
		// Blank query sends nothing.
		assertEquals(Std.string(SearchDecision.Skip), Std.string(SearchQuery.decide("   ", "user", 1, true)), "blank query skipped");
		// A normal query on any page sends.
		assertEquals(Std.string(SearchDecision.Send), Std.string(SearchQuery.decide("mario", "user", 3, false)), "user query sends");
		// Id search past page 1 snaps to page 1 on first run, then is ignored.
		assertEquals(Std.string(SearchDecision.ResetToFirstPage), Std.string(SearchQuery.decide("1234", "id", 4, true)), "id page>1 first run resets");
		assertEquals(Std.string(SearchDecision.Skip), Std.string(SearchQuery.decide("1234", "id", 4, false)), "id page>1 later skipped");
		assertEquals(Std.string(SearchDecision.Send), Std.string(SearchQuery.decide("1234", "id", 1, false)), "id page 1 sends");
		// POST params carry the inputs.
		var vars = SearchQuery.buildPost("mario", "user", "rating", "desc", 2);
		assertEquals("mario", vars.get("search_str"), "post search_str");
		assertEquals("user", vars.get("mode"), "post mode");
		assertEquals("rating", vars.get("order"), "post order");
		assertEquals("desc", vars.get("dir"), "post dir");
		assertEquals("2", vars.get("page"), "post page");
	}

	private static function testLevelAccess():Void {
		var noHats:Array<Int> = [];
		// Open level, sufficient rank: playable.
		assertEquals("Open", accessName(LevelAccess.evaluate(false, false, 1, false, 5, 3, -1, noHats)), "open level");
		// Password level not yet entered: pass cover (members below mod).
		assertEquals("PassNeeded", accessName(LevelAccess.evaluate(true, false, 1, false, 9, 0, -1, noHats)), "pass needed");
		// Owner bypasses the password.
		assertEquals("Open", accessName(LevelAccess.evaluate(true, false, 1, true, 9, 0, -1, noHats)), "owner bypasses pass");
		// Moderators (group>=2) bypass the password.
		assertEquals("Open", accessName(LevelAccess.evaluate(true, false, 2, false, 9, 0, -1, noHats)), "mod bypasses pass");
		// Rank too low: rank cover with the min rank.
		assertEquals("RankNeeded", accessName(LevelAccess.evaluate(false, false, 1, false, 2, 10, -1, noHats)), "rank gate");
		assertEquals("Rank 10 Needed", LevelAccess.coverText(LevelAccess.evaluate(false, false, 1, false, 2, 10, -1, noHats)), "rank cover text");
		// Disallowed hat applies even to the owner.
		assertEquals("HatNotAllowed", accessName(LevelAccess.evaluate(false, false, 1, true, 5, 0, 7, [7, 9])), "hat gate");
		assertEquals("HatNotAllowed", accessName(LevelAccess.evaluate(false, false, 2, false, 5, 0, 7, [7])), "mod still hat-gated");
	}

	private static function testLevelPassResponse():Void {
		var encrypted = pr2.crypto.PR2Encryptor.encryptBase64(
			"\u0000{\"level_id\":42,\"access\":1}\u0000",
			ServerConfig.LEVEL_PASS_KEY,
			ServerConfig.LEVEL_PASS_IV
		);
		var body = haxe.Json.stringify({success: true, result: encrypted});
		assertEquals(true, pr2.lobby.level.LevelItem.parsePasswordResponse(body, 42), "encrypted pass response grants matching level");
		assertEquals(false, pr2.lobby.level.LevelItem.parsePasswordResponse(body, 43), "encrypted pass response rejects other level");

		var denied = pr2.crypto.PR2Encryptor.encryptBase64(
			"{\"level_id\":42,\"access\":0}",
			ServerConfig.LEVEL_PASS_KEY,
			ServerConfig.LEVEL_PASS_IV
		);
		assertEquals(false, pr2.lobby.level.LevelItem.parsePasswordResponse(haxe.Json.stringify({success: true, result: denied}), 42), "encrypted pass response rejects access 0");
		assertEquals(false, pr2.lobby.level.LevelItem.parsePasswordResponse(haxe.Json.stringify({success: false, result: encrypted}), 42), "failed pass response rejects");
	}

	private static function accessName(state:LevelAccessState):String {
		return switch (state) {
			case Open: "Open";
			case PassNeeded: "PassNeeded";
			case RankNeeded(_): "RankNeeded";
			case HatNotAllowed: "HatNotAllowed";
		}
	}

	private static function testLevelGridLayout():Void {
		// Seven levels from y=0 fill three columns then start a second/third row.
		var positions = LevelGridLayout.positions(7, 0);
		assertEquals(7, positions.length, "all seven placed at y=0 start");
		assertEquals(2.0, positions[0].x, "col0 x");
		assertEquals(111.0, positions[1].x, "col1 x");
		assertEquals(220.0, positions[2].x, "col2 x");
		assertEquals(0.0, positions[2].y, "row0 y");
		assertEquals(112.0, positions[3].y, "row1 y");
		assertEquals(224.0, positions[6].y, "row2 y at the limit");
		// A non-zero start height pushes rows past 224 and the phantom row is cut.
		var shifted = LevelGridLayout.positions(9, 20);
		assertEquals(6, shifted.length, "rows past 224 are dropped");
	}

	private static function testLevelInfoParsing():Void {
		var data = {
			level_id: "42",
			version: "3",
			title: "Castle",
			user_name: "Jo",
			user_group: "1,1",
			min_level: "5",
			rating: "4.5",
			play_count: "1200",
			note: "fun",
			pass: "1",
			type: "d",
			bad_hats: "0,1,7,9",
			time: "1600000000"
		};
		var info = CampaignLevelInfo.fromDynamic(data);
		assertEquals(42, info.levelId, "level id");
		assertEquals(true, info.pass, "pass flag");
		assertEquals("d", info.type, "type code");
		assertEquals(2, info.badHats.length, "bad hats keep ids > 1");
		assertEquals(7, info.badHats[0], "first bad hat");
		assertEquals(9, info.badHats[1], "second bad hat");
	}

	private static function testSessionGuestMember():Void {
		LobbySession.clear();
		assertEquals(true, LobbySession.isGuest(), "fresh session is guest");
		assertEquals(false, LobbySession.isMember(), "guest is not member");
		LobbySession.begin("Jiggmin", 3, null, 1, true);
		assertEquals(true, LobbySession.isMember(), "logged-in is member");
		assertEquals("Jiggmin", LobbySession.userName, "user name set");
		assertEquals(true, LobbySession.remember, "remember flag set");
		var fired = 0;
		var listener = function():Void {
			fired++;
		};
		LobbySession.onAccountChange(listener);
		LobbySession.notifyAccountChange();
		assertEquals(1, fired, "account change fired");
		LobbySession.clear();
	}

	private static function testSocketRecording():Void {
		LobbySocket.resetSent();
		LobbySocket.write("set_chat_room`main");
		LobbySocket.write("set_right_room`none");
		assertEquals(2, LobbySocket.sentCommands.length, "two commands recorded");
		assertEquals("set_right_room`none", LobbySocket.lastSent(), "last command");
		LobbySocket.resetSent();
		assertEquals(0, LobbySocket.sentCommands.length, "reset clears recorder");
	}

	private static function testCommandDispatch():Void {
		var handler = new CommandHandler();
		var captured:Array<String> = null;
		handler.defineCommand("setChatRoomList", function(args):Void {
			captured = args;
		});
		// Server layout: hash`num`command`arg1`arg2`
		var handled = handler.handleServerFrame(CommandHandler.buildServerFrame(5, "setChatRoomList", ["main", "speed"]));
		assertEquals(true, handled, "frame handled");
		assertEquals("main", captured[0], "first arg parsed");
		assertEquals("speed", captured[1], "second arg parsed");
		assertEquals(false, handler.handleServerFrame(CommandHandler.buildServerFrame(5, "setChatRoomList", ["replay"])), "replayed send number rejected");
		assertEquals(false, handler.handleServerFrame("bad`6`setChatRoomList`hash`"), "bad hash rejected");
		handler.defineCommand("setChatRoomList", null);
		assertEquals(false, handler.handleServerFrame(CommandHandler.buildServerFrame(7, "setChatRoomList", ["x"])), "cleared command ignored");

		handler.defineCommand("buffered", function(args):Void {
			captured = args;
		});
		var first = CommandHandler.buildServerFrame(8, "buffered", ["one"]);
		var second = CommandHandler.buildServerFrame(9, "buffered", ["two"]);
		assertEquals(0, handler.addText(first.substr(0, 5)), "partial frame waits for EOL");
		assertEquals(2, handler.addText(first.substr(5) + CommandHandler.END_CHAR + second + CommandHandler.END_CHAR), "buffer handles two EOL frames");
		assertEquals("two", captured[0], "second buffered arg parsed");

		SecureData.clear();
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(10, "setRank", ["37"])), "default setRank handled");
		assertEquals(37.0, SecureData.getNumber("userRank"), "setRank updates secure rank");
		handler.clearAll();
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(11, "setRank", ["38"])), "default setRank survives clearAll");
		assertEquals(38.0, SecureData.getNumber("userRank"), "setRank remains global");

		LobbySession.clear();
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(12, "setGroup", ["2"])), "setGroup handled");
		assertEquals(2, LobbySession.group, "setGroup updates session group");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(13, "becomeSpecialUser", [])), "special user handled");
		assertEquals(true, LobbySession.isSpecialUser, "special user flag set");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(14, "becomePrizer", [])), "prizer handled");
		assertEquals(true, LobbySession.isPrizer, "prizer flag set");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(15, "demotePrizer", [])), "demote prizer handled");
		assertEquals(false, LobbySession.isPrizer, "prizer flag cleared");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(16, "becomeTempMod", [])), "temp mod handled");
		assertEquals(true, LobbySession.isTempMod, "temp mod flag set");
		assertEquals(false, LobbySession.isTrialMod, "temp mod clears trial flag");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(17, "becomeTrialMod", [])), "trial mod handled");
		assertEquals(false, LobbySession.isTempMod, "trial mod clears temp flag");
		assertEquals(true, LobbySession.isTrialMod, "trial mod flag set");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(18, "becomeFullMod", [])), "full mod handled");
		assertEquals(2, LobbySession.group, "full mod group");
		assertEquals(false, LobbySession.isTrialMod, "full mod clears trial flag");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(19, "demoteMod", [])), "demote mod handled");
		assertEquals(1, LobbySession.group, "demote mod group");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(20, "tournamentMode", ["1"])), "tournament handled");
		assertEquals(true, LobbySession.tournamentMode, "tournament flag set");
		var accountChanges = 0;
		LobbySession.onAccountChange(function():Void accountChanges++);
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(21, "guildChange", ['{"guild_id":9,"guild_name":"Racers","is_owner":true}'])), "guildChange handled");
		assertEquals(9, LobbySession.guildId, "guild id updated");
		assertEquals("Racers", LobbySession.guildName, "guild name updated");
		assertEquals(true, LobbySession.guildOwner, "guild owner updated");
		assertEquals(1, accountChanges, "guild change fires account change");
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(22, "setServerOwner", ["42"])), "server owner handled");
		assertEquals(42, LobbySession.serverOwner, "server owner updated");
		pr2.lobby.account.AccountState.currentHat = -1;
		var levelAccessChecks = 0;
		handler.defineCommand("testLevelAccess", function(_):Void levelAccessChecks++);
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(23, "wearingHat", ["7"])), "wearingHat handled");
		assertEquals(7, pr2.lobby.account.AccountState.currentHat, "wearingHat updates current hat");
		assertEquals(1, levelAccessChecks, "wearingHat dispatches level access check");
		UnreadNotif.reset();
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(24, "pmNotify", ["100"])), "pmNotify handled");
		assertEquals(1, UnreadNotif.numUnread(), "pmNotify records unread message");
		LobbySocket.resetSent();
		LobbySocket.sendNum = 2;
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(25, "resend", ["3"])), "resend handled");
		assertEquals(1, LobbySocket.closeCount, "resend closes stale socket");
	}

	private static function testMemoryAndSecureData():Void {
		Memory.clear();
		assertEquals(7, Memory.getInt("coursePageNum1", 7), "memory default int");
		Memory.set("coursePageNum1", 3);
		assertEquals(3, Memory.getInt("coursePageNum1", 7), "memory stored int");
		SecureData.clear();
		assertEquals(0.0, SecureData.getNumber("userRank"), "secure default");
		SecureData.setNumber("userRank", 5);
		assertEquals(5.0, SecureData.getNumber("userRank"), "secure stored");
		SecureData.setNumber("zeroRank", 0);
		assertEquals(0.0, SecureData.getNumber("zeroRank", 7), "secure stored zero overrides fallback");
	}

	private static function testPmNotificationLifecycle():Void {
		UnreadNotif.reset();
		CommandHandler.commandHandler.clearAll();
		LobbySession.clear();
		LobbySession.group = 1;
		var left = new LobbyLeft();
		assertNotNull(UnreadNotif.containerForTests(), "member left pane attaches PM unread container");
		CommandHandler.commandHandler.dispatch("pmNotify", ["250"]);
		assertEquals(1, UnreadNotif.numUnread(), "member left pane pmNotify records unread PM");
		assertEquals(true, UnreadNotif.hasNotificationForTests(), "member left pane displays unread PM badge");
		left.remove();
		assertEquals(null, UnreadNotif.containerForTests(), "left pane removal detaches PM unread container");
		assertEquals(false, UnreadNotif.hasNotificationForTests(), "left pane removal removes unread PM badge");

		CommandHandler.commandHandler.dispatch("pmNotify", ["300"]);
		assertEquals(2, UnreadNotif.numUnread(), "pmNotify falls back to global handler after left pane removal");
		assertEquals(false, UnreadNotif.hasNotificationForTests(), "pmNotify after left pane removal has no stale badge parent");

		UnreadNotif.reset();
		LobbySession.clear();
		LobbySession.group = 0;
		left = new LobbyLeft();
		assertEquals(null, UnreadNotif.containerForTests(), "guest left pane does not attach PM unread container");
		left.remove();
		CommandHandler.commandHandler.clearAll();
		UnreadNotif.reset();
	}

	private static function testLobbySidePanelDimensions():Void {
		LobbySession.clear();
		LobbySession.group = 1;
		var left = new LobbyLeft();
		var leftBg = left.getChildAt(0);
		assertEquals(194, Math.round(leftBg.width), "left lobby panel renders background width");
		assertEquals(379, Math.round(leftBg.height), "left lobby panel renders background height");
		left.remove();

		var right = new LobbyRight();
		var rightBg = right.getChildAt(0);
		assertEquals(347, Math.round(rightBg.width), "right lobby panel renders background width");
		assertEquals(341, Math.round(rightBg.height), "right lobby panel renders background height");
		right.remove();
		LobbySession.clear();
	}

	private static function testLoginServerActivationLifecycle():Void {
		var previousFetchFactory = ServerStatusClient.fetchFactory;
		var fetches:Array<{onResult:ServerStatusResult->Void, onError:Null<String->Void>}> = [];
		ServerStatusClient.fetchFactory = function(onResult:ServerStatusResult->Void, onError:Null<String->Void>):Void {
			fetches.push({onResult: onResult, onError: onError});
		};

		var page = new LoginPage();
		page.initialize();
		assertEquals(1, fetches.length, "login server activation immediately fetches server status");
		Reflect.callMethod(page, Reflect.field(page, "onServerRefreshTimer"), [new TimerEvent(TimerEvent.TIMER)]);
		assertEquals(2, fetches.length, "login server activation reloads from timer handler");
		page.remove();
		fetches[1].onResult(new ServerStatusResult([serverInfo(0)]));
		var servers:Array<ServerInfo> = Reflect.field(page, "servers");
		assertEquals(0, servers.length, "login server removal cancels late server status response");

		ServerStatusClient.fetchFactory = previousFetchFactory;
	}

	private static function testCheckServersComboPrompts():Void {
		var previousFetchFactory = ServerStatusClient.fetchFactory;
		var fetches:Array<{onResult:ServerStatusResult->Void, onError:Null<String->Void>}> = [];
		ServerStatusClient.fetchFactory = function(onResult:ServerStatusResult->Void, onError:Null<String->Void>):Void {
			fetches.push({onResult: onResult, onError: onError});
		};
		var page = new LoginPage();
		page.initialize();
		Reflect.callMethod(page, Reflect.field(page, "openCredentialDialog"), []);
		var popup:Dynamic = Reflect.field(page, "activePopup");
		var combo = Std.downcast(DisplayUtil.findByName(popup, "dropdown"), FlComboBox);
		assertNotNull(combo, "login credential popup has server dropdown");
		Reflect.callMethod(page, Reflect.field(page, "loadServers"), []);
		assertEquals("Loading...", combo.prompt, "server dropdown shows loading prompt during reload");
		assertEquals(false, combo.enabled, "server dropdown is disabled while loading");
		fetches[fetches.length - 1].onResult(new ServerStatusResult([]));
		assertEquals("No servers found. :(", combo.prompt, "server dropdown shows no-servers prompt for empty result");
		assertEquals(false, combo.enabled, "server dropdown remains disabled for empty result");
		page.remove();
		ServerStatusClient.fetchFactory = previousFetchFactory;
	}

	private static function testCheckServersGuildSelectionRules():Void {
		var previousFetchFactory = ServerStatusClient.fetchFactory;
		var fetches:Array<{onResult:ServerStatusResult->Void, onError:Null<String->Void>}> = [];
		ServerStatusClient.fetchFactory = function(onResult:ServerStatusResult->Void, onError:Null<String->Void>):Void {
			fetches.push({onResult: onResult, onError: onError});
		};
		LobbySession.clear();
		LobbySession.guildId = 42;
		var page = new LoginPage();
		page.initialize();
		Reflect.callMethod(page, Reflect.field(page, "openCredentialDialog"), []);
		fetches[0].onResult(new ServerStatusResult([
			server(2, 9002, 0, 25, "open", "Public"),
			server(7, 9007, 9, 80, "open", "Other Guild"),
			server(6, 9006, 42, 10, "open", "Own Guild")
		]));
		var popup:Dynamic = Reflect.field(page, "activePopup");
		var combo = Std.downcast(DisplayUtil.findByName(popup, "dropdown"), FlComboBox);
		assertEquals(3, combo.length, "guild selection keeps public and private servers");
		var first:Dynamic = combo.dataProvider.getItemAt(0);
		assertEquals("* Own Guild (10 online)", Reflect.field(first, "label"), "own guild server is sorted first");
		var selected:ServerInfo = Reflect.field(combo.selectedItem, "server");
		assertEquals(6, selected.serverId, "own open guild server is selected by default");
		page.remove();
		LobbySession.clear();
		ServerStatusClient.fetchFactory = previousFetchFactory;
	}

	private static function testLoggingInPayloadAndResetTokenFlow():Void {
		var previousLoginFactory = LoginAuthClient.loginFactory;
		var capturedToken:Null<String> = null;
		var capturedAwardKong = false;
		var capturedLoginId = 0;
		var capturedRemember = false;
		LoginAuthClient.loginFactory = function(userName:String, userPass:String, server:ServerInfo, remember:Bool, loginId:Int,
				onResult:LoginAuthResult->Void, onError:Null<String->Void>, token:Null<String>, awardKong:Bool):Void {
			capturedToken = token;
			capturedAwardKong = awardKong;
			capturedLoginId = loginId;
			capturedRemember = remember;
			onResult(new LoginAuthResult(false, "expired token", {resetToken: true}));
		};
		SavedAccounts.disablePersistenceForTests();
		SavedAccounts.add("Alice", "expired-token");
		KongAward.nextLogin = true;
		LobbySession.begin("Stale", 1, serverInfo(0));
		UnreadNotif.setLastRead(0);
		UnreadNotif.notifyUser(99);
		var page = new LoginPage();
		Reflect.setField(page, "loginToken", "expired-token");
		Reflect.callMethod(page, Reflect.field(page, "openLoggingInPopup"), ["1234", "Alice", "", true, serverInfo(0)]);

		assertEquals("expired-token", capturedToken, "remembered login sends saved token");
		assertEquals(true, capturedAwardKong, "logging in payload consumes pending Kong award");
		assertEquals(false, KongAward.nextLogin, "Kong award flag resets after login send");
		assertEquals(1234, capturedLoginId, "logging in payload parses login id");
		assertEquals(true, capturedRemember, "remembered login forwards remember flag");
		assertEquals(0, SavedAccounts.getAll().length, "resetToken login error deletes remembered token");
		assertEquals(0, LobbySession.group, "login error clears stale session group");
		assertEquals("Guest", LobbySession.userName, "login error clears stale session user");
		assertEquals(0, UnreadNotif.numUnread(), "login error clears unread notifications");
		page.remove();
		LoginAuthClient.loginFactory = previousLoginFactory;
		KongAward.nextLogin = false;
	}

	private static function testLoginPageAppliesPostLoginState():Void {
		SavedAccounts.disablePersistenceForTests();
		LobbySession.clear();
		UnreadNotif.reset();
		Settings.clear();
		Presets.resetForTests();
		var page = new LoginPage();
		Reflect.setField(page, "loginServer", serverInfo(42));
		Reflect.setField(page, "loginRemember", true);
		var session = new LoginSessionResult(2, "Player", {
			userId: 77,
			email: 1,
			token: "fresh-token",
			guild: 42,
			guildOwner: true,
			guildName: "Racers",
			emblem: "racing.png",
			favoriteLevels: ([3, "7"] : Array<Dynamic>),
			time: 12345,
			lastRead: 100,
			lastRecv: 150
		});
		Reflect.callMethod(page, Reflect.field(page, "enterLobby"), [session]);

		assertEquals("Player", LobbySession.userName, "post-login stores socket user name");
		assertEquals(2, LobbySession.group, "post-login stores socket group");
		assertEquals(77, LobbySession.userId, "post-login stores user id");
		assertEquals(true, LobbySession.hasEmail, "post-login stores email flag");
		assertEquals("fresh-token", LobbySession.token, "post-login stores token");
		assertEquals(42, LobbySession.guildId, "post-login stores guild id");
		assertEquals(true, LobbySession.guildOwner, "post-login stores guild owner");
		assertEquals("Racers", LobbySession.guildName, "post-login stores guild name");
		assertEquals("racing.png", LobbySession.emblem, "post-login stores emblem");
		assertEquals("3,7", LobbySession.favoriteLevels.join(","), "post-login stores favorite levels");
		assertEquals(true, Math.abs(LobbySession.lastAuthTime.getTimestamp() - 12345) < 5, "post-login applies server auth time");
		assertEquals(1, UnreadNotif.numUnread(), "post-login applies unread notification state");
		assertEquals(true, Settings.isNameSet(), "post-login initializes per-user settings");
		assertEquals(true, Presets.loadedForTests(), "post-login loads presets after settings");
		assertEquals("fresh-token", SavedAccounts.getByName("Player").token, "remembered login stores fresh token");
		page.remove();
		LobbySession.clear();
		UnreadNotif.reset();
		Settings.clear();
		Presets.resetForTests();
	}

	private static function closeAllPopups():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function serverInfo(guildId:Int):ServerInfo {
		return new ServerInfo("127.0.0.1", 9160, 1, "Test Server", "open", 0, guildId, false);
	}

	private static function server(id:Int, port:Int, guildId:Int, population:Int, status:String, name:String):ServerInfo {
		return new ServerInfo("127.0.0.1", port, id, name, status, population, guildId, false);
	}

	private static function mapSize(map:Map<String, String>):Int {
		var count = 0;
		for (_ in map.keys()) count++;
		return count;
	}

	private static function lastConfirmPopup():ConfirmPopup {
		for (i in 0...Popup.getOpen().length) {
			var popup = Popup.getOpen()[Popup.getOpen().length - 1 - i];
			var confirm = Std.downcast(popup, ConfirmPopup);
			if (confirm != null) {
				return confirm;
			}
		}
		return null;
	}

	private static function lastMessagePopup():pr2.lobby.dialogs.MessagePopup {
		for (i in 0...Popup.getOpen().length) {
			var popup = Popup.getOpen()[Popup.getOpen().length - 1 - i];
			var message = Std.downcast(popup, pr2.lobby.dialogs.MessagePopup);
			if (message != null) {
				return message;
			}
		}
		return null;
	}

	private static function clickPopup(popup:Popup, buttonName:String):Void {
		var button = Std.downcast(DisplayUtil.findByName(popup, buttonName), InteractiveObject);
		button.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function signedLevel(levelData:String, levelId:Int, version:Int):String {
		return levelData + Md5.encode(Std.string(version) + Std.string(levelId) + levelData + ServerConfig.LEVEL_SALT_2);
	}

	private static function findTextDescendant(container:DisplayObjectContainer, text:String):Null<TextField> {
		for (i in 0...container.numChildren) {
			var child = container.getChildAt(i);
			var field = Std.downcast(child, TextField);
			if (field != null && field.text.indexOf(text) >= 0) {
				return field;
			}
			var nested = Std.downcast(child, DisplayObjectContainer);
			if (nested != null) {
				var found = findTextDescendant(nested, text);
				if (found != null) {
					return found;
				}
			}
		}
		return null;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertNear(expected:Int, actual:Int, tolerance:Int, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) {
			throw '$message: expected $expected +/- $tolerance, got $actual';
		}
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw message;
		}
	}
}

private typedef UploadLevelCall = {
	var url:String;
	var fields:Map<String, String>;
	var label:String;
}

private class EmptyDataLevelEditor extends LevelEditor {
	public function new() {
		super(null, true, false);
	}

	override public function getLevelVars():Map<String, String> {
		var vars = super.getLevelVars();
		vars.set("data", "");
		return vars;
	}
}

/** Minimal `SortableRow` for exercising the players/guilds sort comparator. */
private class TestRow implements SortableRow {
	private var name:String;
	private var rank:Int;
	private var hats:Int;

	public function new(name:String, rank:Int, hats:Int) {
		this.name = name;
		this.rank = rank;
		this.hats = hats;
	}

	public function numericField(key:String):Float {
		return key == "rank" ? rank : (key == "hats" ? hats : 0);
	}

	public function sortName():String {
		return name;
	}
}

private class FakeAsyncListResource {
	public var removes:Int = 0;

	public function new() {}

	public function remove():Void {
		removes++;
	}
}

private class FakeFavoriteUploadingPopup extends pr2.lobby.dialogs.UploadingPopup {
	public var removes:Int = 0;
	public var fadeOuts:Int = 0;

	public function new() {
		super(null);
	}

	override public function startFadeOut():Void {
		fadeOuts++;
	}

	override public function remove():Void {
		removes++;
		super.remove();
	}
}

private class TestPage extends Page {
	public var id(default, null):String;

	public function new(id:String) {
		super();
		this.id = id;
	}
}
