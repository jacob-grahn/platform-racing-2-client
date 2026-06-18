package pr2.lobby.level;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `level_browser.Slot` — one of the four join slots on a
	`LevelItem`. Clicking an empty slot sends `fill_slot` to the gameserver; the
	server then drives `fillSlot`/`confirmSlot`/`clearSlot` through the level item.
	The slot background steps through `<status>Up` / `<status>Over` / `pending`
	frames exactly as in Flash.

	`CourseMenu` (shown when the local player fills a slot) is not yet ported; the
	socket `fill_slot`/`confirm_slot`/`clear_slot` round-trip is faithful.
**/
class Slot extends Sprite {
	private var num:Int;
	private var owner:LevelItem;
	private var art:PR2MovieClip;
	private var bg:Null<PR2MovieClip>;
	private var rankBox:Null<TextField>;
	private var nameBox:Null<TextField>;
	private var status:String = "empty";

	public function new(num:Int, owner:LevelItem) {
		super();
		this.num = num;
		this.owner = owner;
		art = PR2MovieClip.fromLinkage("SlotGraphic", {maxNestedDepth: 4});
		addChild(art);
		bg = Std.downcast(LobbyArt.findByName(art, "bg"), PR2MovieClip);
		rankBox = LobbyArt.text(art, "rankBox");
		nameBox = LobbyArt.text(art, "nameBox");
		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		addEventListener(MouseEvent.CLICK, onClick);
	}

	public function fillSlot(name:String, rank:Float, me:String):Void {
		clearSlot();
		if (rankBox != null) {
			rankBox.text = Std.string(Std.int(rank));
		}
		if (nameBox != null) {
			nameBox.text = name;
		}
		changeStatus("filled");
		// Flash opens a CourseMenu here when me == "me"; menu port is pending.
	}

	public function confirmSlot():Void {
		changeStatus("confirmed");
	}

	public function clearSlot():Void {
		if (rankBox != null) {
			rankBox.text = "";
		}
		if (nameBox != null) {
			nameBox.text = "";
		}
		changeStatus("empty");
	}

	private function changeStatus(s:String):Void {
		status = s;
		gotoBg(status + "Up");
	}

	private function onOver(_:MouseEvent):Void {
		gotoBg(status + "Over");
	}

	private function onOut(_:MouseEvent):Void {
		gotoBg(status + "Up");
	}

	private function onClick(_:MouseEvent):Void {
		gotoBg("pending");
		owner.sendFillSlot(num);
	}

	private inline function gotoBg(frame:String):Void {
		if (bg != null) {
			bg.gotoAndStop(frame);
		}
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		removeEventListener(MouseEvent.CLICK, onClick);
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
