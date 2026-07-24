package pr2.gameplay;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.DropShadowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.character.CharacterRig;
import pr2.character.CharacterRig.CharacterRigDefinition;
import pr2.character.CharacterRig.RigPartChannels;
import pr2.character.CharacterRig.RigPartKind;
import pr2.runtime.FontResolver;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact XFL prize shell with native dynamic fields and source-derived part channels. */
class PrizePopupView extends NativeView {
	private final partSymbols:Array<PrizePartSymbol> = [];

	public function new() {
		super();
		var flavorBg = createFlavorPanel();
		flavorBg.name = "flavorBg";
		flavorBg.x = 95.4;
		flavorBg.y = 49.95;
		addChild(flavorBg);
		field("flavor", 103.95, 60, 152, 51.95, 10, false);
		var bg = createPanel(172.9, 180.95, 2, 2, 3);
		bg.name = "bg";
		bg.x = 95.4;
		bg.y = -138.1;
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
		partSymbols.push(symbol);
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
		text.multiline = height > 18;
		text.wordWrap = text.multiline;
		text.embedFonts = true;
		text.defaultTextFormat = new TextFormat(FontResolver.resolve(bold ? "Verdana-Bold" : "Verdana"), size, 0x000000, false, null, null, null,
			null, TextFormatAlign.CENTER);
		parent.addChild(text);
		return text;
	}

	private function createFlavorPanel():Sprite {
		return createPanel(172.9, 63.05, 1, 2, 2);
	}

	/**
		Recreates UI/ShadowBG from its XFL geometry. The exported SVG contains the
		filter's hidden source object as opaque white, which erases the intended
		90%-opaque panel and level-background show-through.
	**/
	private function createPanel(width:Float, height:Float, shadowDistance:Float, shadowBlurX:Float, shadowBlurY:Float):Sprite {
		var panel = new Sprite();
		var fill = new Shape();
		fill.graphics.beginFill(0xFFFFFF, 0.9);
		fill.graphics.moveTo(4, 0);
		fill.graphics.lineTo(width - 4, 0);
		fill.graphics.curveTo(width, 0, width, 4);
		fill.graphics.lineTo(width, height);
		fill.graphics.lineTo(0, height);
		fill.graphics.lineTo(0, 4);
		fill.graphics.curveTo(0, 0, 4, 0);
		fill.graphics.endFill();
		fill.filters = [new DropShadowFilter(shadowDistance, 90, 0x000000, 0.6, shadowBlurX, shadowBlurY, 1, 2)];
		panel.addChild(fill);
		return panel;
	}

	override public function dispose():Void {
		for (symbol in partSymbols) symbol.dispose();
		partSymbols.resize(0);
		super.dispose();
	}
}

class PrizePartSymbol extends Sprite {
	private static var cachedRig:Null<CharacterRigDefinition>;
	public var currentFrame(default, null):Int = 1;
	public final colorMC:PrizePartSymbolChannel;
	public final colorMC2:PrizePartSymbolChannel;
	private final kind:String;
	private var fixed:Null<Shape>;
	private var overlay:Null<Sprite>;
	private var overlayFrames:Array<String> = [];
	public var overlayCurrentFrame(default, null):Int = 0;

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
		var part = partKind();
		var variant = findVariant(part, frame);
		var registration = kind == "hat" ? {x: 0.0, y: 0.0} : part.registration;
		if (fixed != null && fixed.parent == this) removeChild(fixed);
		fixed = SvgAsset.create(variant.fixed);
		fixed.name = "static";
		fixed.x = registration.x;
		fixed.y = registration.y;
		// Character parts are authored primary -> fixed line/detail art ->
		// secondary. Keep the same stacking order used by CharacterView.
		addChildAt(fixed, 1);
		colorMC.x = colorMC2.x = registration.x;
		colorMC.y = colorMC2.y = registration.y;
		colorMC.setAsset(variant.primary, frame);
		colorMC2.setAsset(variant.secondary, frame);
		setOverlay(variant, registration.x, registration.y);
	}

	private function setOverlay(variant:RigPartChannels, registrationX:Float, registrationY:Float):Void {
		removeEventListener(Event.ENTER_FRAME, advanceOverlay);
		if (overlay != null && overlay.parent == this) removeChild(overlay);
		overlay = null;
		overlayFrames = [];
		overlayCurrentFrame = 0;
		if (variant.overlayAnimation == null || variant.overlayAnimation.frames.length == 0) return;
		overlayFrames = variant.overlayAnimation.frames.copy();
		overlay = new Sprite();
		overlay.name = "animatedOverlay";
		overlay.x = registrationX;
		overlay.y = registrationY;
		addChild(overlay);
		renderOverlayFrame();
		addEventListener(Event.ENTER_FRAME, advanceOverlay);
	}

	private function advanceOverlay(_:Event):Void {
		stepOverlay();
	}

	private function stepOverlay():Void {
		if (overlayFrames.length == 0) return;
		overlayCurrentFrame = (overlayCurrentFrame + 1) % overlayFrames.length;
		renderOverlayFrame();
	}

	private function renderOverlayFrame():Void {
		if (overlay == null || overlayFrames.length == 0) return;
		while (overlay.numChildren > 0) overlay.removeChildAt(0);
		var art = SvgAsset.create(overlayFrames[overlayCurrentFrame]);
		art.name = "vectorFrame";
		overlay.addChild(art);
	}

	public function advanceOverlayFrameForTests():Void stepOverlay();

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advanceOverlay);
		overlayFrames = [];
		if (overlay != null && overlay.parent == this) removeChild(overlay);
		overlay = null;
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
