package pr2.page;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.display.StageQuality;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.level.ServerLevelRenderer;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Initial shell for Flash `levelEditor.LevelEditor`.

	The editor subsystems are ported incrementally; this owns the top-level
	lifecycle boundary Flash established before sidebars/tools attach.
**/
class LevelEditor extends Page {
	public static var editor:Null<LevelEditor>;
	public static inline var segSize:Float = 30;

	public final isMod:Bool;
	public var reportsMode(default, null):Bool;
	public var overlayLayer(default, null):Null<Sprite>;
	public var menu(default, null):Null<LevelEditorMenu>;
	public var selectedToolSidebar(default, null):String = "";
	public var selectedToolId(default, null):String = "";
	public var objectLayers(default, null):Array<EditorObjectLayer> = [];
	public var activeObjectLayer(default, null):Null<EditorObjectLayer>;
	private var layerContainer:Null<Sprite>;

	public function new(?variables:Dynamic, mod:Bool = false, report:Bool = false) {
		super();
		isMod = mod;
		reportsMode = report;
	}

	override public function initialize():Void {
		super.initialize();
		LevelEditor.editor = this;
		if (stage != null) {
			stage.quality = StageQuality.HIGH;
		}

		layerContainer = new Sprite();
		addChild(layerContainer);
		attachObjectLayers();
		addEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);

		overlayLayer = new Sprite();
		overlayLayer.mouseEnabled = false;
		overlayLayer.mouseChildren = false;

		menu = new LevelEditorMenu(this);
		menu.init();
		addChild(menu);
		menu.setReportsMode(reportsMode);
		addChild(overlayLayer);
	}

	public function setReportsMode(on:Bool = false):Void {
		reportsMode = on;
	}

	public function selectEditorTool(sidebar:String, toolId:String):Void {
		selectedToolSidebar = sidebar;
		selectedToolId = toolId;
	}

	public function setActiveObjectLayer(layerNum:Int):Void {
		if (layerNum < 1 || layerNum > objectLayers.length) {
			return;
		}
		activeObjectLayer = objectLayers[layerNum - 1];
	}

	public function placeSelectedToolAt(stageX:Float, stageY:Float):Null<EditorPlacedObject> {
		if (activeObjectLayer == null || selectedToolSidebar != "stamps" || !StringTools.startsWith(selectedToolId, "stamp")) {
			return null;
		}
		var code = Std.parseInt(selectedToolId.substr("stamp".length));
		if (code == null) {
			return null;
		}
		return activeObjectLayer.addStamp(code, stageX, stageY);
	}

	override public function remove():Void {
		if (LevelEditor.editor == this) {
			LevelEditor.editor = null;
		}
		removeEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);
		if (menu != null) {
			menu.remove();
			menu = null;
		}
		if (layerContainer != null) {
			for (layer in objectLayers) {
				layer.remove();
			}
			objectLayers = [];
			activeObjectLayer = null;
			layerContainer = null;
		}
		overlayLayer = null;
		super.remove();
	}

	private function attachObjectLayers():Void {
		if (layerContainer == null) {
			return;
		}
		for (scale in [1.0, 0.5, 0.25, 1.0, 2.0]) {
			var layer = new EditorObjectLayer(objectLayers.length + 1, scale);
			objectLayers.push(layer);
			layerContainer.addChild(layer);
		}
		activeObjectLayer = objectLayers[0];
	}

	private function placeSelectedToolFromMouse(event:MouseEvent):Void {
		if (menu != null && menu.hitTestPoint(event.stageX, event.stageY, true)) {
			return;
		}
		if (placeSelectedToolAt(event.stageX, event.stageY) != null) {
			event.stopImmediatePropagation();
		}
	}
}

class LevelEditorMenu extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	public final blocks:EditorSideBar;
	public final settings:EditorSideBar;
	public final stamps:EditorSideBar;
	public final tools:EditorSideBar;
	public final bg:EditorSideBar;
	public var sideBar(default, null):Null<EditorSideBar>;
	private var bindings:Array<Binding> = [];

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("LevelEditorMenuGraphic", {maxNestedDepth: 8});
		addChild(art);
		blocks = new EditorSideBar("blocks", ["delete", "basic1", "basic2", "basic3", "basic4", "brick", "finish", "ice", "item", "infItem", "left",
			"right", "up", "down", "teleport", "mine", "crumble", "vanish", "move", "water", "rotateR", "rotateL", "push", "happy", "sad",
			"custom", "safety", "heart", "time", "egg"]);
		settings = new EditorSideBar("settings", ["music", "items", "hats", "rank", "gravity", "time", "mode", "sfcm", "pass"]);
		stamps = new EditorSideBar("stamps", ["brush", "delete", "text", "stamp0", "stamp1", "stamp2", "stamp3", "stamp4", "stamp5", "stamp6",
			"stamp7", "stamp8", "stamp9"]);
		tools = new EditorSideBar("tools", ["landscape", "brush", "eraser", "size", "color"]);
		bg = new EditorSideBar("backgrounds", ["color", "bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "bg7"]);
	}

	public function init():Void {
		bind("blocksButton", clickBlocks);
		bind("settingsButton", clickSettings);
		bind("bgButton", clickBackgrounds);
		bind("layer00Button", function() setLayer(5));
		bind("layer0Button", function() setLayer(4));
		bind("layer1Button", function() setLayer(1));
		bind("layer2Button", function() setLayer(2));
		bind("layer3Button", function() setLayer(3));
		Reflect.setProperty(find("zoomSelect"), "selectedIndex", 3);
		if (pr2.lobby.LobbySession.group <= 0) {
			Reflect.setProperty(find("saveButton"), "enabled", false);
			Reflect.setProperty(find("loadButton"), "enabled", false);
		}
		reset();
	}

	public function setReportsMode(on:Bool = false):Void {
		Reflect.setProperty(find("saveButton"), "enabled", !on);
		editor.setReportsMode(on);
	}

	public function changeSideBar(next:EditorSideBar):Void {
		if (sideBar != null) {
			sideBar.exit();
		}
		sideBar = next;
		editor.selectEditorTool("", "");
		sideBar.init();
		addChild(sideBar);
	}

	public function reset():Void {
		clickBlocks();
		tools.exit();
	}

	public function remove():Void {
		for (binding in bindings) LobbyArt.unbind(binding);
		bindings = [];
		for (side in [blocks, settings, stamps, tools, bg]) {
			side.remove();
		}
		sideBar = null;
		art.dispose();
	}

	private function find(name:String):Dynamic {
		return pr2.util.DisplayUtil.findByName(art, name);
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickBlocks():Void {
		changeSideBar(blocks);
		moveGlow(find("blocksButton"));
	}

	private function clickSettings():Void {
		changeSideBar(settings);
		moveGlow(find("settingsButton"));
	}

	private function clickBackgrounds():Void {
		changeSideBar(bg);
		moveGlow(find("bgButton"));
	}

	private function setLayer(layerNum:Int):Void {
		if (sideBar != stamps && sideBar != tools) {
			changeSideBar(stamps);
		}
		editor.setActiveObjectLayer(layerNum);
		moveGlow(find(switch (layerNum) {
			case 5: "layer00Button";
			case 4: "layer0Button";
			case 1: "layer1Button";
			case 2: "layer2Button";
			case 3: "layer3Button";
			default: "layer1Button";
		}));
	}

	private function moveGlow(target:Null<DisplayObject>):Void {
		var glow = Std.downcast(find("selectedGlow"), DisplayObject);
		if (target == null || glow == null) {
			return;
		}
		glow.x = target.x + target.width / 2;
		glow.width = target.width + 6;
	}
}

class EditorObjectLayer extends Sprite {
	public final layerNum:Int;
	public final placedObjects:Array<EditorPlacedObject> = [];

	public function new(layerNum:Int, layerScale:Float) {
		super();
		this.layerNum = layerNum;
		name = 'editorObjectLayer$layerNum';
		scaleX = layerScale;
		scaleY = layerScale;
	}

	public function addStamp(code:Int, stageX:Float, stageY:Float):EditorPlacedObject {
		var size = stampDisplaySize(code);
		var point = globalToLocal(new Point(stageX, stageY));
		var placed = new EditorPlacedObject(code, Math.round(point.x - size.width / 2), Math.round(point.y - size.height / 2));
		placedObjects.push(placed);
		addChild(createStampDisplay(placed, size));
		return placed;
	}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
		while (numChildren > 0) {
			removeChildAt(0);
		}
		placedObjects.resize(0);
	}

	private static function createStampDisplay(placed:EditorPlacedObject, size:StampSize):Sprite {
		var holder = new Sprite();
		holder.x = placed.x;
		holder.y = placed.y;
		var assetPath = ServerLevelRenderer.stampAssetPath(placed.code);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = true;
			bitmap.scaleX = 0.25;
			bitmap.scaleY = 0.25;
			holder.addChild(bitmap);
		} else {
			holder.graphics.lineStyle(1, 0x666666);
			holder.graphics.beginFill(0xEEEEEE, 0.5);
			holder.graphics.drawRect(0, 0, size.width, size.height);
			holder.graphics.endFill();
		}
		return holder;
	}

	private static function stampDisplaySize(code:Int):StampSize {
		return switch (code) {
			case 0: new StampSize(228, 172.75);
			case 1: new StampSize(188, 249.25);
			case 2: new StampSize(194, 236.5);
			case 3: new StampSize(77.25, 101.75);
			case 5: new StampSize(87.25, 91);
			case 6: new StampSize(125.75, 118.5);
			case 7: new StampSize(114, 319.75);
			case 8: new StampSize(294.25, 268.5);
			default: new StampSize(30, 30);
		}
	}
}

class EditorPlacedObject {
	public final code:Int;
	public final x:Int;
	public final y:Int;

	public function new(code:Int, x:Int, y:Int) {
		this.code = code;
		this.x = x;
		this.y = y;
	}
}

private class StampSize {
	public final width:Float;
	public final height:Float;

	public function new(width:Float, height:Float) {
		this.width = width;
		this.height = height;
	}
}

class EditorSideBar extends Sprite {
	public final id:String;
	public var selectedEntry(default, null):Null<EditorSideBarEntry>;

	public function new(id:String, itemIds:Array<String>) {
		super();
		this.id = id;
		name = id + "SideBar";
		x = 222;
		y = -195;
		var itemY:Float = 4;
		for (itemId in itemIds) {
			var entry = new EditorSideBarEntry(itemId);
			entry.addEventListener(MouseEvent.CLICK, selectEntry);
			entry.y = itemY;
			addChild(entry);
			itemY += entry.height + 10;
		}
	}

	public function init():Void {}

	private function selectEntry(e:MouseEvent):Void {
		var entry = Std.downcast(e.currentTarget, EditorSideBarEntry);
		if (entry == null) {
			return;
		}
		if (selectedEntry != null) {
			selectedEntry.setSelected(false);
		}
		selectedEntry = entry;
		selectedEntry.setSelected(true);
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.selectEditorTool(id, entry.id);
		}
	}

	public function exit():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function remove():Void {
		exit();
		while (numChildren > 0) {
			var child = removeChildAt(0);
			child.removeEventListener(MouseEvent.CLICK, selectEntry);
		}
		selectedEntry = null;
	}
}

class EditorSideBarEntry extends Sprite {
	public final id:String;

	public function new(id:String) {
		super();
		this.id = id;
		name = id + "Entry";
		buttonMode = true;
		useHandCursor = true;
		draw(false);
		var label = new TextField();
		label.defaultTextFormat = new TextFormat("_sans", 6, 0x111111);
		label.width = 30;
		label.height = 30;
		label.selectable = false;
		label.mouseEnabled = false;
		label.text = id;
		addChild(label);
	}

	public function setSelected(selected:Bool):Void {
		draw(selected);
	}

	private function draw(selected:Bool):Void {
		graphics.clear();
		graphics.beginFill(0xF4F4F4);
		graphics.lineStyle(selected ? 2 : 1, selected ? 0x1F66CC : 0x666666);
		graphics.drawRect(0, 0, 30, 30);
		graphics.endFill();
	}
}
