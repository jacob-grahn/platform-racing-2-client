package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import pr2.levelEditor.EditorSideBarCatalog.EditorSideBarHoverInfo;
import pr2.ui.CustomScrollBar;
import pr2.util.DisplayUtil;

class EditorSideBar extends Sprite {
	public final id:String;
	public var selectedEntry(default, null):Null<EditorSideBarEntry>;
	public var zoom(default, null):Float = 1;
	private var scrollBar:CustomScrollBar;
	private var scroll:Sprite;
	private var scrollMask:Sprite;
	private var posY:Float = 0;
	private static inline final ITEM_GAP:Float = 10;
	private static inline final MASK_WIDTH:Float = 30;
	private static inline final MASK_HEIGHT:Float = 348;

	public function new(id:String, itemIds:Array<String>) {
		super();
		this.id = id;
		name = id + "SideBar";
		x = 222;
		y = -195;
		scrollBar = new CustomScrollBar();
		scroll = new Sprite();
		scrollMask = new Sprite();
		addChild(scrollBar);
		addChild(scroll);
		addChild(scrollMask);
		scroll.y = 4;
		scrollBar.x = 35;
		scrollBar.y = 2;
		scrollBar.init(scroll, 348, 346);
		drawScrollMask();
		for (itemId in itemIds) {
			var hover = hoverInfo(id, itemId);
			var entry = if (id == "backgrounds" && itemId == "color") {
				new EditorBackgroundColorPickerButton(hover.title, hover.desc);
			} else if (id == "tools" && itemId == "size") {
				new EditorBrushSizePickerButton(hover.title, hover.desc);
			} else if (id == "tools" && itemId == "color") {
				new EditorBrushColorPickerButton(hover.title, hover.desc);
			} else {
				new EditorSideBarEntry(itemId, hover.title, hover.desc, EditorSideBarIconFactory.create(id, itemId));
			}
			entry.addEventListener(MouseEvent.CLICK, selectEntry);
			entry.y = posY;
			scroll.addChild(entry);
			posY += MASK_WIDTH + ITEM_GAP;
		}
	}

	private function drawScrollMask():Void {
		scrollMask.graphics.beginFill(0);
		scrollMask.graphics.drawRect(0, 2, MASK_WIDTH, MASK_HEIGHT);
		scrollMask.graphics.endFill();
		scroll.mask = scrollMask;
	}

	public function init():Void {
		if (id != "tools") {
			return;
		}
		var brushEntry = Std.downcast(getChildByName("brushEntry"), EditorSideBarEntry);
		if (brushEntry != null) {
			if (selectedEntry != null) {
				selectedEntry.setSelected(false);
			}
			selectedEntry = brushEntry;
			selectedEntry.setSelected(true);
		}
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.selectEditorTool("tools", "brush");
		}
	}

	public function setZoom(nextZoom:Float):Void {
		if (!Math.isNaN(nextZoom) && nextZoom > 0) {
			zoom = nextZoom;
		}
	}

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
		if (editor != null && id == "stamps" && entry.id == "brush" && editor.menu != null) {
			editor.menu.changeSideBar(editor.menu.tools);
			editor.focusOnActiveDrawLayer();
			return;
		}
		if (editor != null && id == "tools" && entry.id == "landscape" && editor.menu != null) {
			editor.menu.changeSideBar(editor.menu.stamps);
			editor.focusOnActiveObjectLayer();
			return;
		}
		if (editor != null && id == "tools" && entry.id == "size") {
			var sizeEntry = Std.downcast(entry, EditorBrushSizePickerButton);
			if (sizeEntry != null) {
				sizeEntry.openMenu();
			}
			return;
		}
		if (editor != null && id == "tools" && entry.id == "color") {
			return;
		}
		if (editor != null && id == "backgrounds") {
			var bgSpec = backgroundSpec(entry.id);
			if (bgSpec != null) {
				editor.selectArtBackground(bgSpec.code, bgSpec.color);
				return;
			}
		}
		if (editor != null && id == "settings" && entry.id == "items") {
			editor.openItemSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && entry.id == "hats") {
			editor.openHatsSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && entry.id == "music") {
			editor.openMusicSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && entry.id == "mode") {
			editor.openModeSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && EditorValueSettingsPopup.handles(entry.id)) {
			editor.openValueSettingsMenu(entry.id, entry);
			return;
		}
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
		while (scroll.numChildren > 0) {
			var child = scroll.getChildAt(0);
			child.removeEventListener(MouseEvent.CLICK, selectEntry);
			var entry = Std.downcast(child, EditorSideBarEntry);
			if (entry != null) {
				entry.remove();
			} else {
				scroll.removeChildAt(0);
			}
		}
		scrollBar.remove();
		if (scroll.parent == this) removeChild(scroll);
		if (scrollMask.parent == this) removeChild(scrollMask);
		selectedEntry = null;
	}

	public function updateColor():Void {
		for (i in 0...scroll.numChildren) {
			var colorEntry = Std.downcast(scroll.getChildAt(i), EditorBackgroundColorPickerButton);
			if (colorEntry != null) {
				colorEntry.updateColor();
			}
		}
	}

	public function setEntryValue(itemId:String, value:String):Void {
		var entry = Std.downcast(getChildByName(itemId + "Entry"), EditorSideBarEntry);
		if (entry != null) {
			entry.setDisplayedValue(value);
		}
	}

	override public function getChildByName(name:String):DisplayObject {
		var direct = super.getChildByName(name);
		return direct != null ? direct : DisplayUtil.directChildByName(scroll, name);
	}

	public function scrollHolderForTests():Sprite {
		return scroll;
	}

	public function scrollBarForTests():CustomScrollBar {
		return scrollBar;
	}

	public function scrollMaskForTests():Sprite {
		return scrollMask;
	}

	public function itemGapForTests():Float {
		return ITEM_GAP;
	}

	public function maskWidthForTests():Float {
		return MASK_WIDTH;
	}

	public function maskHeightForTests():Float {
		return MASK_HEIGHT;
	}

	private static function hoverInfo(sidebar:String, itemId:String):EditorSideBarHoverInfo {
		return EditorSideBarCatalog.hoverInfo(sidebar, itemId);
	}

	public static function backgroundSpec(itemId:String):Null<{code:Int, color:Int}> {
		return EditorSideBarCatalog.backgroundSpec(itemId);
	}
}
