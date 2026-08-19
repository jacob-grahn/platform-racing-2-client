package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.text.TextField;
import pr2.levelEditor.EditorBlockOptionsView;
import pr2.levelEditor.EditorSettingsMenuView;
import pr2.levelEditor.GetLevelsView;
import pr2.levelEditor.HandleLevelReportView;
import pr2.levelEditor.SaveLevelView;
import pr2.lobby.dialogs.LevelInfoView;
import pr2.lobby.dialogs.OptionsView;
import pr2.lobby.dialogs.PlayerView;
import pr2.lobby.dialogs.SendMessageView;
import pr2.lobby.tabs.SearchTab;
import pr2.page.LoginFlashPopup;

class TextFieldParityTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("TextFieldParityTest.testLogin", testLogin);
		if (pr2.DeterministicTestMode.finishSmokeSuite("TextFieldParityTest")) return;
		pr2.DeterministicTestMode.runTest("TextFieldParityTest.testOptionsAndSearch", testOptionsAndSearch);
		pr2.DeterministicTestMode.runTest("TextFieldParityTest.testPlayerAndLevel", testPlayerAndLevel);
		pr2.DeterministicTestMode.runTest("TextFieldParityTest.testSendMessage", testSendMessage);
		pr2.DeterministicTestMode.runTest("TextFieldParityTest.testEditorDialogs", testEditorDialogs);
		trace('TextFieldParityTest passed $assertions assertions');
	}

	private static function testLogin():Void {
		var login = new LoginFlashPopup("LoginPopupGraphic");
		assertColor(0x000000, findText(login, "name:"), "login labels use authored black");
		login.remove();
	}

	private static function testOptionsAndSearch():Void {
		var options = new OptionsView();
		assertColor(0x000000, options.title, "options labels use authored black");
		options.dispose();

		var search = new SearchTab();
		search.initialize();
		assertColor(0x000000, findText(search, "Search By:"), "search labels use authored black");
		search.remove();
	}

	private static function testPlayerAndLevel():Void {
		var player = new PlayerView();
		assertColor(0x000000, namedText(player, "nameBox"), "player name uses authored black");
		assertColor(0x151515, namedText(player, "groupBox"), "player details use authored near-black");
		player.dispose();

		var level = new LevelInfoView();
		assertColor(0x000000, namedText(level, "title"), "level title uses authored black");
		assertColor(0x666666, namedText(level, "author"), "level author uses authored gray");
		assertColor(0x666666, namedText(level, "note"), "level note uses authored gray");
		assertSize(11, findText(level, "Version:"), "level labels use authored 11px size");
		level.dispose();
	}

	private static function testSendMessage():Void {
		var message = new SendMessageView("Target", "Message");
		assertColor(0x666666, message.warning, "message warning uses authored gray");
		assertColor(0xAAAAAA, message.charsRemaining, "message counter uses authored light gray");
		assertSize(8, message.charsRemaining, "message counter uses authored 8px size");
		message.dispose();
	}

	private static function testEditorDialogs():Void {
		var block = new EditorBlockOptionsView("StatBlockOptionsGraphic");
		assertColor(0x000000, namedText(block, "titleBox"), "block-options text uses authored black");
		block.dispose();
		var settings = new EditorSettingsMenuView("mode");
		assertColor(0x000000, findText(settings, "-- Game Mode --"), "editor-settings text uses authored black");
		settings.dispose();
		var levels = new GetLevelsView();
		assertColor(0x000000, namedText(levels, "titleBox"), "get-levels text uses authored black");
		levels.dispose();
		var report = new HandleLevelReportView();
		assertColor(0x000000, namedText(report, "heading"), "level-report text uses authored black");
		report.dispose();
		var save = new SaveLevelView();
		assertColor(0x000000, namedText(save, "heading"), "save-level heading uses authored black");
		assertColor(0x000000, namedText(save, "warning"), "save-level warning uses authored black");
		save.dispose();
	}

	private static function namedText(root:DisplayObjectContainer, name:String):TextField {
		var found = findNamed(root, name);
		var field = Std.downcast(found, TextField);
		if (field == null) throw '$name text field missing';
		return field;
	}

	private static function findNamed(root:DisplayObjectContainer, name:String):Null<DisplayObject> {
		for (index in 0...root.numChildren) {
			var child = root.getChildAt(index);
			if (child.name == name) return child;
			var container = Std.downcast(child, DisplayObjectContainer);
			if (container != null) {
				var nested = findNamed(container, name);
				if (nested != null) return nested;
			}
		}
		return null;
	}

	private static function findText(root:DisplayObjectContainer, value:String):TextField {
		for (index in 0...root.numChildren) {
			var child = root.getChildAt(index);
			var field = Std.downcast(child, TextField);
			if (field != null && field.text == value) return field;
			var container = Std.downcast(child, DisplayObjectContainer);
			if (container != null) {
				var nested = findTextOrNull(container, value);
				if (nested != null) return nested;
			}
		}
		throw '$value text field missing';
	}

	private static function findTextOrNull(root:DisplayObjectContainer, value:String):Null<TextField> {
		for (index in 0...root.numChildren) {
			var child = root.getChildAt(index);
			var field = Std.downcast(child, TextField);
			if (field != null && field.text == value) return field;
			var container = Std.downcast(child, DisplayObjectContainer);
			if (container != null) {
				var nested = findTextOrNull(container, value);
				if (nested != null) return nested;
			}
		}
		return null;
	}

	private static function assertColor(expected:Int, field:TextField, message:String):Void {
		assertions++;
		if (field.textColor != expected) throw '$message: expected $expected, got ${field.textColor}';
	}

	private static function assertSize(expected:Float, field:TextField, message:String):Void {
		assertions++;
		var actual:Float = field.defaultTextFormat.size;
		if (Math.abs(expected - actual) > 0.001) throw '$message: expected $expected, got $actual';
	}
}
