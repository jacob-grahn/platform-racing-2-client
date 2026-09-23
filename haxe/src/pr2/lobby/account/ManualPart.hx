package pr2.lobby.account;

import openfl.events.Event;
import openfl.events.EventDispatcher;

/** Catalog equip events are independent of either account presentation. */
class ManualPart {
	public static final dispatcher = new EventDispatcher();
	public static var selection:Array<Dynamic> = [];
	public static inline var CHANGE = "manualPart";
	public static function set(type:String, id:Int):Void { selection = [type, id]; dispatch(); }
	public static function dispatch():Void dispatcher.dispatchEvent(new Event(CHANGE));
}
