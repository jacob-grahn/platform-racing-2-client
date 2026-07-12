package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.display.Removable;
import pr2.runtime.FontResolver;
import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `gameplay.ItemDisplay`.

	The authored timeline contains one labelled frame per item. The two nested
	text holders form the dark/light item-name treatment, while `a1`-`a3` are
	the ammo dots.
**/
class ItemDisplay extends Removable {
	private var art:Null<PR2MovieClip>;
	private var darkLabel:TextField;
	private var lightLabel:TextField;
	private var snakeIcon:Shape;

	public var itemCode(default, null):Int = 0;
	public var itemName(default, null):String = "None";
	public var ammo(default, null):Int = 0;

	public function new() {
		super();
		mouseChildren = false;
		mouseEnabled = false;
		art = PR2MovieClip.fromLinkage("ItemDisplayGraphic", {maxNestedDepth: 5});
		addChild(art);
		darkLabel = createLabel(2, 55, 0x000000);
		lightLabel = createLabel(3, 56, 0xFFFFFF);
		addChild(darkLabel);
		addChild(lightLabel);
		snakeIcon = createSnakeIcon();
		addChild(snakeIcon);
		setItemCode(0);
	}

	public function setItemCode(code:Int):Void {
		itemCode = code;
		setItem(itemNameFromCode(code));
	}

	public function setItem(name:String):Void {
		if (art == null) {
			return;
		}
		itemName = name;
		art.gotoAndStop(name == "Snake" ? "None" : name);
		snakeIcon.visible = name == "Snake";
		hideAuthoredTextHolder("holder1");
		hideAuthoredTextHolder("holder2");
		darkLabel.text = name;
		lightLabel.text = name;
		setAmmo(name == "None" ? 0 : 1);
	}

	public function setAmmo(value:Int):Void {
		ammo = clampAmmo(value);
		for (index in 1...4) {
			var dot = DisplayUtil.findByName(art, "a" + index);
			if (dot != null) {
				dot.visible = index <= ammo;
			}
		}
	}

	private function hideAuthoredTextHolder(holderName:String):Void {
		var holder = DisplayUtil.findByName(art, holderName);
		if (holder != null) {
			holder.visible = false;
		}
	}

	private function createLabel(x:Float, y:Float, color:Int):TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(FontResolver.resolve("Verdana"), 12, color);
		field.x = x;
		field.y = y;
		field.width = 100;
		field.height = 14.5;
		field.alpha = 0.5;
		field.selectable = false;
		field.mouseEnabled = false;
		return field;
	}

	private function createSnakeIcon():Shape {
		var icon = new Shape();
		icon.x = 17;
		icon.y = 15;
		icon.graphics.lineStyle(2, 0x174D20);
		icon.graphics.beginFill(0x42C95A);
		icon.graphics.drawRoundRect(0, 4, 34, 25, 8, 8);
		icon.graphics.endFill();
		icon.graphics.beginFill(0xE8FFE8);
		icon.graphics.drawCircle(10, 12, 3);
		icon.graphics.drawCircle(24, 12, 3);
		icon.graphics.endFill();
		icon.visible = false;
		return icon;
	}

	public function ammoVisible(index:Int):Bool {
		var dot:Null<DisplayObject> = DisplayUtil.findByName(art, "a" + index);
		return dot != null && dot.visible;
	}

	public function labelText(holderName:String):Null<String> {
		return switch (holderName) {
			case "holder1": darkLabel.text;
			case "holder2": lightLabel.text;
			default: null;
		};
	}

	override public function remove():Void {
		if (isRemoved()) return;
		if (art != null) {
			art.dispose();
			art = null;
		}
		darkLabel = null;
		lightLabel = null;
		snakeIcon = null;
		super.remove();
	}

	public static function itemNameFromCode(code:Int):String {
		return switch (code) {
			case 1: "Laser";
			case 2: "Mine";
			case 3: "Lightning";
			case 4: "Teleport";
			case 5: "Super Jump";
			case 6: "Jet Pack";
			case 7: "Speed Burst";
			case 8: "Sword";
			case 9: "Ice Wave";
			case 10: "Snake";
			default: "None";
		};
	}

	public static function clampAmmo(value:Int):Int {
		return value < 0 ? 0 : (value > 3 ? 3 : value);
	}
}
