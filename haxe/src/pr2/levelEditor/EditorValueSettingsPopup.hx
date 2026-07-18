package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.app.AppStage;
import pr2.lobby.dialogs.AutoDismissController;
import pr2.ui.controls.GameTextInput;
import pr2.ui.StageFocus;

class EditorValueSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:EditorSettingsMenuView;
	public final settingId:String;
	private var valueInput:Null<GameTextInput>;
	private var autoDismiss:Null<AutoDismissController>;
	private var removed:Bool = false;
	private var defaultVal:String = "0";

	public function new(editor:LevelEditor, target:DisplayObject, settingId:String) {
		super();
		this.editor = editor;
		this.settingId = settingId;
		art = new EditorSettingsMenuView("value");
		addChild(art);
		configure();
		mountNear(target);
		autoDismiss = new AutoDismissController(this, remove);
	}

	public static function handles(settingId:String):Bool {
		return switch (settingId) {
			case "rank" | "gravity" | "time" | "sfcm" | "pass": true;
			default: false;
		}
	}

	public function value():String {
		return valueInput == null ? "" : valueInput.text;
	}

	public function setValue(nextValue:String):Void {
		if (valueInput != null) {
			valueInput.text = nextValue == null ? "" : nextValue;
		}
		commitValue();
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (autoDismiss != null) {
			autoDismiss.remove();
			autoDismiss = null;
		}
		if (valueInput != null) {
			valueInput.textField.removeEventListener(Event.CHANGE, commitValue);
		}
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.valueSettingsPopupRemoved(this);
		StageFocus.reset();
	}

	private function configure():Void {
		var spec = specFor(settingId);
		defaultVal = spec.defaultVal;
		var titleBox = art.titleBox;
		var descBox = art.descBox;
		if (titleBox != null) {
			titleBox.htmlText = "<b>-- " + spec.title + " --</b>";
		}
		if (descBox != null) {
			descBox.htmlText = spec.desc;
		}
		valueInput = art.valueInput;
		if (valueInput != null) {
			valueInput.text = spec.value;
			valueInput.textField.maxChars = spec.maxChars;
			if (spec.restrict != null) {
				valueInput.textField.restrict = spec.restrict;
			}
			valueInput.textField.displayAsPassword = spec.displayAsPassword;
			valueInput.textField.addEventListener(Event.CHANGE, commitValue);
			if (AppStage.stage != null) {
				AppStage.stage.focus = valueInput.textField;
			}
		}
	}

	private function specFor(settingId:String):EditorValueSettingSpec {
		return switch (settingId) {
			case "rank":
				{id: "rank", title: "Minimum Rank", desc: "Players below this rank will not be able to race on this course.",
					value: editor.minRank, maxChars: 2, restrict: "0123456789", defaultVal: "0", displayAsPassword: false};
			case "gravity":
				{id: "gravity", title: "Gravity Multiplier", desc: "Normal gravity will be multiplied by the number you provide.",
					value: editor.gravity, maxChars: 4, restrict: "-.0123456789", defaultVal: "0", displayAsPassword: false};
			case "time":
				{id: "time", title: "Time Limit",
					desc: "Racers will have this amount of seconds to complete this course. Enter 0 for infinite time.", value: editor.maxTime,
					maxChars: 4, restrict: "0123456789", defaultVal: "0", displayAsPassword: false};
			case "sfcm":
				{id: "sfcm", title: "Chance of Cowboy Mode", desc: "Super Flying Cowboy Mode will appear this often out of 100.",
					value: editor.cowboyChance, maxChars: 3, restrict: "0123456789", defaultVal: "0", displayAsPassword: false};
			case "pass":
				{id: "pass", title: "Secret Password", desc: "This password lets players play your course while unpublished.",
					value: editor.pass == null ? "" : editor.pass, maxChars: 32, restrict: null, defaultVal: "", displayAsPassword: false};
			default:
				{id: settingId, title: settingId, desc: "", value: "", maxChars: 9, restrict: "0123456789", defaultVal: "0",
					displayAsPassword: false};
		}
	}

	private function commitValue(?_):Void {
		var text = valueInput == null ? "" : valueInput.text;
		if (text == "") {
			text = defaultVal;
		}
		switch (settingId) {
			case "rank":
				editor.setMinRank(text);
			case "gravity":
				editor.setGravity(text);
			case "time":
				editor.setMaxTime(text);
			case "sfcm":
				editor.setCowboyChance(text);
			case "pass":
				editor.setPass(text);
			default:
		}
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 250 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 95 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

}
