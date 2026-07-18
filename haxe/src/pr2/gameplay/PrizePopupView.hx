package pr2.gameplay;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.character.CharacterRig;
import pr2.character.CharacterRig.CharacterRigDefinition;
import pr2.character.CharacterRig.RigPartChannels;
import pr2.character.CharacterRig.RigPartKind;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact XFL prize shell with native dynamic fields and source-derived part channels. */
class PrizePopupView extends NativeView {
	public static inline final BG_ASSET = "assets/svg/effects/prize_bg_01.svg";
	public static inline final FLAVOR_BG_ASSET = "assets/svg/effects/prize_flavor_bg_01.svg";

	public function new() {
		super();
		var flavorBg = SvgAsset.create(FLAVOR_BG_ASSET);
		flavorBg.name = "flavorBg";
		addChild(flavorBg);
		field("flavor", 103.95, 60, 152, 51.95, 10, false);
		var bg = SvgAsset.create(BG_ASSET);
		bg.name = "bg";
		addChild(bg);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = 144;
		close.y = 8.45;
		close.setSize(72, 22);
		addChild(close);
		field("titleBox", 101, -87, 162, 14.55, 12, true);
		field("textBox", 101, -129.05, 161.95, 38.05, 12, false);
		part("head", "head", 169.25, -67.3, 0.340484619140625, 0.1142578125, true);
		part("body", "body", 168.65, -60.4, 0.377639770507812, 0, false);
		part("foot", "feet", 158.3, -38.55, 0.800445556640625, 0, false);
		part("hat", "hat", 184.15, -10.75, 0.538116455078125, 0, false);
		var exp = new Sprite();
		exp.name = "exp";
		exp.x = 115.4;
		exp.y = -70;
		fieldOn(exp, "textBox", -1.05, 11.95, 125, 68.75, 10, false);
		addChild(exp);
	}

	private function part(name:String, kind:String, x:Float, y:Float, a:Float, b:Float, withHats:Bool):Void {
		var symbol = new PrizePartSymbol(kind, withHats);
		symbol.name = name;
		symbol.x = x;
		symbol.y = y;
		symbol.scaleX = symbol.scaleY = Math.sqrt(a * a + b * b);
		symbol.rotation = Math.atan2(b, a) * 180 / Math.PI;
		addChild(symbol);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool):TextField {
		return fieldOn(this, name, x, y, width, height, size, bold);
	}

	private function fieldOn(parent:Sprite, name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat("Verdana", size, 0x000000, bold, null, null, null, null, TextFormatAlign.CENTER);
		parent.addChild(text);
		return text;
	}
}

class PrizePartSymbol extends Sprite {
	private static var cachedRig:Null<CharacterRigDefinition>;
	public var currentFrame(default, null):Int = 1;
	public final colorMC:PrizePartSymbolChannel;
	public final colorMC2:PrizePartSymbolChannel;
	private final kind:String;
	private var fixed:Null<Shape>;

	public function new(kind:String, withHats:Bool = false) {
		super();
		this.kind = kind;
		colorMC = new PrizePartSymbolChannel();
		colorMC.name = "colorMC";
		addChild(colorMC);
		colorMC2 = new PrizePartSymbolChannel();
		colorMC2.name = "colorMC2";
		addChild(colorMC2);
		if (withHats) {
			for (i in 1...5) {
				var hat = new Sprite();
				hat.name = "hat" + i;
				addChild(hat);
			}
		}
		setPartFrame(1);
	}

	public function setPartFrame(frame:Int):Void {
		currentFrame = frame;
		var variant = findVariant(partKind(), frame);
		if (fixed != null && fixed.parent == this) removeChild(fixed);
		fixed = SvgAsset.create(variant.fixed);
		addChildAt(fixed, 0);
		colorMC.setAsset(variant.primary, frame);
		colorMC2.setAsset(variant.secondary, frame);
	}

	private function partKind():RigPartKind {
		var rig = classicRig();
		return switch (kind) {
			case "hat": rig.parts.hat;
			case "head": rig.parts.head;
			case "body": rig.parts.body;
			default: rig.parts.feet;
		};
	}

	private static function classicRig():CharacterRigDefinition {
		if (cachedRig == null) cachedRig = CharacterRig.loadClassic();
		return cachedRig;
	}

	private static function findVariant(kind:RigPartKind, id:Int):RigPartChannels {
		for (variant in kind.variants) if (variant.id == id) return variant;
		return kind.variants[0];
	}
}

class PrizePartSymbolChannel extends Sprite {
	public var currentFrame(default, null):Int = 1;
	private var art:Null<Shape>;

	public function new() super();

	public function setAsset(asset:String, frame:Int):Void {
		currentFrame = frame;
		if (art != null && art.parent == this) removeChild(art);
		art = SvgAsset.create(asset);
		addChild(art);
	}

	public function setPartFrame(frame:Int):Void currentFrame = frame;
}
