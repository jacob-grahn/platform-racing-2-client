package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;

class PopupButtonStack {
	private var owner:DisplayObjectContainer;
	private var nextY:Float;
	private var gap:Float;
	private var bindings:Array<Null<Binding>> = [];
	private var buttons:Array<DisplayObject> = [];

	public function new(owner:DisplayObjectContainer, startY:Float = 80, gap:Float = 20) {
		this.owner = owner;
		this.nextY = startY;
		this.gap = gap;
	}

	public function hide(button:Null<DisplayObject>):Void {
		if (button == null) return;
		button.visible = false;
		if (button.parent == owner) {
			owner.removeChild(button);
		}
	}

	public function add(button:Null<DisplayObject>, handler:Void->Void):Void {
		if (button == null) return;
		if (button.parent != owner) {
			owner.addChild(button);
		}
		button.visible = true;
		button.y = nextY;
		nextY -= gap;
		buttons.push(button);
		bindings.push(LobbyArt.bind(button, handler));
	}

	public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		for (button in buttons) {
			if (button != null) {
				button.visible = false;
				if (button.parent == owner) {
					owner.removeChild(button);
				}
			}
		}
		buttons = [];
		owner = null;
	}
}
