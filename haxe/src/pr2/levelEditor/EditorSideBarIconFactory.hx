package pr2.levelEditor;

import com.jiggmin.data.Objects;
import openfl.display.DisplayObject;
import pr2.level.ObjectCodes;
import pr2.levelEditor.EditorBlockLayer;
import pr2.runtime.FlComponents;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Builds the visual content used by level-editor sidebar entries.

	Keeping asset lookup and fitting here leaves `EditorSideBar` responsible for
	selection and interaction only. The factory deliberately returns display
	objects rather than sidebar entries so it has no ownership of listeners or
	editor state.
**/
class EditorSideBarIconFactory {
	private static inline final ICON_BOX:Float = 24;
	private static inline final ICON_OFFSET:Float = 3;

	private function new() {}

	public static function create(sidebar:String, itemId:String):Null<DisplayObject> {
		return switch (sidebar + ":" + itemId) {
			case "blocks:delete" | "stamps:delete": linkage("ObjectDeleterButtonGraphic");
			case "settings:music": linkage("MusicNoteGraphic");
			case "settings:items": linkage("ItemButtonGraphic");
			case "settings:hats": linkage("HatsButtonGraphic");
			case "settings:rank": valueButton("rank", "0");
			case "settings:gravity": valueButton("grav", "1.0");
			case "settings:time": valueButton("time", "120");
			case "settings:mode": valueButton("mode", "race");
			case "settings:sfcm": valueButton("sfcm", "5");
			case "settings:pass": valueButton("pass", "");
			case "stamps:brush": linkage("BrushGraphic");
			case "stamps:text": linkage("TextToolButtonGraphic");
			case "tools:landscape": linkage("LandscapeGraphic");
			case "tools:brush": linkage("BrushButtonGraphic");
			case "tools:eraser": linkage("EraserButtonGraphic");
			case "backgrounds:bg1": fittedCode(ObjectCodes.BG1Code);
			case "backgrounds:bg2": fittedCode(ObjectCodes.BG2Code);
			case "backgrounds:bg3": fittedCode(ObjectCodes.BG3Code);
			case "backgrounds:bg4": fittedCode(ObjectCodes.BG4Code);
			case "backgrounds:bg5": fittedCode(ObjectCodes.BG5Code);
			case "backgrounds:bg6": fittedCode(ObjectCodes.BG6Code);
			case "backgrounds:bg7": fittedCode(ObjectCodes.BG7Code);
			case _ if (sidebar == "blocks"):
				var spec = EditorBlockLayer.specForTool(itemId);
				spec == null ? null : Objects.getFromCode(spec.code);
			case _ if (sidebar == "stamps" && StringTools.startsWith(itemId, "stamp")):
				var stampId = Std.parseInt(itemId.substr(5));
				stampId == null ? null : stampIcon(stampId);
			default:
				null;
		}
	}

	private static function linkage(name:String):PR2MovieClip {
		var clip = PR2MovieClip.fromLinkage(name, {maxNestedDepth: 6});
		clip.name = name;
		return clip;
	}

	private static function fittedCode(code:Int):Null<DisplayObject> {
		var icon = Objects.getFromCode(code);
		if (icon != null) {
			fit(icon);
		}
		return icon;
	}

	private static function stampIcon(code:Int):Null<DisplayObject> {
		var icon = Objects.getFromCode(code);
		if (icon == null) {
			return null;
		}
		icon.name = stampLinkageName(code);
		fit(icon);
		return icon;
	}

	private static function stampLinkageName(code:Int):String {
		return switch (code) {
			case ObjectCodes.STAMP_TREE: "Tree";
			case ObjectCodes.STAMP_TREE2: "Tree2";
			case ObjectCodes.STAMP_TREE3: "Tree3";
			case ObjectCodes.STAMP_PETRIFIED_TREE: "PetrifiedTree";
			case ObjectCodes.STAMP_CACTUS: "Cactus";
			case ObjectCodes.STAMP_ROCK: "Rock";
			case ObjectCodes.STAMP_ROCK2: "Rock2";
			case ObjectCodes.STAMP_SPIRE: "Spire";
			case ObjectCodes.STAMP_SPIRE2: "Spire2";
			case ObjectCodes.STAMP_BUILDING1: "Building1";
			default: 'Stamp$code';
		}
	}

	private static function fit(icon:DisplayObject):Void {
		var bounds = icon.getBounds(icon);
		var visualWidth = Math.abs(icon.width);
		var visualHeight = Math.abs(icon.height);
		if (visualWidth <= 0 || visualHeight <= 0 || bounds.width <= 0 || bounds.height <= 0) {
			icon.x = ICON_OFFSET;
			icon.y = ICON_OFFSET;
			return;
		}
		// Raster stamps are exported at a higher bitmap resolution and scaled to
		// their authored Flash dimensions. `getBounds(icon)` reports those source
		// pixels, whereas width/height report the actual displayed footprint.
		var scale = Math.min(ICON_BOX / visualWidth, ICON_BOX / visualHeight);
		icon.scaleX *= scale;
		icon.scaleY *= scale;
		var fittedWidth = bounds.width * Math.abs(icon.scaleX);
		var fittedHeight = bounds.height * Math.abs(icon.scaleY);
		icon.x = ICON_OFFSET + (ICON_BOX - fittedWidth) / 2 - bounds.left * icon.scaleX;
		icon.y = ICON_OFFSET + (ICON_BOX - fittedHeight) / 2 - bounds.top * icon.scaleY;
	}

	private static function valueButton(title:String, value:String):PR2MovieClip {
		var clip = linkage("ValueButtonGraphic");
		var titleBox = FlComponents.asTextField(DisplayUtil.findByName(clip, "titleBox"));
		if (titleBox != null) {
			titleBox.text = title;
		}
		var valueBox = FlComponents.asTextField(DisplayUtil.findByName(clip, "valueBox"));
		if (valueBox != null) {
			valueBox.text = value;
		}
		return clip;
	}
}
