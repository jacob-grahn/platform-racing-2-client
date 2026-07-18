package pr2.page;

import com.jiggmin.data.Objects;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import pr2.character.CharacterView;
import pr2.level.ObjectCodes;
#if pr2_legacy_preview
import pr2.character.CharacterDisplay;
import pr2.runtime.PR2MovieClip;
#end

/**
	Debug screen that renders a single library symbol through the vector
	renderer so its OpenFL output can be screenshotted and compared against the
	Adobe-exported PNG. Driven by `?screen=symbol&symbol=<name>&scale=<n>`.

	The symbol is drawn at `scale` (default 4, matching the `@4x` reference
	rasters) and its drawing bounds are aligned to a fixed inset so the capture
	rectangle is deterministic.
**/
class SymbolPreview extends Sprite {
	public static inline var INSET:Float = 10;

	public function new(symbolName:Null<String>, scale:Float, background:Int) {
		super();

		graphics.beginFill(background);
		graphics.drawRect(0, 0, 550, 400);
		graphics.endFill();

		if (symbolName == null || symbolName == "") {
			return;
		}

		var holder = new Sprite();
		var content = nativePreview(symbolName);
		#if pr2_legacy_preview
		holder.addChild(content == null ? PR2MovieClip.fromSymbolName(symbolName) : content);
		#else
		if (content == null) return;
		holder.addChild(content);
		#end
		holder.scaleX = scale;
		holder.scaleY = scale;
		addChild(holder);

		var bounds:Rectangle = holder.getBounds(this);
		holder.x = INSET - bounds.x;
		holder.y = INSET - bounds.y;
	}

	/** Native migration previews rendered beside their archival timeline equivalents. */
	private static function nativePreview(symbolName:String):Null<DisplayObject> {
		var nativeActionPrefix = "native-character:action-";
		if (StringTools.startsWith(symbolName, nativeActionPrefix)) {
			var route = symbolName.substr(nativeActionPrefix.length);
			var separator = route.lastIndexOf("-");
			var view = new CharacterView();
			view.setItemFrameName(routeItem(route.substr(0, separator)));
			var frame = Std.parseInt(route.substr(separator + 1));
			view.gotoItemActionFrame(frame == null ? 1 : frame);
			return view;
		}
		#if pr2_legacy_preview
		var legacyActionPrefix = "legacy-character:action-";
		if (StringTools.startsWith(symbolName, legacyActionPrefix)) {
			var route = symbolName.substr(legacyActionPrefix.length);
			var separator = route.lastIndexOf("-");
			var item = routeItem(route.substr(0, separator));
			var parsedFrame = Std.parseInt(route.substr(separator + 1));
			var frame = parsedFrame == null ? 1 : parsedFrame;
			var display = new CharacterDisplay(null, null, false);
			display.setItemFrameName(item);
			var state = display.getStateClip("standAnim");
			var weapon = state == null ? null : Std.downcast(state.getChildByTimelineName("weapon"), PR2MovieClip);
			var animation = weapon == null ? null : Std.downcast(weapon.getChildByTimelineName(item == "Laser" ? "gun" : "sword"), PR2MovieClip);
			if (animation != null) animation.gotoAndStop(frame);
			return display;
		}
		#end
		var nativeItemPrefix = "native-character:item-";
		if (StringTools.startsWith(symbolName, nativeItemPrefix)) {
			var view = new CharacterView();
			view.setItemFrameName(routeItem(symbolName.substr(nativeItemPrefix.length)));
			return view;
		}
		#if pr2_legacy_preview
		var legacyItemPrefix = "legacy-character:item-";
		if (StringTools.startsWith(symbolName, legacyItemPrefix)) {
			var display = new CharacterDisplay(null, null, false);
			display.setItemFrameName(routeItem(symbolName.substr(legacyItemPrefix.length)));
			return display;
		}
		#end
		var nativeFredPrefix = "native-character:fred-stack-";
		if (StringTools.startsWith(symbolName, nativeFredPrefix)) {
			var view = new CharacterView(0x55AAFF, 0xFFCC33, null, routeState(symbolName.substr(nativeFredPrefix.length)));
			view.setPartIds({head: 1, body: 29, feet: 1});
			view.setPartColor("body", 0x55AAFF, 0xFFCC33);
			view.setHatIds([6, 5, 13, 16]);
			view.setHatSlotColors([
				{primary: 0xFFD700, secondary: 0xAA5500},
				{primary: 0x663300, secondary: -1},
				{primary: 0x22CCEE, secondary: 0xFF44AA},
				{primary: 0xFFF099, secondary: 0xCC8800}
			]);
			return view;
		}
		#if pr2_legacy_preview
		var legacyFredPrefix = "legacy-character:fred-stack-";
		if (StringTools.startsWith(symbolName, legacyFredPrefix)) {
			var state = routeState(symbolName.substr(legacyFredPrefix.length));
			var display = new CharacterDisplay(null, null, false);
			display.setAppearance(
				{hat: 6, hats: [6, 5, 13, 16], head: 1, body: 29, feet: 1},
				{
					hats: [
						{primary: 0xFFD700, secondary: 0xAA5500},
						{primary: 0x663300, secondary: -1},
						{primary: 0x22CCEE, secondary: 0xFF44AA},
						{primary: 0xFFF099, secondary: 0xCC8800}
					],
					head: {primary: 0x55AAFF, secondary: 0xFFCC33},
					body: {primary: 0x55AAFF, secondary: 0xFFCC33},
					feet: {primary: 0x55AAFF, secondary: 0xFFCC33}
				}
			);
			display.setState(legacyClipName(state));
			return display;
		}
		#end
		var nativeHatPrefix = "native-character:hat-stack-";
		if (StringTools.startsWith(symbolName, nativeHatPrefix)) {
			var view = new CharacterView(0x2E8BFF, 0xFFD24A, null, routeState(symbolName.substr(nativeHatPrefix.length)));
			view.setPartIds({head: 23, body: 28, feet: 40});
			view.setHatIds([6, 5, 13, 16]);
			view.setHatSlotColors([
				{primary: 0xFFD700, secondary: 0xAA5500},
				{primary: 0x663300, secondary: -1},
				{primary: 0x22CCEE, secondary: 0xFF44AA},
				{primary: 0xFFF099, secondary: 0xCC8800}
			]);
			return view;
		}
		#if pr2_legacy_preview
		var legacyHatPrefix = "legacy-character:hat-stack-";
		if (StringTools.startsWith(symbolName, legacyHatPrefix)) {
			var state = routeState(symbolName.substr(legacyHatPrefix.length));
			var display = new CharacterDisplay(null, null, false);
			display.setAppearance(
				{hat: 6, hats: [6, 5, 13, 16], head: 23, body: 28, feet: 40},
				{
					hats: [
						{primary: 0xFFD700, secondary: 0xAA5500},
						{primary: 0x663300, secondary: -1},
						{primary: 0x22CCEE, secondary: 0xFF44AA},
						{primary: 0xFFF099, secondary: 0xCC8800}
					],
					head: {primary: 0x2E8BFF, secondary: 0xFFD24A},
					body: {primary: 0x2E8BFF, secondary: 0xFFD24A},
					feet: {primary: 0x2E8BFF, secondary: 0xFFD24A}
				}
			);
			display.setState(legacyClipName(state));
			return display;
		}
		#end
		var nativeStandardPrefix = "native-character:standard-a-";
		if (StringTools.startsWith(symbolName, nativeStandardPrefix)) {
			var view = new CharacterView(0x2E8BFF, 0xFFD24A, null, routeState(symbolName.substr(nativeStandardPrefix.length)));
			view.setAppearance(
				{head: 37, body: 28, feet: 40},
				{
					head: {primary: 0xAA00FF, secondary: 0x00CC11},
					body: {primary: 0x1177DD, secondary: 0xFF9900},
					feet: {primary: 0x22BB66, secondary: -1}
				}
			);
			return view;
		}
		#if pr2_legacy_preview
		var legacyStandardPrefix = "legacy-character:standard-a-";
		if (StringTools.startsWith(symbolName, legacyStandardPrefix)) {
			var state = routeState(symbolName.substr(legacyStandardPrefix.length));
			var display = new CharacterDisplay(null, null, false);
			display.setAppearance(
				{hat: 1, head: 37, body: 28, feet: 40},
				{
					hats: [],
					head: {primary: 0xAA00FF, secondary: 0x00CC11},
					body: {primary: 0x1177DD, secondary: 0xFF9900},
					feet: {primary: 0x22BB66, secondary: -1}
				}
			);
			display.setState(legacyClipName(state));
			return display;
		}
		#end
		var nativePrefix = "native-character:classic-";
		if (StringTools.startsWith(symbolName, nativePrefix)) {
			return new CharacterView(0x2E8BFF, 0xFFD24A, null, routeState(symbolName.substr(nativePrefix.length)));
		}
		#if pr2_legacy_preview
		var legacyPrefix = "legacy-character:classic-";
		if (StringTools.startsWith(symbolName, legacyPrefix)) {
			var state = routeState(symbolName.substr(legacyPrefix.length));
			var display = new CharacterDisplay(null, null, false);
			display.setState(legacyClipName(state));
			return display;
		}
		#end
		return switch (symbolName) {
			case "native-stamp:Cactus": Objects.getFromCode(ObjectCodes.STAMP_CACTUS);
			case "native-stamp:Building1": Objects.getFromCode(ObjectCodes.STAMP_BUILDING1);
			default: null;
		}
	}

	private static function routeState(route:String):String {
		return switch (route) {
			case "standing": "stand";
			case "super-jump": "superJump";
			case "crouch-walk": "crouchWalk";
			default: route;
		}
	}

	private static function routeItem(route:String):String {
		return switch (route) {
			case "super-jump": "Super Jump";
			case "jet-pack": "Jet Pack";
			case "speed-burst": "Speed Burst";
			case "ice-wave": "Ice Wave";
			default: route.charAt(0).toUpperCase() + route.substr(1);
		}
	}

	private static function legacyClipName(state:String):String {
		return switch (state) {
			case "superJump": "superJumpAnim";
			case "crouchWalk": "crouchWalkAnim";
			case "frozen": "frozenSolidAnim";
			default: state + "Anim";
		}
	}
}
