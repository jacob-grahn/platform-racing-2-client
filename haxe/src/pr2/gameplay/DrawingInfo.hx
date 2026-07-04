package pr2.gameplay;

import com.jiggmin.data.Data;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.Constants;
import pr2.display.Removable;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.HoverPopup;
import pr2.net.CommandHandler;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `gameplay.DrawingInfo`: drawing-readiness rows and finish table.
**/
class DrawingInfo extends Removable {
	private static inline final MAX_PLAYERS:Int = 4;

	private var art:Null<PR2MovieClip>;
	private var info1:Null<DisplayObjectContainer>;
	private var info2:Null<DisplayObjectContainer>;
	private var names:Array<Null<String>> = [];
	private var commandHandler:CommandHandler;
	private var gameMode:String;
	private var courseId:Int;
	private var framesPlaying:Void->Int;
	private var frameRate:Void->Float;
	private var submitKongStat:Null<String->String->Void>;
	private var localTimeHover:Null<HoverPopup>;
	private var localTimeHoverContent:String = "";
	private var localTimeBox:Null<TextField>;

	public function new(?commandHandler:CommandHandler, gameMode:String = "race", courseId:Int = 0, ?framesPlaying:Void->Int, ?frameRate:Void->Float,
			?submitKongStat:String->String->Void) {
		super();
		this.commandHandler = commandHandler == null ? CommandHandler.commandHandler : commandHandler;
		this.gameMode = gameMode;
		this.courseId = courseId;
		this.framesPlaying = framesPlaying == null ? function():Int return 0 : framesPlaying;
		this.frameRate = frameRate == null ? function():Float return Constants.FRAME_RATE : frameRate;
		this.submitKongStat = submitKongStat;
		art = PR2MovieClip.fromLinkage("DrawingInfoGraphic", {maxNestedDepth: 5});
		addChild(art);
		info1 = Std.downcast(DisplayUtil.findByName(art, "info1"), DisplayObjectContainer);
		info2 = Std.downcast(DisplayUtil.findByName(art, "info2"), DisplayObjectContainer);
		for (i in 0...MAX_PLAYERS) {
			names[i] = null;
			setDrawingVisible(i, false);
			setName(i, "");
			setTime(i, "");
		}
		this.commandHandler.defineCommand("finishDrawing", onFinishDrawingCommand);
		this.commandHandler.defineCommand("finishTimes", onFinishTimesCommand);
	}

	public function addPlayer(name:String, tempID:Int):Void {
		if (!validTempID(tempID)) {
			return;
		}
		names[tempID] = name;
		setName(tempID, name);
		setDrawingVisible(tempID, true);
	}

	public function finishDrawing(tempID:Int):Void {
		if (!validTempID(tempID)) {
			return;
		}
		setDrawingVisible(tempID, false);
	}

	public function clear():Void {
		clearLocalTimeHover();
		unbindLocalTimeHover();
		for (i in 0...MAX_PLAYERS) {
			if (timeText(i) == "") {
				names[i] = null;
				setName(i, "");
			}
			setDrawingVisible(i, false);
		}
	}

	override public function remove():Void {
		if (isRemoved()) return;
		clearLocalTimeHover();
		unbindLocalTimeHover();
		commandHandler.defineCommand("finishTimes", null);
		commandHandler.defineCommand("finishDrawing", null);
		if (art != null) {
			art.dispose();
			art = null;
		}
		info1 = null;
		info2 = null;
		names = [];
		super.remove();
	}

	public function playerName(tempID:Int):String {
		return fieldText(info1, "nameBox" + tempID);
	}

	public function timeText(tempID:Int):String {
		return fieldText(info1, "timeBox" + tempID);
	}

	public function isDrawing(tempID:Int):Bool {
		var anim = findInBoth("anim" + tempID);
		return anim.first != null && anim.second != null && anim.first.visible && anim.second.visible;
	}

	public function finishRace(args:Array<String>):Void {
		clear();
		var row = 0;
		var key = 0;
		while (key + 1 < args.length && row < MAX_PLAYERS) {
			if (timeText(0) == "" && row > 0) {
				row = 0;
			}
			var name = arg(args, key);
			var time = arg(args, key + 1);
			var drawing = boolArg(args, key + 2);
			var stillHere = boolArg(args, key + 3, true);
			var isLocal = name.toLowerCase() == LobbySession.userName.toLowerCase();
			if (isLocal && time != "forfeit") {
				maybeSubmitKongStat(time);
			}
			var text = formatFinishTime(time, drawing, stillHere);
			setName(row, name);
			if (drawing) {
				setDrawingVisible(row, true);
			}
			if (isLocal && gameMode != Modes.egg && time != "forfeit") {
				setTime(row, text + "*");
				bindLocalTimeHover(row);
			} else {
				setTime(row, text);
			}
			row++;
			key += 4;
		}
		while (row < MAX_PLAYERS) {
			setTime(row, "");
			setName(row, "");
			setDrawingVisible(row, false);
			row++;
		}
	}

	public function hasLocalTimeHoverForTests():Bool {
		return localTimeHover != null;
	}

	public function localTimeHoverContentForTests():String {
		return localTimeHoverContent;
	}

	public function showLocalTimeHoverForTests():Void {
		onMouseLoggedInPlayerTime(new MouseEvent(MouseEvent.MOUSE_OVER));
	}

	public function hideLocalTimeHoverForTests():Void {
		onMouseLoggedInPlayerTime(new MouseEvent(MouseEvent.MOUSE_OUT));
	}

	private function onFinishDrawingCommand(args:Array<String>):Void {
		if (args.length == 0) {
			return;
		}
		var tempID = Std.parseInt(args[0]);
		if (tempID != null) {
			finishDrawing(tempID);
		}
	}

	private function onFinishTimesCommand(args:Array<String>):Void {
		finishRace(args);
	}

	private function setName(tempID:Int, value:String):Void {
		setFieldText(info1, "nameBox" + tempID, value);
		setFieldText(info2, "nameBox" + tempID, value);
	}

	private function setTime(tempID:Int, value:String):Void {
		setFieldText(info1, "timeBox" + tempID, value);
		setFieldText(info2, "timeBox" + tempID, value);
	}

	private function bindLocalTimeHover(row:Int):Void {
		unbindLocalTimeHover();
		localTimeBox = LobbyArt.text(info1, "timeBox" + row);
		if (localTimeBox != null) {
			localTimeBox.addEventListener(MouseEvent.MOUSE_OVER, onMouseLoggedInPlayerTime);
			localTimeBox.addEventListener(MouseEvent.MOUSE_OUT, onMouseLoggedInPlayerTime);
		}
	}

	private function unbindLocalTimeHover():Void {
		if (localTimeBox != null) {
			localTimeBox.removeEventListener(MouseEvent.MOUSE_OVER, onMouseLoggedInPlayerTime);
			localTimeBox.removeEventListener(MouseEvent.MOUSE_OUT, onMouseLoggedInPlayerTime);
			localTimeBox = null;
		}
	}

	private function onMouseLoggedInPlayerTime(?event:MouseEvent):Void {
		if (event == null || event.type != MouseEvent.MOUSE_OVER) {
			clearLocalTimeHover();
			return;
		}
		var rate = frameRate();
		var frames = framesPlaying();
		var framesToTime = Data.formatTime(rate <= 0 ? 0 : frames / rate, "decimal");
		localTimeHoverContent = 'The time listed here is the time the server reports. This includes lag.\n\nSince you played for $frames frames at ${formatFrameRate(rate)}fps, your no-lag time is $framesToTime.';
		clearLocalTimeHover();
		if (info1 != null) {
			localTimeHover = new HoverPopup("Timing for Nerds", localTimeHoverContent, info1);
			localTimeHover.x = 100;
			localTimeHover.y += 20;
		}
	}

	private function clearLocalTimeHover():Void {
		if (localTimeHover != null) {
			localTimeHover.remove();
			localTimeHover = null;
		}
	}

	private function formatFinishTime(time:String, drawing:Bool, stillHere:Bool):String {
		var text = "";
		if (drawing) {
			text = "";
		} else if (gameMode == Modes.obj) {
			var parts = time.split(",");
			text = parts[0] != "forfeit" ? Data.formatTime(number(parts[0]), "decimal") : parts[0];
			if (parts.length > 2 && parts[1] != null && parts[2] != null) {
				text += ' (${Std.int(number(parts[1]))}/${Std.int(number(parts[2]))})';
			}
		} else if (number(time) > 0 && time != "forfeit" && gameMode != Modes.egg) {
			text = Data.formatTime(number(time), "decimal");
		} else {
			text = time;
		}
		if (!stillHere) {
			text += " (gone)";
		}
		return text;
	}

	private function maybeSubmitKongStat(time:String):Void {
		if (submitKongStat == null) {
			return;
		}
		var courseName = kongCourseName(courseId);
		if (courseName != "") {
			submitKongStat(courseName, time);
		}
	}

	private function setDrawingVisible(tempID:Int, visible:Bool):Void {
		var anim = findInBoth("anim" + tempID);
		if (anim.first != null) anim.first.visible = visible;
		if (anim.second != null) anim.second.visible = visible;
	}

	private function findInBoth(name:String):{first:Null<DisplayObject>, second:Null<DisplayObject>} {
		return {
			first: DisplayUtil.findByName(info1, name),
			second: DisplayUtil.findByName(info2, name)
		};
	}

	private static function validTempID(tempID:Int):Bool {
		return tempID >= 0 && tempID < MAX_PLAYERS;
	}

	private static function setFieldText(container:Null<DisplayObjectContainer>, name:String, value:String):Void {
		var field:Null<TextField> = LobbyArt.text(container, name);
		if (field != null) {
			field.text = value;
		}
	}

	private static function fieldText(container:Null<DisplayObjectContainer>, name:String):String {
		var field:Null<TextField> = LobbyArt.text(container, name);
		return field == null ? "" : field.text;
	}

	private static function arg(args:Array<String>, index:Int):String {
		return index >= 0 && index < args.length && args[index] != null ? args[index] : "";
	}

	private static function boolArg(args:Array<String>, index:Int, fallback:Bool = false):Bool {
		var value = arg(args, index);
		if (value == "") {
			return fallback;
		}
		var lower = value.toLowerCase();
		return lower == "true" || lower == "1" || lower == "yes";
	}

	private static function number(value:String):Float {
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? 0 : parsed;
	}

	private static function formatFrameRate(value:Float):String {
		return Math.ffloor(value) == value ? Std.string(Std.int(value)) : Std.string(value);
	}

	private static function kongCourseName(courseID:Int):String {
		return switch (courseID) {
			case 50815: "Newbieland 2";
			case 80814: "Mario Bros Remix";
			case 7376: "Soul Temple";
			case 102573: "Razor Blade";
			case 81998: "New York";
			case 1990682: "Blacklight";
			case 3460484: "Candyland";
			case 76127: "Zerostar";
			case 84156: "Hat Factory";
			default: "";
		}
	}
}
