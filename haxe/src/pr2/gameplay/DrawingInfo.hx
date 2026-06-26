package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.net.CommandHandler;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `gameplay.DrawingInfo`'s drawing-readiness rows.

	The full finish-times table is part of the race-lifecycle work; this component
	covers the live "drawing..." status used while players wait for map drawing.
**/
class DrawingInfo extends Sprite {
	private static inline final MAX_PLAYERS:Int = 4;

	private var art:Null<PR2MovieClip>;
	private var info1:Null<DisplayObjectContainer>;
	private var info2:Null<DisplayObjectContainer>;
	private var names:Array<Null<String>> = [];
	private var commandHandler:CommandHandler;

	public function new(?commandHandler:CommandHandler) {
		super();
		this.commandHandler = commandHandler == null ? CommandHandler.commandHandler : commandHandler;
		art = PR2MovieClip.fromLinkage("DrawingInfoGraphic", {maxNestedDepth: 5});
		addChild(art);
		info1 = Std.downcast(LobbyArt.findByName(art, "info1"), DisplayObjectContainer);
		info2 = Std.downcast(LobbyArt.findByName(art, "info2"), DisplayObjectContainer);
		for (i in 0...MAX_PLAYERS) {
			names[i] = null;
			setDrawingVisible(i, false);
			setName(i, "");
			setTime(i, "");
		}
		this.commandHandler.defineCommand("finishDrawing", onFinishDrawingCommand);
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
		for (i in 0...MAX_PLAYERS) {
			if (timeText(i) == "") {
				names[i] = null;
				setName(i, "");
			}
			setDrawingVisible(i, false);
		}
	}

	public function remove():Void {
		commandHandler.defineCommand("finishDrawing", null);
		if (art != null) {
			art.dispose();
			art = null;
		}
		info1 = null;
		info2 = null;
		names = [];
		if (parent != null) {
			parent.removeChild(this);
		}
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

	private function onFinishDrawingCommand(args:Array<String>):Void {
		if (args.length == 0) {
			return;
		}
		var tempID = Std.parseInt(args[0]);
		if (tempID != null) {
			finishDrawing(tempID);
		}
	}

	private function setName(tempID:Int, value:String):Void {
		setFieldText(info1, "nameBox" + tempID, value);
		setFieldText(info2, "nameBox" + tempID, value);
	}

	private function setTime(tempID:Int, value:String):Void {
		setFieldText(info1, "timeBox" + tempID, value);
		setFieldText(info2, "timeBox" + tempID, value);
	}

	private function setDrawingVisible(tempID:Int, visible:Bool):Void {
		var anim = findInBoth("anim" + tempID);
		if (anim.first != null) anim.first.visible = visible;
		if (anim.second != null) anim.second.visible = visible;
	}

	private function findInBoth(name:String):{first:Null<DisplayObject>, second:Null<DisplayObject>} {
		return {
			first: LobbyArt.findByName(info1, name),
			second: LobbyArt.findByName(info2, name)
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
}
