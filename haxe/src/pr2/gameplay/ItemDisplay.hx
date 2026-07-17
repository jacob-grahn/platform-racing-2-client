package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;
import pr2.display.Removable;
import pr2.runtime.FontResolver;
import pr2.util.DisplayUtil;

/**
	Port of Flash `gameplay.ItemDisplay`.

	The authored timeline contains one labelled frame per item. The two nested
	text holders form the dark/light item-name treatment, while `a1`-`a3` are
	the ammo dots.
**/
class ItemDisplay extends Removable {
	private var art:Null<ItemDisplayView>;
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
		art = new ItemDisplayView();
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
		art.showItem(name == "Snake" ? "None" : name);
		snakeIcon.visible = name == "Snake";
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
			if (art.parent != null) art.parent.removeChild(art);
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

private class ItemDisplayView extends Sprite {
	private final icon:Shape;
	private var assetBitmap:Null<Bitmap>;

	public function new() {
		super();
		graphics.beginFill(0x292929, 0.86);
		graphics.lineStyle(1, 0x111111);
		graphics.drawRoundRect(0, 0, 106, 73, 9, 9);
		graphics.endFill();
		icon = new Shape();
		icon.x = 18;
		icon.y = 11;
		addChild(icon);
		for (index in 1...4) {
			var dot = new Shape();
			dot.name = "a" + index;
			dot.x = 78 + index * 6;
			dot.y = 8;
			dot.graphics.beginFill(0xFFE15A);
			dot.graphics.lineStyle(1, 0x8A7116);
			dot.graphics.drawCircle(0, 0, 2.5);
			dot.graphics.endFill();
			addChild(dot);
		}
	}

	public function showItem(name:String):Void {
		if (assetBitmap != null) {
			if (assetBitmap.parent != null) assetBitmap.parent.removeChild(assetBitmap);
			assetBitmap = null;
		}
		icon.graphics.clear();
		if (name == "None") return;
		if (name == "Mine") {
			try {
				assetBitmap = new Bitmap(Assets.getBitmapData("assets/blocks/mine_block.png"));
				assetBitmap.x = 20;
				assetBitmap.y = 11;
				addChild(assetBitmap);
				return;
			} catch (_:Dynamic) {}
		}
		var color = switch (name) {
			case "Laser": 0xEF4242;
			case "Mine": 0x424242;
			case "Lightning": 0xF6D73B;
			case "Teleport": 0x9B62E8;
			case "Super Jump": 0x55B8F0;
			case "Jet Pack": 0xE9853E;
			case "Speed Burst": 0x55D589;
			case "Sword": 0xC8D2DB;
			case "Ice Wave": 0x8DE6F4;
			default: 0xFFFFFF;
		};
		icon.graphics.lineStyle(2, 0x222222);
		icon.graphics.beginFill(color);
		switch (name) {
			case "Lightning":
				icon.graphics.moveTo(25, 0);
				icon.graphics.lineTo(8, 22);
				icon.graphics.lineTo(21, 22);
				icon.graphics.lineTo(12, 40);
				icon.graphics.lineTo(38, 15);
				icon.graphics.lineTo(24, 15);
				icon.graphics.lineTo(25, 0);
			case "Sword":
				icon.graphics.moveTo(33, 1);
				icon.graphics.lineTo(22, 31);
				icon.graphics.lineTo(17, 26);
				icon.graphics.lineTo(33, 1);
				icon.graphics.drawRect(9, 29, 19, 4);
			case "Mine": icon.graphics.drawCircle(23, 22, 16);
			default: icon.graphics.drawRoundRect(3, 4, 42, 35, 9, 9);
		}
		icon.graphics.endFill();
	}
}
