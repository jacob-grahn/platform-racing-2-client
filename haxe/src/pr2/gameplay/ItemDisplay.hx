package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import pr2.animation.TimelineClip;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.display.Removable;
import pr2.runtime.FontResolver;
import pr2.runtime.SvgAsset;
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
		addEventListener(Event.ENTER_FRAME, advanceItemArt);
		darkLabel = createLabel(2, 55, 0x000000);
		lightLabel = createLabel(3, 56, 0xFFFFFF);
		addChild(darkLabel);
		addChild(lightLabel);
		snakeIcon = createSnakeIcon();
		addChild(snakeIcon);
		setItemCode(0);
	}

	private function advanceItemArt(_:Event):Void {
		if (art != null) art.advanceFrame();
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
			var dot = DisplayUtil.directChildByName(art, "a" + index);
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
		var dot:Null<DisplayObject> = DisplayUtil.directChildByName(art, "a" + index);
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
		removeEventListener(Event.ENTER_FRAME, advanceItemArt);
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
	public final timeline:TimelineClip;
	private var frameStart:Int = 1;
	private var frameSpan:Int = 5;
	private var frameOffset:Int = 0;

	public function new() {
		super();
		timeline = new TimelineClip("assets/effects/item_display.lottie.json");
		timeline.stop();
		addChild(timeline);
		redraw();
		for (index in 1...4) {
			var dot = SvgAsset.create('assets/svg/effects/item_ammo_${StringTools.lpad(Std.string(index), "0", 2)}.svg');
			dot.name = "a" + index;
			addChild(dot);
		}
	}

	public function showItem(name:String):Void {
		frameStart = switch (name) {
			case "Jet Pack": 6;
			case "Mine": 11;
			case "Speed Burst": 16;
			case "Super Jump": 21;
			case "Teleport": 26;
			case "Lightning": 31;
			case "Laser": 36;
			case "Sword": 41;
			case "Ice Wave": 46;
			default: 1;
		};
		frameSpan = name == "Ice Wave" ? 6 : 5;
		frameOffset = 0;
		redraw();
	}

	public function advanceFrame():Void {
		frameOffset = (frameOffset + 1) % frameSpan;
		redraw();
	}

	private function redraw():Void {
		timeline.gotoAndStop(frameStart + frameOffset);
	}
}
