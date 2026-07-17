package pr2.lobby.level;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.level.SlotView.SlotBackground;

/**
	Port of Flash `level_browser.Slot` — one of the four join slots on a
	`LevelItem`. Clicking an empty slot sends `fill_slot` to the gameserver; the
	server then drives `fillSlot`/`confirmSlot`/`clearSlot` through the level item.
	The slot background steps through `<status>Up` / `<status>Over` / `pending`
	frames exactly as in Flash. When the local player fills a slot (`me == "me"`),
	a `CourseMenu` opens beside it; `sendConfirmSlot`/`sendClearSlot` route back
	through the owning `LevelItem` to the gameserver.
**/
class Slot extends Sprite {
	private var num:Int;
	private var owner:Null<LevelItem>;
	private var art:SlotView;
	private var bg:Null<SlotBackground>;
	private var rankBox:Null<TextField>;
	private var nameBox:Null<TextField>;
	private var status:String = "empty";
	private var courseMenu:Null<CourseMenu>;

	public function new(num:Int, owner:LevelItem) {
		super();
		// Give browser automation a stable target that only exists after the
		// asynchronous level listing has rendered. Multiple listings may contain
		// slots, so the driver selects by display-list index.
		name = "levelSlot";
		this.num = num;
		this.owner = owner;
		art = new SlotView();
		addChild(art);
		bg = art.background;
		// The bg is a multi-frame state machine (emptyUp/emptyOver/pending/...),
		// not an animation. Rest it on the initial status frame so it doesn't
		// free-run through every state until the first server-driven change.
		changeStatus(status);
		rankBox = art.rankBox;
		nameBox = art.nameBox;
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
		if (me == "me" && owner != null) {
			owner.selectLevel();
			courseMenu = new CourseMenu(this);
		}
	}

	/** Confirm/clear route through the owning level item to the gameserver,
		mirroring Flash `Slot.sendConfirmSlot`/`sendClearSlot`. */
	public function sendConfirmSlot():Void {
		if (owner != null) {
			owner.sendConfirmSlot();
		}
	}

	public function sendClearSlot():Void {
		if (owner != null) {
			owner.sendClearSlot();
			owner.clearSelectedLevel();
		}
		courseMenu = null;
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
		if (owner != null) {
			owner.sendFillSlot(num);
		}
	}

	private inline function gotoBg(frame:String):Void {
		if (bg != null) {
			bg.render(frame);
		}
	}

	public function remove():Void {
		if (courseMenu != null) {
			courseMenu.remove();
			courseMenu = null;
		}
		owner = null;
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
