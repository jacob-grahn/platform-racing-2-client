package pr2.lobby;

import haxe.crypto.Md5;
import openfl.display.InteractiveObject;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;
import pr2.lobby.LobbyLeft;
import pr2.lobby.LobbyRight;
import pr2.lobby.players.PlayerListSort;
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
import pr2.lobby.messages.MessagesPaging;
import pr2.lobby.messages.UnreadNotif;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelDataClient;
import pr2.net.ServerConfig;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.Popup;
import pr2.page.EditorBlockOptions;
import pr2.page.LobbyPage;
import pr2.page.LevelEditor;
import pr2.page.LevelEditor.ChooseLevelsModePopup;
import pr2.page.LevelEditor.DeletingLevelPopup;
import pr2.page.LevelEditor.GetLevelsPopup;
import pr2.page.LevelEditor.GetReportedLevelsPopupItem;
import pr2.page.LevelEditor.HandleLevelReportPopup;
import pr2.page.LevelEditor.GetReportedLevelsPopup;
import pr2.page.LevelEditor.LoadingLevelPopup;
import pr2.page.LevelEditor.SaveLevelPopup;
import pr2.page.LevelEditor.UploadingLevelPopup;
import pr2.page.LevelEditor.TestCoursePage;
import pr2.page.Page;
import pr2.page.PageHolder;
import pr2.lobby.account.Settings;
import pr2.lobby.account.StatSlider;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlComboBox;
import pr2.ui.CustomScrollBar;
import pr2.ui.PageNavigation;
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
		testPaneTabLabels();
		testLevelListParsing();
		testSearchQuery();
		testLevelAccess();
		testLevelPassResponse();
		testLevelGridLayout();
		testLevelInfoParsing();
		testSessionGuestMember();
		testSocketRecording();
		testCommandDispatch();
		testMemoryAndSecureData();
		testLevelEditorRoute();
		testLevelEditorShell();
		testLevelEditorLoadListPopup();
		testLevelEditorLoadingLevelPopup();
		testLevelEditorReportedLevelsPopup();
		testLevelEditorReportHandlePopup();
		testLevelEditorDeleteFlow();
		testLevelEditorSaveDialog();
		testUploadingLevelPopupFields();
		testUploadingLevelPopupDrawingRetryWait();
		testUploadingLevelPopupOverwriteConfirmation();
		testUploadingLevelPopupBannedConfirmation();
		testUploadingLevelPopupResultMessages();
		testUploadingLevelPopupEmptyDataMessage();
		testLevelEditorTestCourseTransition();
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
		var launchedAsMod:Null<Bool> = null;
		LobbyPage.createLevelEditorPage = function(isMod:Bool):Page {
			launchedAsMod = isMod;
			return new TestPage("level-editor");
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
		page = new LobbyPage();
		page.pageHolder = holder;
		Reflect.callMethod(page, Reflect.field(page, "clickLevelEditor"), []);
		assertEquals(false, launchedAsMod, "temporary moderators enter editor without mod privileges");

		LobbyPage.createLevelEditorPage = previousFactory;
		LobbySession.clear();
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
		assertEquals(0.5, @:privateAccess editor.layerContainer.scaleX, "editor world scales horizontally with zoom");
		assertEquals(0.5, @:privateAccess editor.layerContainer.scaleY, "editor world scales vertically with zoom");
		var zoomedPoint = editor.blockLayer.globalToLocal(new Point(100, 120));
		assertEquals(200, Std.int(zoomedPoint.x), "zoom changes editor stage-to-world x conversion");
		assertEquals(240, Std.int(zoomedPoint.y), "zoom changes editor stage-to-world y conversion");
		zoomSelect.selectedIndex = 3;
		zoomSelect.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(1, editor.zoom, "editor zoom returns to 100% before placement tests");
		@:privateAccess editor.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.RIGHT));
		@:privateAccess editor.keyScroll(new Event(Event.ENTER_FRAME));
		@:privateAccess editor.onKeyUp(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, Keyboard.RIGHT));
		assertEquals(-275.0, editor.posX, "editor keyboard scroll clamps against Flash right edge");
		assertEquals(-200.0, editor.posY, "editor keyboard scroll clamps against Flash bottom edge");
		assertEquals(-275.0, editor.blockLayer.x, "block layer follows clamped camera x");
		assertEquals(-200.0, editor.blockLayer.y, "block layer follows clamped camera y");
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
		assertEquals("blocks", editor.menu.sideBar.id, "editor menu starts on blocks sidebar");
		assertEquals(editor.menu, editor.menu.sideBar.parent, "active sidebar is mounted above menu art");
		clickEditorSidebar(editor, "brickEntry");
		assertEquals("blocks", editor.selectedToolSidebar, "sidebar click records selected tool sidebar");
		assertEquals("brick", editor.selectedToolId, "sidebar click records selected tool id");
		clickEditorMenu(editor, "settingsButton");
		assertEquals("settings", editor.menu.sideBar.id, "settings button switches sidebar");
		assertEquals(null, editor.menu.blocks.parent, "old sidebar is removed when switching");
		assertEquals("", editor.selectedToolId, "switching sidebars clears stale selected tool");
		clickEditorMenu(editor, "bgButton");
		assertEquals("backgrounds", editor.menu.sideBar.id, "background button switches sidebar");
		clickEditorMenu(editor, "layer1Button");
		assertEquals("stamps", editor.menu.sideBar.id, "layer buttons switch to stamps sidebar");
		assertEquals(1, editor.activeObjectLayer.layerNum, "layer 1 selects the matching object layer");
		clickEditorSidebar(editor, "brushEntry");
		assertEquals("tools", editor.menu.sideBar.id, "stamp brush entry switches to draw tools");
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
		editor.closeBrushSizeMenu();
		var brushColorEntry = editor.menu.sideBar.getChildByName("colorEntry");
		Reflect.callMethod(brushColorEntry, Reflect.field(brushColorEntry, "setPickedColor"), [0x336699]);
		assertEquals(0x336699, editor.brushColor, "brush color picker commits the selected brush color");
		assertEquals(true, editor.beginSelectedBrushAt(30, 40), "brush still starts after size/color changes");
		assertEquals(true, editor.continueSelectedBrushAt(35, 47), "customized brush extends while drawing");
		assertEquals(true, editor.endSelectedBrush(), "customized brush stroke finishes");
		assertEquals("d10;12;5;6,c336699,t12,d30;40;5;7", editor.activeDrawLayer.getSaveString(),
			"brush size and color controls record Flash draw actions before the stroke");
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
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0", editor.activeObjectLayer.getActionString(), "text placement records Flash add/change actions");
		label.beginDragAt(100, 120);
		label.endDragAt(100, 120);
		assertEquals(true, label.isEditing(), "clicking existing text reopens editing");
		label.setEditingText("edited text");
		label.setColor(0x336699);
		label.finishEditing();
		assertEquals("edited text", label.text, "re-editing commits the updated text");
		assertEquals(0x336699, label.color, "text color edit commits the selected color");
		assertEquals("u;95;104;0;100;100,y0;hello#44 world#59 #351;0,y0;edited text;3368601", editor.activeObjectLayer.getActionString(),
			"text re-edit records a Flash change action with color");
		label.beginDragAt(100, 120);
		assertEquals(0.75, label.alpha, "text drag fades the moved object like Flash");
		label.dragTo(117.4, 146.6);
		label.endDragAt(117.4, 146.6);
		assertEquals(1, label.alpha, "text drag restores alpha on release");
		var resizeHandle = label.getChildByName("resizeHandle");
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
		assertEquals("cffffff,t12,merase,d200;240;10;0", editor.activeDrawLayer.getSaveString(),
			"eraser stores selected size, erase color, mode, and scaled stroke coordinates");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "undoButton"), "enabled"), "draw stroke enables undo");
		clickEditorMenu(editor, "undoButton");
		assertEquals("", editor.activeDrawLayer.getSaveString(), "draw undo removes the last stroke and setup actions");
		assertEquals(0, editor.activeDrawLayer.drawActions.length, "draw undo rebuilds decoded actions");
		assertEquals(0, editor.activeDrawLayer.rasterCanvas.numChildren, "draw undo clears rasterized art");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "redoButton"), "enabled"), "draw undo enables redo");
		clickEditorMenu(editor, "redoButton");
		assertEquals("cffffff,t12,merase,d200;240;10;0", editor.activeDrawLayer.getSaveString(), "draw redo restores the stroke group");
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
		var brickBlock = editor.placeSelectedBlockAt(100, 120);
		assertEquals(104, brickBlock.code, "placing over an editable block replaces it");
		assertEquals(5, editor.blockLayer.blocks.length, "replacement keeps the four start blocks plus new block");
		assertEquals(null, itemBlock.parent, "replaced block is unmounted");
		assertEquals(null, brickBlock.getChildByName("optionsButton"), "plain selected blocks do not show options");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "undoButton"), "enabled"), "block replacement enables undo");
		clickEditorMenu(editor, "undoButton");
		var restoredItemBlock = editor.blockLayer.getBlockAtSeg(3, 4);
		assertNotNull(restoredItemBlock, "block undo restores the replaced item block");
		assertEquals(110, restoredItemBlock.code, "block undo restores the replaced block code");
		assertEquals("none", restoredItemBlock.options, "block undo restores the replaced block options");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "redoButton"), "enabled"), "block undo enables redo");
		clickEditorMenu(editor, "redoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(3, 4);
		assertNotNull(brickBlock, "block redo restores the replacement block");
		assertEquals(104, brickBlock.code, "block redo restores the replacement block code");
		brickBlock.setOptions("legacy");
		assertEquals("444;335;11,1;0;12,1;0;13,1;0;14,-444;-331;4;legacy", editor.blockLayer.getSaveString(),
			"block save string uses Flash relative grid coordinates and option suffixes");
		clickEditorMenu(editor, "undoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(3, 4);
		assertEquals("", brickBlock.options, "block undo reverts option changes");
		clickEditorMenu(editor, "redoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(3, 4);
		assertEquals("legacy", brickBlock.options, "block redo restores option changes");
		clickEditorSidebar(editor, "deleteEntry");
		assertEquals("delete", editor.selectedToolId, "blocks delete entry selects the delete tool");
		brickBlock.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(4, editor.blockLayer.blocks.length, "blocks delete tool removes the target block");
		assertEquals(null, brickBlock.parent, "deleted block is unmounted");
		assertEquals(null, editor.selectedBlock, "deleted selected block clears selection");
		assertEquals("444;335;11,1;0;12,1;0;13,1;0;14", editor.blockLayer.getSaveString(),
			"block save string updates after deleting a placed block");
		clickEditorMenu(editor, "undoButton");
		brickBlock = editor.blockLayer.getBlockAtSeg(3, 4);
		assertNotNull(brickBlock, "block undo restores deleted blocks");
		assertEquals("legacy", brickBlock.options, "block undo restores deleted block options");
		clickEditorMenu(editor, "redoButton");
		assertEquals(null, editor.blockLayer.getBlockAtSeg(3, 4), "block redo reapplies deletion");
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
		teleportBlock.getChildByName("optionsButton").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertNotNull(editor.activeBlockOptionsPopup, "teleport block opens the teleport option popup");
		assertNotNull(DisplayUtil.findByName(editor.activeBlockOptionsPopup, "colorPicker"), "teleport popup mounts the color picker");
		Reflect.callMethod(editor.activeBlockOptionsPopup, Reflect.field(editor.activeBlockOptionsPopup, "setTeleportColor"), [0x00FF00]);
		editor.closeBlockOptionsPopup();
		assertEquals("65280", teleportBlock.options, "closing the teleport popup commits normalized color options");
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
		editor = new LevelEditor(null, true, false);
		editor.initialize();
		assertEquals(true, editor.isMod, "editor shell stores permanent mod flag");
		assertEquals(false, editor.reportsMode, "editor shell starts outside reports mode");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "saveButton"), "enabled"), "members can save");
		assertEquals(true, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "loadButton"), "enabled"), "members can load");
		editor.menu.setReportsMode(true);
		assertEquals(false, Reflect.getProperty(DisplayUtil.findByName(editor.menu.art, "saveButton"), "enabled"), "reports mode disables save");
		assertEquals(true, editor.reportsMode, "menu reports mode updates editor");
		editor.remove();
		LobbySession.clear();
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
					{level_id: "7", version: "3", title: "Alpha", live: "1", type: "r", play_count: "12", rating: "4.5", note: "note"},
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
		assertEquals("Alpha", LobbyArt.text(popup.listings[0].art, "titleBox").text, "listing renders title");
		assertEquals("Published", LobbyArt.text(popup.listings[0].art, "statusBox").text, "listing renders published state");
		assertEquals(1, popup.listings[0].art.currentFrame, "load listing row starts on the authored up frame");
		popup.listings[0].art.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, popup.listings[0].art.currentFrame, "load listing row does not auto-play through button states");

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
		assertEquals("7:3", loaded, "loading a listing hands off id and version");
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
						version: "6",
						title: "Reported One",
						creator: "Maker",
						report_time: "1363478400",
						reporter: "Concerned",
						reason: "Bad art",
						note: "check this"
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
		assertEquals("Reported One", LobbyArt.text(popup.listings[0].art, "titleBox").text, "reported listing renders title");
		assertEquals("16/Mar/2013", LobbyArt.text(popup.listings[0].art, "timeBox").text, "reported listing renders report date");

		popup.selectListing(popup.listings[0]);
		DisplayUtil.findByName(popup.art, "load_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals("51:6", loaded, "reported listing load hands off id and version");
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
		Settings.disablePersistenceForTests();
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
		var sourceData = editor.getLevelVars().get("data");

		LobbySocket.resetSent();
		clickEditorMenu(editor, "testButton");
		var testCourse = Std.downcast(holder.getCurrentPage(), TestCoursePage);
		assertNotNull(testCourse, "editor test button opens the test-course page");
		assertEquals(true, testCourse.isMod, "test course preserves editor mod flag");
		assertEquals(true, testCourse.reportsMode, "test course preserves reports mode");
		assertEquals(sourceData, testCourse.variables.get("data"), "test course receives serialized editor data");
		assertNotNull(testCourse.course, "test course mounts a playable Course");
		assertNotNull(DisplayUtil.findByName(testCourse.art, "back_bt"), "test course mounts authored back button");
		assertNotNull(DisplayUtil.findByName(testCourse.art, "restart_bt"), "test course mounts authored restart button");
		assertNotNull(testCourse.statsSelect, "test course mounts the StatsSelect control");
		assertNotNull(testCourse.hatPicker, "test course mounts the HatPicker control");
		assertEquals(10.0, testCourse.statsSelect.x, "test course stat picker x matches Flash holder placement");
		assertEquals(290.0, testCourse.statsSelect.y, "test course stat picker y matches Flash holder placement");
		assertEquals(0.66, testCourse.statsSelect.scaleX, "test course stat picker scale matches Flash");
		assertEquals(15.0, testCourse.hatPicker.x, "test course hat picker x matches Flash holder placement");
		assertEquals(265.0, testCourse.hatPicker.y, "test course hat picker y matches Flash holder placement");
		assertEquals(0.7, testCourse.hatPicker.scaleX, "test course hat picker scale matches Flash");
		var initialStats = testCourse.course.localCharacter.debugState();
		assertEquals(61, Math.round(initialStats.speedStat), "test course applies saved speed stat");
		assertEquals(72, Math.round(initialStats.accelerationStat), "test course applies saved acceleration stat");
		assertEquals(83, Math.round(initialStats.jumpStat), "test course applies saved jump stat");
		assertEquals(13, testCourse.course.localCharacter.hat1, "test course applies saved test hat");
		assertEquals(true, LobbySocket.sentCommands.length > 0 && StringTools.startsWith(LobbySocket.sentCommands[0], "exact_pos`"),
			"test course starts the race countdown like Flash");

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
		DisplayUtil.findByName(testCourse.art, "restart_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, firstCourse != testCourse.course, "restart rebuilds the test course");
		assertEquals(null, firstCourse.parent, "restart removes the previous Course display");
		assertEquals(null, firstStatsSelect.parent, "restart removes the previous StatsSelect display");
		assertEquals(null, firstHatPicker.parent, "restart removes the previous HatPicker display");
		var restartedStats = testCourse.course.localCharacter.debugState();
		assertEquals(91, Math.round(restartedStats.speedStat), "restart applies saved speed stat");
		assertEquals(82, Math.round(restartedStats.accelerationStat), "restart applies saved acceleration stat");
		assertEquals(73, Math.round(restartedStats.jumpStat), "restart applies saved jump stat");
		assertEquals(15, testCourse.course.localCharacter.hat1, "restart applies saved test hat");

		DisplayUtil.findByName(testCourse.art, "back_bt").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var returnedEditor = Std.downcast(holder.getCurrentPage(), LevelEditor);
		assertNotNull(returnedEditor, "back button returns to the level editor");
		assertEquals(true, returnedEditor.isMod, "returned editor preserves mod flag");
		assertEquals(true, returnedEditor.reportsMode, "returned editor preserves reports mode");
		assertEquals("Testable Level", returnedEditor.title, "returned editor restores level vars");
		assertEquals("2.0", returnedEditor.gravity, "returned editor restores normalized gravity");
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
		// Campaign page formula `((server_id + day) % 6) + 1`, 1..6.
		assertEquals(1, pr2.net.LevelListClient.campaignPage(0, 0), "campaign page base");
		assertEquals(3, pr2.net.LevelListClient.campaignPage(5, 3), "campaign page wraps within 6");
		assertEquals(6, pr2.net.LevelListClient.campaignPage(2, 3), "campaign page upper");
		// Parsing pulls the levels array; an arbitrary body has an invalid hash.
		var body = '{"hash":"zzz","levels":[{"level_id":"7","title":"Alpha","user_name":"Jo"},{"level_id":"8","title":"Beta","user_name":"Al"}]}';
		var result = pr2.net.LevelListClient.parse(body);
		assertEquals(2, result.levels.length, "parsed level count");
		assertEquals(7, result.levels[0].levelId, "first level id");
		assertEquals("Beta", result.levels[1].title, "second level title");
		assertEquals(false, result.hashValid, "arbitrary hash is invalid");
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
		var handled = handler.handleServerFrame("abc`5`setChatRoomList`main`speed`");
		assertEquals(true, handled, "frame handled");
		assertEquals("main", captured[0], "first arg parsed");
		assertEquals("speed", captured[1], "second arg parsed");
		handler.defineCommand("setChatRoomList", null);
		assertEquals(false, handler.handleServerFrame("abc`6`setChatRoomList`x`"), "cleared command ignored");

		SecureData.clear();
		assertEquals(true, handler.handleServerFrame("abc`7`setRank`37`"), "default setRank handled");
		assertEquals(37.0, SecureData.getNumber("userRank"), "setRank updates secure rank");
		handler.clearAll();
		assertEquals(true, handler.handleServerFrame("abc`8`setRank`38`"), "default setRank survives clearAll");
		assertEquals(38.0, SecureData.getNumber("userRank"), "setRank remains global");
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
	}

	private static function closeAllPopups():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
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

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
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

private class TestPage extends Page {
	public var id(default, null):String;

	public function new(id:String) {
		super();
		this.id = id;
	}
}
