package pr2.mobile;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.geom.Point;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import pr2.app.AppStage;
import pr2.app.ScreenFactory;
import pr2.audio.MusicCatalog;
import pr2.gameplay.Items;
import pr2.level.BlockType;
import pr2.levelEditor.EditorBlockObject;
import pr2.levelEditor.EditorLevelService;
import pr2.levelEditor.EditorReportService;
import pr2.levelEditor.EditorSideBarCatalog;
import pr2.levelEditor.LevelEditor;
import pr2.lobby.LobbySession;
import pr2.net.ServerLevelData;
import pr2.page.EditorBlockOptions;
import pr2.mobile.MobileAuthControls.AuthInput;

/** Landscape editor presentation. The original LevelEditor still owns all course data and edits. */
class MobileLevelEditorPage extends LevelEditor {
	private static inline var INK:Int = 0x18334B;
	private static inline var NAVY:Int = 0x10283C;
	private static inline var LIME:Int = 0xD1ED62;
	private static inline var PAPER:Int = 0xF3F8FA;
	private static inline var MUTED:Int = 0x50687A;
	private final viewport = new Sprite();
	private final canvasContent = new Sprite();
	private final view = new LobbyView();
	private var scroll:Null<MobileScrollPane>;
	private var extraScroll:Null<MobileScrollPane>;
	private var screen = "canvas";
	private var mode = "blocks";
	private var activeLayerLabel = "Art 1";
	private var panMode = false;
	private var panDragging = false;
	private var panX:Float;
	private var panY:Float;
	private var w:Float = 844;
	private var h:Float = 390;
	private var inset:Float = 44;
	private var canvasW:Float = 560;
	private var canvasH:Float = 252;
	private var paletteW:Float = 184;
	private var selectedBlockTool = "basic1";
	private var selectedArtTool = "brush";
	private var ruleId = "";
	private var gearKind = "items";
	private var catalogCategory = "all";
	private var selectedLevel:Dynamic;
	private var levels:Array<Dynamic> = [];
	private var reports:Array<Dynamic> = [];
	private var selectedReport:Dynamic;
	private var reportReason = "";
	private var reportDuration = 0;
	private var reportBanApplied = false;
	private var selectedOptionsBlock:Null<EditorBlockObject>;
	private var optionItems:Array<Int> = [];
	private var message = "";
	private var busy = false;
	private var requestGeneration = 0;
	private var savedSignature = "";
	private var initialSignature:Null<String>;
	private var draftTitle = "";
	private var draftNote = "";
	private var draftPublish = false;
	private var draftNewest = false;
	private var titleInput:Null<AuthInput>;
	private var noteInput:Null<AuthInput>;
	private var valueInput:Null<AuthInput>;
	private var advancedPicker:Null<pr2.lobby.account.ColorPickerSurface>;
	private var returnAfterSave:Null<Void->Void>;
	private var confirmReturnScreen = "canvas";
	private var confirmationOfferSave = true;
	private var touches = new Map<Int, Point>();
	private var gestureCenter:Null<Point>;
	private var gestureDistance = 0.0;
	private var gestureZoom = 1.0;

	public function new(?variables:Map<String, String>, isMod:Bool = false, reportsMode:Bool = false, ?draftSignature:String) {
		super(variables, isMod, reportsMode);
		fullViewport = true;
		initialSignature = draftSignature;
	}

	override public function initialize():Void {
		super.initialize();
		if (menu != null) menu.visible = false;
		var canvasChildren:Array<DisplayObject> = [];
		for (i in 0...numChildren) {
			var child = getChildAt(i);
			if (child != menu && child != overlayLayer) canvasChildren.push(child);
		}
		for (child in canvasChildren) canvasContent.addChild(child);
		viewport.addChild(canvasContent);
		addChildAt(viewport, 0);
		addChild(view);
		mobileChrome = view;
		mobileBlockOptions = showBlockOptions;
		setMode("blocks");
		savedSignature = initialSignature == null ? signature() : initialSignature;
		if (AppStage.stage != null) AppStage.stage.addEventListener(Event.RESIZE, layout);
		viewport.addEventListener(MouseEvent.MOUSE_DOWN, canvasDown);
		viewport.addEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(TouchEvent.TOUCH_MOVE, touchMove);
			AppStage.stage.addEventListener(TouchEvent.TOUCH_END, touchEnd);
			AppStage.stage.addEventListener(Event.DEACTIVATE, cancelGesture);
		}
		#if (js && html5)
		js.Browser.window.addEventListener("touchcancel", browserCancelGesture);
		js.Browser.window.addEventListener("blur", browserCancelGesture);
		js.Browser.document.addEventListener("visibilitychange", browserCancelGesture);
		#end
		layout();
	}

	private function layout(?_:Event):Void {
		w = AppStage.stage == null ? 844 : AppStage.stage.stageWidth;
		h = AppStage.stage == null ? 390 : AppStage.stage.stageHeight;
		inset = w >= 760 ? 44 : 16;
		paletteW = w >= 760 ? 184 : 170;
		canvasW = Math.max(220, w - inset * 2 - paletteW - 12);
		canvasH = Math.max(160, h - 138);
		viewport.x = inset;
		viewport.y = 66;
		viewport.scrollRect = new Rectangle(0, 0, canvasW, canvasH);
		canvasContent.x = (canvasW - 550) / 2;
		canvasContent.y = (canvasH - 400) / 2;
		mobileCanvasBounds = new Rectangle(inset, 66, canvasW, canvasH);
		if (toolCursor != null) toolCursor.refreshMobileVisibility();
		graphics.clear();
		graphics.beginFill(NAVY);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		render();
	}

	private function signature():String {
		return getSaveString() + "|" + title + "|" + note + "|" + live + "|" + minRank + "|" + song + "|" + gravity + "|" + maxTime
			+ "|" + gameMode + "|" + cowboyChance + "|" + pass + "|" + allowedItems.join(",") + "|" + badHats.join(",");
	}

	private function render():Void {
		if (scroll != null) { scroll.remove(); scroll = null; }
		if (extraScroll != null) { extraScroll.remove(); extraScroll = null; }
		view.clear();
		viewport.visible = screen == "canvas" || screen == "block-options" || screen == "layers" || screen == "confirm";
		if (h > w) { renderRotateHint(); return; }
		switch (screen) {
			case "canvas": renderCanvas();
			case "catalog": renderCatalog();
			case "rules": renderRules();
			case "rule": renderRule();
			case "gear": renderGear();
			case "save": renderSave();
			case "levels": renderLevels();
			case "block-options": renderBlockOptions();
			case "layers": renderLayers();
			case "confirm": renderConfirm();
			case "menu": renderMenu();
			case "color": renderColor();
			case "brush-size": renderBrushSize();
			case "stamps": renderStamps();
			case "canvas-tools": renderCanvasTools();
			case "reports": renderReports();
			case "report-detail": renderReportDetail();
			case "report-ban": renderReportBan();
			case "report-custom": renderReportCustom();
			default: renderCanvas();
		}
	}

	private function renderRotateHint():Void {
		view.graphics.beginFill(0x0B519E);
		view.graphics.drawRect(0, 0, w, h);
		view.graphics.endFill();
		view.label("Turn your device sideways to edit", 24, h / 2 - 50, w - 48, 100, 26, true, 0xFFFFFF);
	}

	private function header(heading:String, status:String, back:String, action:Void->Void, primary:Bool = false):Void {
		var width = w - inset * 2;
		view.graphics.beginFill(INK);
		view.graphics.drawRoundRect(inset, 12, width, 46, 20, 20);
		view.graphics.endFill();
		var titleX = screen == "canvas" ? inset + 68 : inset + 12;
		view.singleLine(heading, titleX, 23, Math.max(100, Math.min(235, width * .32)), 30, 21, true, 0xFFFFFF);
		if (width > 600) view.singleLine(status, inset + Math.min(270, width * .43), 28, Math.max(80, width - 420), 22, 12, false, LIME);
		if (back != "") view.button(back, w - inset - 132, 17, 132, action, primary, 36);
	}

	private function renderCanvas():Void {
		header(title == "" ? "NEW COURSE" : title.toUpperCase(), mode.toUpperCase() + "  •  " + (signature() == savedSignature ? "SAVED" : "UNSAVED CHANGES"), "SAVE", openSave, true);
		view.button("☰", inset + 4, 18, 46, function() show("menu"), false, 36);
		view.graphics.beginFill(PAPER);
		view.graphics.drawRoundRect(inset + canvasW + 12, 66, paletteW, canvasH, 18, 18);
		view.graphics.endFill();
		var x = inset + canvasW + 24;
		var panelWidth = paletteW - 24;
		switch (mode) {
			case "art": renderArtPalette(x, panelWidth);
			case "bg": renderBackgroundPalette(x, panelWidth);
			default: renderBlockPalette(x, panelWidth);
		}
		var y = h - 56;
		var bw = w - inset * 2;
		var compact = bw < 700;
		view.button("BLOCKS", inset, y, compact ? 78 : 88, function() setMode("blocks"), mode == "blocks", 44);
		view.button("ART", inset + (compact ? 82 : 94), y, 62, function() setMode("art"), mode == "art", 44);
		view.button("BG", inset + (compact ? 148 : 162), y, 50, function() setMode("bg"), mode == "bg", 44);
		var right = w - inset;
		view.button("TEST ▶", right - 116, y, 116, testDraft, true, 44);
		view.button("RULES", right - 206, y, 82, function() show("rules"), false, 44);
		if (compact) {
			view.button("MORE", right - 290, y, 76, function() show("menu"), false, 44);
		} else {
			view.button(Std.int(zoom * 100) + "%", right - 296, y, 82, cycleZoom, false, 44);
			view.button(panMode ? "DRAW" : "PAN", right - 372, y, 70, togglePan, panMode, 44);
			view.button("↷", right - 426, y, 46, function() { redoActiveObjectLayer(); render(); }, false, 44);
			view.button("↶", right - 480, y, 46, function() { undoActiveObjectLayer(); render(); }, false, 44);
		}
	}

	private function renderBlockPalette(x:Float, width:Float):Void {
		view.label("BLOCKS", x, 75, width, 30, 19, true);
		view.label("Tap to select", x, 101, width, 22, 11, false, MUTED);
		var quick = [{id:"basic1",label:"BASIC"},{id:"brick",label:"BRICK"},{id:"finish",label:"FINISH"},{id:"item",label:"ITEM"},{id:"ice",label:"ICE"}];
		var cw = (width - 8) / 2;
		for (i in 0...quick.length) {
			var entry = quick[i];
			view.button(entry.label, x + (i % 2) * (cw + 8), 125 + Std.int(i / 2) * 57, cw,
				function() { selectedBlockTool = entry.id; selectEditorTool("blocks", entry.id); render(); }, selectedBlockTool == entry.id, 50);
		}
		view.button("MORE", x + cw + 8, 239, cw, function() show("catalog"), false, 50);
	}

	private function renderArtPalette(x:Float, width:Float):Void {
		view.label("ART TOOLS", x, 75, width, 30, 19, true);
		view.label("Editing " + activeLayerLabel, x, 101, width, 22, 11, false, MUTED);
		var tools = [{id:"brush",label:"BRUSH",group:"tools"},{id:"eraser",label:"ERASE",group:"tools"},
			{id:"stamps",label:"STAMPS",group:"stamps"},{id:"text",label:"TEXT",group:"stamps"}];
		var cw = (width - 8) / 2;
		for (i in 0...tools.length) {
			var tool = tools[i];
			view.button(tool.label, x + (i % 2) * (cw + 8), 124 + Std.int(i / 2) * 48, cw,
				function() {
					if (tool.id == "stamps") show("stamps");
					else { selectedArtTool = tool.id; selectEditorTool(tool.group, tool.id); render(); }
				}, tool.id == "stamps" ? StringTools.startsWith(selectedArtTool, "stamp") || selectedArtTool == "delete" : selectedArtTool == tool.id, 42);
		}
		view.button("SIZE " + Std.int(brushSize), x, 223, width * .49, function() show("brush-size"), false, 44);
		view.button("COLOR", x + width * .53, 223, width * .47, function() show("color"), false, 44);
		view.button(activeLayerLabel.toUpperCase() + " ▾", x, 270, width, function() show("layers"), false, 44);
	}

	private function renderBackgroundPalette(x:Float, width:Float):Void {
		view.label("BACKGROUNDS", x, 75, width, 30, 18, true);
		view.label("Preset or color", x, 101, width, 22, 11, false, MUTED);
		var cw = (width - 8) / 2;
		for (i in 0...7) {
			var id = "bg" + (i + 1);
			var spec = EditorSideBarCatalog.backgroundSpec(id);
			if (spec == null) continue;
			var row = Std.int(i / 2);
			view.button("BG " + (i + 1), x + (i % 2) * (cw + 8), 124 + row * 43, cw,
				function() { selectArtBackground(spec.code, spec.color); render(); }, artBackgroundCode == spec.code, 38);
		}
		view.button("COLOR", x + cw + 8, 253, cw, function() show("color"), false, 38);
	}

	private function show(next:String):Void {
		if (screen != next && busy) { requestGeneration++; busy = false; }
		screen = next;
		if (next == "levels") fetchLevels(); else if (next == "reports") fetchReports(); else render();
	}

	private function setMode(next:String):Void {
		mode = next;
		panMode = false;
		if (next == "blocks") selectEditorTool("blocks", selectedBlockTool);
		else if (next == "art") selectEditorTool(selectedArtTool == "brush" || selectedArtTool == "eraser" ? "tools" : "stamps", selectedArtTool);
		else { selectEditorTool("", ""); focusNone(); }
		render();
	}

	private function togglePan():Void {
		panMode = !panMode;
		if (panMode) selectEditorTool("", ""); else setMode(mode);
		render();
	}

	private function cycleZoom():Void {
		var values = [0.25, 0.5, 0.75, 1.0, 1.5, 2.5, 5.0];
		var next = 0;
		for (i in 0...values.length) if (Math.abs(zoom - values[i]) < .01) next = (i + 1) % values.length;
		setZoom(values[next]); render();
	}

	private function canvasDown(e:MouseEvent):Void {
		if (!panMode || screen != "canvas") return;
		panDragging = true; panX = e.stageX; panY = e.stageY;
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_MOVE, canvasMove);
			AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, canvasUp);
		}
	}
	private function touchBegin(e:TouchEvent):Void {
		if (screen != "canvas" || !mobileCanvasBounds.contains(e.stageX, e.stageY)) return;
		touches.set(e.touchPointID, new Point(e.stageX, e.stageY));
		if (touchCount() == 2) {
			if (isDrawing()) endSelectedBrush();
			canvasUp();
			mobileGestureActive = true;
			gestureCenter = touchCenter();
			gestureDistance = touchDistance();
			gestureZoom = zoom;
		}
	}
	private function touchMove(e:TouchEvent):Void {
		if (!touches.exists(e.touchPointID)) return;
		touches.set(e.touchPointID, new Point(e.stageX, e.stageY));
		if (touchCount() != 2 || gestureCenter == null) return;
		var center = touchCenter();
		setPos(posX + (center.x - gestureCenter.x) / zoom, posY + (center.y - gestureCenter.y) / zoom);
		if (gestureDistance > 8) setZoom(gestureZoom * touchDistance() / gestureDistance);
		gestureCenter = center;
	}
	private function touchEnd(e:TouchEvent):Void {
		touches.remove(e.touchPointID);
		if (touchCount() == 2) { gestureCenter = touchCenter(); gestureDistance = touchDistance(); gestureZoom = zoom; }
		else gestureCenter = null;
		if (touchCount() == 0) mobileGestureActive = false;
	}
	private function cancelGesture(?_:Event):Void {
		touches = new Map<Int, Point>(); gestureCenter = null; mobileGestureActive = false; canvasUp();
	}
	#if (js && html5)
	private function browserCancelGesture(_:js.html.Event):Void cancelGesture();
	#end
	private function touchCount():Int { var count = 0; for (_ in touches.keys()) count++; return count; }
	private function touchCenter():Point {
		var x = 0.0, y = 0.0, count = 0;
		for (point in touches) { x += point.x; y += point.y; count++; }
		return new Point(x / count, y / count);
	}
	private function touchDistance():Float {
		var points = [for (point in touches) point];
		if (points.length < 2) return 0;
		return Point.distance(points[0], points[1]);
	}
	private function canvasMove(e:MouseEvent):Void {
		if (!panDragging) return;
		setPos(posX + (e.stageX - panX) / zoom, posY + (e.stageY - panY) / zoom);
		panX = e.stageX; panY = e.stageY;
	}
	private function canvasUp(?_:MouseEvent):Void {
		panDragging = false;
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_MOVE, canvasMove);
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, canvasUp);
		}
	}

	private function beginScreen(heading:String, status:String, back:String, action:Void->Void):Void {
		view.graphics.beginFill(NAVY);
		view.graphics.drawRect(0, 0, w, h);
		view.graphics.endFill();
		header(heading, status, back, action);
	}

	private function renderMenu():Void {
		beginScreen("EDITOR MENU", title == "" ? "NEW COURSE" : title.toUpperCase(), "← CANVAS", function() show("canvas"));
		var width = (w - inset * 2 - 24) / 3;
		var actions = [
			{label:"MY LEVELS",run:function() show("levels")}, {label:"NEW COURSE",run:confirmNew},
			{label:reportsMode ? "REPORTED LEVELS" : "SAVE COURSE",run:reportsMode ? function() show("reports") : openSave},
			{label:"LEVEL RULES",run:function() show("rules")},
			{label:"TEST RUN",run:testDraft}, {label:"EXIT EDITOR",run:confirmExit},
			{label:"CANVAS TOOLS",run:function() show("canvas-tools")}
		];
		if (canViewLevelReports() && !reportsMode) actions.push({label:"REPORTED LEVELS",run:function() show("reports")});
		for (i in 0...actions.length) {
			var action = actions[i];
			view.button(action.label, inset + (i % 3) * (width + 12), 96 + Std.int(i / 3) * 92, width, action.run, i == 2, 72);
		}
		if (message != "") view.label(message, inset, 63, w - inset * 2, 28, 14, false, 0xFFFFFF);
	}

	private function renderCanvasTools():Void {
		beginScreen("CANVAS TOOLS", title == "" ? "NEW COURSE" : title.toUpperCase(), "← MENU", function() show("menu"));
		var width = w - inset * 2;
		var cell = (width - 16) / 2;
		var actions = [
			{label:"UNDO",run:function() { undoActiveObjectLayer(); show("canvas"); }},
			{label:"REDO",run:function() { redoActiveObjectLayer(); show("canvas"); }},
			{label:panMode ? "DRAW MODE" : "PAN MODE",run:function() { togglePan(); show("canvas"); }},
			{label:"ZOOM " + Std.int(zoom * 100) + "%",run:function() { cycleZoom(); show("canvas"); }}
		];
		for (i in 0...actions.length) {
			var action = actions[i];
			view.button(action.label, inset + (i % 2) * (cell + 16), 98 + Std.int(i / 2) * 108, cell, action.run,
				i == 2 && panMode, 92);
		}
	}

	private function renderCatalog():Void {
		beginScreen("BLOCK CATALOG", "CHOOSE A TOOL", "← CANVAS", function() show("canvas"));
		var categories = ["all", "movement", "hazards", "special"];
		var width = (w - inset * 2 - 24) / 4;
		for (i in 0...categories.length) {
			var category = categories[i];
			view.button(category.toUpperCase(), inset + i * (width + 8), 69, width,
				function() { catalogCategory = category; render(); }, category == catalogCategory, 36);
		}
		view.panel(inset, 111, w - inset * 2, h - 169);
		var names = blockTools(catalogCategory);
		var columns = w >= 760 ? 4 : 3;
		var cell = (w - inset * 2 - 28 - (columns - 1) * 8) / columns;
		scroll = new MobileScrollPane(); view.addChild(scroll);
		scroll.x = inset + 14; scroll.y = 123;
		var v = scroll.content;
		for (i in 0...names.length) {
			var tool = names[i];
			v.button(blockName(tool), (i % columns) * (cell + 8), Std.int(i / columns) * 59, cell,
				function() { selectedBlockTool = tool; setMode("blocks"); show("canvas"); }, selectedBlockTool == tool, 52);
		}
		scroll.setSize(w - inset * 2 - 28, h - 193, Math.ceil(names.length / columns) * 59);
		view.label("Choose a block to return to the canvas.", inset, h - 42, w - inset * 2, 27, 12, false, 0xFFFFFF);
	}

	private static function blockTools(category:String):Array<String> {
		var all = ["basic1","basic2","basic3","basic4","brick","finish","ice","item","infItem","left","right","up","down",
			"teleport","mine","crumble","vanish","move","water","rotateR","rotateL","push","happy","sad","custom","safety","heart","time","egg","delete"];
		return switch category {
			case "movement": ["left","right","up","down","move","rotateR","rotateL","push","water","teleport"];
			case "hazards": ["mine","crumble","vanish","sad","egg"];
			case "special": ["item","infItem","teleport","happy","custom","safety","heart","time","finish","delete"];
			default: all;
		};
	}
	private static function blockName(id:String):String return switch id {
		case "infItem": "Infinite item"; case "rotateR": "Rotate right"; case "rotateL": "Rotate left";
		case "basic1" | "basic2" | "basic3" | "basic4": "Basic " + id.substr(5);
		default: id.substr(0, 1).toUpperCase() + id.substr(1);
	};

	private function renderRules():Void {
		beginScreen("LEVEL RULES", title == "" ? "NEW COURSE" : title.toUpperCase(), "← CANVAS", function() show("canvas"));
		view.label("Set how your course plays. Tap a rule to change it.", inset, 68, w - inset * 2, 29, 14, false, 0xFFFFFF);
		var rules = [
			{id:"mode",label:"GAME MODE",value:gameMode}, {id:"music",label:"MUSIC",value:song == "" ? "Random" : song},
			{id:"rank",label:"MINIMUM RANK",value:minRank + "+"}, {id:"gravity",label:"GRAVITY",value:gravity + "×"},
			{id:"time",label:"TIME LIMIT",value:maxTime == "0" ? "∞" : maxTime + " sec"},
			{id:"sfcm",label:"COWBOY CHANCE",value:cowboyChance + "%"},
			{id:"items",label:"ITEMS",value:allowedItems.length + " allowed"},
			{id:"hats",label:"HATS",value:(15 - badHats.length) + " allowed"},
			{id:"pass",label:"SECRET PASSWORD",value:hasPass > 0 ? "On" : "Off"}
		];
		var gap = 12.0;
		var cell = (w - inset * 2 - gap * 2) / 3;
		for (i in 0...rules.length) {
			var rule = rules[i];
			var x = inset + (i % 3) * (cell + gap), y = 105 + Std.int(i / 3) * 71;
			view.panel(x, y, cell, 62);
			view.label(rule.label, x + 11, y + 8, cell - 22, 20, 10, false, 0x0B519E);
			view.singleLine(rule.value, x + 11, y + 28, cell - 35, 28, 18, true);
			view.button("›", x + cell - 52, y + 9, 44, function() openRule(rule.id), false, 44);
		}
	}

	private function openRule(id:String):Void {
		ruleId = id;
		if (id == "items" || id == "hats") { gearKind = id; show("gear"); }
		else show("rule");
	}

	private function renderRule():Void {
		beginScreen(ruleTitle(ruleId), "LEVEL RULES", "← RULES", function() show("rules"));
		var width = w - inset * 2;
		view.label(EditorSideBarCatalog.hoverInfo("settings", ruleId).desc, inset, 69, width, 45, 14, false, 0xFFFFFF);
		if (ruleId == "mode") {
			var modes = [{id:"race",label:"RACE"},{id:"objective",label:"OBJECTIVE"},{id:"deathmatch",label:"DEATHMATCH"},
				{id:"egg",label:"ALIEN EGGS"},{id:"hat",label:"HAT ATTACK"},{id:"roguelike",label:"ROGUELIKE"}];
			var cell = (width - 24) / 3;
			for (i in 0...modes.length) {
				var entry = modes[i];
				view.button(entry.label, inset + (i % 3) * (cell + 12), 118 + Std.int(i / 3) * 106, cell,
					function() { setGameMode(entry.id); show("rules"); }, gameMode == entry.id, 92);
			}
			return;
		}
		if (ruleId == "music") {
			var tracks = MusicCatalog.enabled([], true);
			var cell = (width - 16) / 2;
			scroll = new MobileScrollPane(); view.addChild(scroll); scroll.x = inset; scroll.y = 115;
			for (i in 0...tracks.length) {
				var track = tracks[i];
				scroll.content.button(track.label, (i % 2) * (cell + 16), Std.int(i / 2) * 52, cell,
					function() { setSong(track.id); show("rules"); }, song == track.id, 46);
			}
			scroll.setSize(width, h - 145, Math.ceil(tracks.length / 2) * 52);
			return;
		}
		var initial = switch ruleId { case "rank": minRank; case "gravity": gravity; case "time": maxTime; case "sfcm": cowboyChance; case "pass": pass == null ? "" : pass; default: ""; };
		view.panel(inset, 120, width, 163);
		valueInput = view.own(new AuthInput(initial)); valueInput.x = inset + 18; valueInput.y = 158;
		valueInput.setSize(width - 36, 48);
		valueInput.textField.maxChars = ruleId == "pass" ? 32 : ruleId == "sfcm" ? 3 : ruleId == "gravity" || ruleId == "time" ? 4 : 2;
		if (ruleId != "pass") valueInput.textField.restrict = ruleId == "gravity" ? "-.0123456789" : "0123456789";
		view.button("APPLY", w - inset - 178, 294, 178, function() {
			var text = valueInput == null ? "" : valueInput.text;
			if (text == "") text = ruleId == "gravity" ? "1" : "0";
			switch ruleId { case "rank": setMinRank(text); case "gravity": setGravity(text); case "time": setMaxTime(text);
				case "sfcm": setCowboyChance(text); case "pass": setPass(text); default: }
			show("rules");
		}, true);
	}
	private static function ruleTitle(id:String):String return EditorSideBarCatalog.hoverInfo("settings", id).title.toUpperCase();

	private function renderGear():Void {
		beginScreen("ALLOWED GEAR", "COURSE RULES  •  " + gearKind.toUpperCase(), "← RULES", function() show("rules"));
		var width = w - inset * 2;
		view.button("ITEMS", inset, 69, 110, function() { gearKind = "items"; render(); }, gearKind == "items", 36);
		view.button("HATS", inset + 118, 69, 110, function() { gearKind = "hats"; render(); }, gearKind == "hats", 36);
		view.label("Only selected gear appears in this course.", inset + 250, 75, width - 250, 25, 13, false, 0xFFFFFF);
		view.panel(inset, 112, width, h - 180);
		var codes = gearKind == "items" ? Items.getAllCodes() : [for (i in 2...17) i];
		var columns = w >= 760 ? 3 : 2;
		var cell = (width - 28 - (columns - 1) * 12) / columns;
		scroll = new MobileScrollPane(); view.addChild(scroll); scroll.x = inset + 14; scroll.y = 126;
		for (i in 0...codes.length) {
			var code = codes[i];
			var allowed = gearKind == "items" ? allowedItems.indexOf(code) >= 0 : badHats.indexOf(code) < 0;
			var label = gearKind == "items" ? Items.getNameFromCode(code) : "Hat " + code;
			scroll.content.button((allowed ? "✓ " : "○ ") + label, (i % columns) * (cell + 12), Std.int(i / columns) * 60,
				cell, function() { toggleGear(code); }, allowed, 51);
		}
		scroll.setSize(width - 28, h - 210, Math.ceil(codes.length / columns) * 60);
		view.label("Changes apply to this draft; save to publish them.", inset, h - 48, width - 180, 25, 12, false, 0xFFFFFF);
		view.button("DONE", w - inset - 164, h - 55, 164, function() show("rules"), true, 38);
	}
	private function toggleGear(code:Int):Void {
		if (gearKind == "items") {
			var next = allowedItems.copy();
			if (next.indexOf(code) >= 0) next.remove(code); else next.push(code);
			setAllowedItems(next);
		} else {
			var next = badHats.copy();
			if (next.indexOf(code) >= 0) next.remove(code); else next.push(code);
			setBadHats(next.join(","));
		}
		render();
	}

	private function openSave():Void {
		if (LobbySession.group <= 0 || reportsMode) { message = "Sign in to save levels."; show("menu"); return; }
		draftTitle = title; draftNote = note; draftPublish = live == 1; draftNewest = draftPublish && toNewest;
		show("save");
	}
	private function renderSave():Void {
		beginScreen("SAVE COURSE", busy ? "UPLOADING…" : "DRAFT  •  " + (signature() == savedSignature ? "SAVED" : "UNSAVED CHANGES"), "CANCEL", function() {
			returnAfterSave = null; show("canvas");
		});
		var width = w - inset * 2;
		view.panel(inset, 69, width, h - 128);
		view.label("COURSE TITLE", inset + 18, 82, width / 2, 20, 11, false, 0x0B519E);
		view.label(draftTitle.length + " / 50", w - inset - 100, 82, 80, 20, 11, false, MUTED);
		titleInput = view.own(new AuthInput(draftTitle)); titleInput.x = inset + 18; titleInput.y = 104; titleInput.setSize(width - 36, 44);
		titleInput.textField.maxChars = 50; titleInput.onChange = function(value) draftTitle = value;
		view.label("DESCRIPTION", inset + 18, 158, width / 2, 20, 11, false, 0x0B519E);
		view.label(draftNote.length + " / 255", w - inset - 100, 158, 80, 20, 11, false, MUTED);
		noteInput = view.own(new AuthInput(draftNote)); noteInput.x = inset + 18; noteInput.y = 180; noteInput.setSize(width - 36, 54);
		noteInput.textField.maxChars = 255; noteInput.textField.multiline = true; noteInput.textField.wordWrap = true;
		noteInput.onChange = function(value) draftNote = value;
		var half = (width - 48) / 2;
		view.button((draftPublish ? "●" : "○") + " PUBLISH COURSE", inset + 18, 251, half,
			function() { draftPublish = !draftPublish; if (!draftPublish) draftNewest = false; render(); }, draftPublish, 54);
		view.button((draftNewest ? "●" : "○") + " SUBMIT TO NEWEST", inset + 30 + half, 251, half,
			function() { if (draftPublish) draftNewest = !draftNewest; render(); }, draftNewest, 54).enabled = draftPublish;
		view.label(message, inset, h - 47, width - 195, 28, 12, false, 0xFFFFFF);
		view.button(busy ? "UPLOADING…" : "SAVE COURSE", w - inset - 170, h - 54, 170, saveCourse, true, 40).enabled = !busy;
	}
	private function saveCourse():Void {
		if (titleInput != null) draftTitle = titleInput.text;
		if (noteInput != null) draftNote = noteInput.text;
		if (StringTools.trim(draftTitle) == "") { message = "Enter a course title."; render(); return; }
		title = draftTitle; note = draftNote; live = draftPublish ? 1 : 0; toNewest = draftPublish && draftNewest;
		if (isDrawing()) endSelectedBrush();
		uploadCourse(false, false);
	}
	private function uploadCourse(overrideBan:Bool, overwrite:Bool):Void {
		busy = true; message = "Uploading level…"; screen = "save"; render();
		var generation = ++requestGeneration;
		EditorLevelService.upload(this, overrideBan, overwrite, function(result) {
			if (generation != requestGeneration) return;
			busy = false;
			var status = result == null ? "" : Std.string(Reflect.field(result, "status"));
			if (status == "exists") { confirm("A level with this title exists. Overwrite it?", function() uploadCourse(overrideBan, true)); return; }
			if (status == "banned") { confirm("Save as unpublished without a password?", function() {
				live = 0; toNewest = false; setPass(""); draftPublish = false; draftNewest = false;
				uploadCourse(true, overwrite);
			}); return; }
			if (result == null || Reflect.hasField(result, "error") || !uploadSucceeded(result)) {
				message = result == null ? "Could not save this level." : Reflect.hasField(result, "error") ? Std.string(Reflect.field(result, "error")) : "Could not save this level.";
				render(); return;
			}
			savedSignature = signature();
			message = Reflect.hasField(result, "message") ? Std.string(Reflect.field(result, "message")) : "Course saved.";
			if (returnAfterSave != null) { var action = returnAfterSave; returnAfterSave = null; action(); } else show("canvas");
		}, function(error) { if (generation != requestGeneration) return; busy = false; message = "Error: " + error; render(); });
	}
	private static function uploadSucceeded(result:Dynamic):Bool {
		if (!Reflect.hasField(result, "success")) return true;
		var value = Std.string(Reflect.field(result, "success")).toLowerCase();
		return value == "1" || value == "true" || value == "yes";
	}

	private function fetchLevels():Void {
		levels = []; selectedLevel = null; busy = true; message = "Loading your levels…"; render();
		if (LobbySession.group <= 0) { busy = false; message = "Sign in to load saved levels."; render(); return; }
		var generation = ++requestGeneration;
		EditorLevelService.list(function(result) {
			if (generation != requestGeneration) return;
			busy = false; message = "";
			var entries:Dynamic = result == null ? null : Reflect.field(result, "levels");
			if (Std.isOfType(entries, Array)) levels = cast entries;
			render();
		}, function(error) { if (generation != requestGeneration) return; busy = false; message = "Error: " + error; render(); });
	}
	private function renderLevels():Void {
		beginScreen("MY LEVELS", busy ? "LOADING…" : levels.length + " SAVED", "← CANVAS", function() show("canvas"));
		var width = w - inset * 2;
		view.label("Pick up a draft, or start a brand-new course.", inset, 70, width, 29, 15, false, 0xFFFFFF);
		var listW = width * .64;
		view.panel(inset, 102, listW, h - 165);
		scroll = new MobileScrollPane(); view.addChild(scroll); scroll.x = inset + 10; scroll.y = 112;
		for (i in 0...levels.length) {
			var entry = levels[i]; var label = field(entry, "title");
			var published = field(entry, "live") == "1";
			scroll.content.button(label + "  •  " + (published ? "Published" : "Unpublished"), 0, i * 66, listW - 20,
				function() { selectedLevel = entry; render(); }, selectedLevel == entry, 58);
		}
		scroll.setSize(listW - 20, h - 201, levels.length * 66);
		var x = inset + listW + 12, rightW = width - listW - 12;
		view.panel(x, 102, rightW, h - 165);
		if (selectedLevel != null) {
			view.label("SELECTED COURSE", x + 14, 116, rightW - 28, 20, 11, false, 0x0B519E);
			view.singleLine(field(selectedLevel, "title"), x + 14, 139, rightW - 28, 30, 19, true);
			view.label(field(selectedLevel, "live") == "1" ? "Published" : "Unpublished", x + 14, 172, rightW - 28, 25, 12, false, MUTED);
			view.button("EDIT LEVEL", x + 14, 222, rightW - 28, loadSelected, true, 42);
			view.button("DELETE…", x + 14, 270, rightW - 28, deleteSelected, false, 36);
		} else view.label(busy ? "Loading…" : "Choose a level", x + 14, 140, rightW - 28, 50, 17, true);
		view.button("＋ NEW LEVEL", inset, h - 57, Math.min(260, listW), confirmNew, true, 43);
		view.label(message, x, h - 55, rightW, 43, 12, false, 0xFFFFFF);
	}
	private static function field(value:Dynamic, key:String):String {
		var result = value == null ? null : Reflect.field(value, key);
		return result == null ? "" : Std.string(result);
	}
	private function loadSelected():Void {
		if (selectedLevel == null) return;
		var entry = selectedLevel;
		protectDraft(function() {
			busy = true; message = "Loading level…"; screen = "levels"; render();
			var id = Std.parseInt(field(entry, "level_id"));
			var version = Std.parseInt(field(entry, "version"));
			if (id == null || version == null) { busy = false; message = "Invalid level listing."; render(); return; }
			var generation = ++requestGeneration;
			EditorLevelService.load(id, version, function(data:ServerLevelData) {
				if (generation != requestGeneration) return;
				busy = false; applyLoadedLevelData(data); setReportsMode(false); savedSignature = signature(); setMode("blocks"); show("canvas");
			}, function(error) { if (generation != requestGeneration) return; busy = false; message = "Error: " + error; render(); });
		});
	}
	private function deleteSelected():Void {
		if (selectedLevel == null) return;
		var entry = selectedLevel;
		confirm('Delete "' + field(entry, "title") + '"?', function() {
			var id = Std.parseInt(field(entry, "level_id"));
			if (id == null) return;
			busy = true; message = "Deleting level…"; render();
			var generation = ++requestGeneration;
			EditorLevelService.deleteLevel(id, function(_) { if (generation == requestGeneration) fetchLevels(); },
				function(error) { if (generation != requestGeneration) return; busy = false; message = "Error: " + error; render(); });
		});
	}

	private function fetchReports():Void {
		reports = []; selectedReport = null; busy = true; message = "Loading reports…"; render();
		if (!canViewLevelReports()) { busy = false; message = "Moderator access is required."; render(); return; }
		var generation = ++requestGeneration;
		EditorReportService.list(function(result:Dynamic) {
			if (generation != requestGeneration) return;
			busy = false; message = "";
			var entries:Dynamic = result == null ? null : Reflect.field(result, "levels");
			if (Std.isOfType(entries, Array)) reports = cast entries;
			render();
		}, function(error:String) {
			if (generation != requestGeneration) return;
			busy = false; message = "Error: " + error; render();
		});
	}
	private function renderReports():Void {
		beginScreen("REPORTED LEVELS", busy ? "LOADING…" : reports.length + " REPORTS", "← MENU", function() show("menu"));
		view.label("Review a report, inspect the course, or archive it.", inset, 70, w - inset * 2, 28, 15, false, 0xFFFFFF);
		var width = w - inset * 2, listW = width * .63;
		view.panel(inset, 104, listW, h - 166);
		scroll = new MobileScrollPane(); view.addChild(scroll); scroll.x = inset + 12; scroll.y = 115;
		for (i in 0...reports.length) {
			var report = reports[i];
			var label = EditorReportService.field(report, "title") + "  •  " + EditorReportService.field(report, "creator");
			scroll.content.button(label, 0, i * 60, listW - 24, function() { selectedReport = report; render(); }, selectedReport == report, 52);
		}
		scroll.setSize(listW - 24, h - 190, reports.length * 60);
		var x = inset + listW + 12, rightW = width - listW - 12;
		view.panel(x, 104, rightW, h - 166);
		if (selectedReport != null) {
			view.label("SELECTED REPORT", x + 14, 118, rightW - 28, 23, 11, false, 0x0B519E);
			view.singleLine(EditorReportService.field(selectedReport, "title"), x + 14, 143, rightW - 28, 30, 19, true);
			view.label("By " + EditorReportService.field(selectedReport, "creator"), x + 14, 174, rightW - 28, 25, 13, false, 0x50687A);
			view.button("REVIEW REPORT", x + 14, 226, rightW - 28, function() { reportBanApplied = false; show("report-detail"); }, true, 48);
		} else view.label(busy ? "Loading…" : "Choose a report", x + 14, 150, rightW - 28, 48, 16, true);
		view.label(message, inset, h - 53, width, 40, 14, false, 0xFFFFFF);
	}
	private function renderReportDetail():Void {
		if (selectedReport == null) { show("reports"); return; }
		beginScreen("REPORT DETAILS", EditorReportService.field(selectedReport, "title"), "← REPORTS", function() { screen = "reports"; render(); });
		var width = w - inset * 2, leftW = width * .61;
		view.panel(inset, 76, leftW, h - 94);
		var x = inset + 16;
		scroll = new MobileScrollPane(); view.addChild(scroll); scroll.x = x; scroll.y = 90;
		var details = scroll.content;
		details.singleLine(EditorReportService.field(selectedReport, "title"), 0, 0, leftW - 32, 35, 24, true);
		details.label("CREATOR  " + EditorReportService.field(selectedReport, "creator"), 0, 40, leftW - 32, 27, 14, false, 0x0B519E);
		details.label("REPORTED BY  " + EditorReportService.field(selectedReport, "reporter"), 0, 69, leftW - 32, 27, 14, false, 0x0B519E);
		details.label("VERSION  " + EditorReportService.field(selectedReport, "version") + "    REPORTED  " + reportDate(selectedReport),
			0, 98, leftW - 32, 27, 13, false, 0x50687A);
		details.label("REASON", 0, 134, leftW - 32, 22, 11, true, 0x50687A);
		details.label(EditorReportService.field(selectedReport, "reason"), 0, 159, leftW - 32, 85, 15, false, 0x18334B);
		details.label("LEVEL NOTE", 0, 256, leftW - 32, 22, 11, true, 0x50687A);
		details.label(EditorReportService.field(selectedReport, "note"), 0, 282, leftW - 32, 120, 15, false, 0x18334B);
		scroll.setSize(leftW - 32, h - 122, 410);
		var actionX = inset + leftW + 12, actionW = width - leftW - 12;
		view.panel(actionX, 76, actionW, h - 94);
		view.button("LOAD IN EDITOR", actionX + 14, 104, actionW - 28, loadReportedLevel, true, 52).enabled = !busy;
		view.button("ARCHIVE REPORT", actionX + 14, 171, actionW - 28, confirmArchiveReport, false, 52).enabled = !busy;
		view.button(reportBanApplied ? "BAN APPLIED" : "BAN + UNPUBLISH", actionX + 14, 238, actionW - 28,
			function() { reportReason = ""; reportDuration = 0; show("report-ban"); }, false, 52).enabled = !busy && !reportBanApplied;
		view.label(message, inset, h - 22, width, 20, 12, false, 0xFFFFFF);
	}
	private static function reportDate(report:Dynamic):String {
		var seconds = Std.parseFloat(EditorReportService.field(report, "report_time"));
		return Math.isNaN(seconds) || seconds <= 0 ? "Unknown" : Date.fromTime(seconds * 1000).toString().substr(0, 16);
	}
	private function loadReportedLevel():Void {
		var report = selectedReport;
		protectDraft(function() {
			var id = Std.parseInt(EditorReportService.field(report, "level_id"));
			var version = Std.parseInt(EditorReportService.field(report, "version"));
			if (id == null || version == null) { message = "Invalid report listing."; show("report-detail"); return; }
			busy = true; message = "Loading reported level…"; screen = "report-detail"; render();
			var generation = ++requestGeneration;
			EditorLevelService.load(id, version, function(data:ServerLevelData) {
				if (generation != requestGeneration) return;
				busy = false; applyLoadedLevelData(data, true); setReportsMode(true); savedSignature = signature(); setMode("blocks"); show("canvas");
			}, function(error:String) { if (generation != requestGeneration) return; busy = false; message = "Error: " + error; render(); });
		});
	}
	private function confirmArchiveReport():Void {
		if (busy) return;
		confirm("Archive this report without changing the level?", archiveSelectedReport, false);
	}
	private function archiveSelectedReport():Void {
		if (selectedReport == null || busy && !reportBanApplied) return;
		busy = true; message = "Archiving report…"; screen = "report-detail"; render();
		var generation = ++requestGeneration;
		EditorReportService.archive(selectedReport, function(_:Dynamic) {
			if (generation != requestGeneration) return;
			busy = false; screen = "reports"; fetchReports();
		}, function(error:String) { if (generation != requestGeneration) return; busy = false; message = "Error: " + error; render(); });
	}
	private function renderReportBan():Void {
		beginScreen("BAN + UNPUBLISH", EditorReportService.field(selectedReport, "creator"), "← REPORT", function() show("report-detail"));
		var width = w - inset * 2, half = (width - 16) / 2;
		view.label("REASON", inset, 70, half, 25, 13, true, 0xFFFFFF);
		view.label("DURATION", inset + half + 16, 70, half, 25, 13, true, 0xFFFFFF);
		view.panel(inset, 101, half, h - 164);
		view.panel(inset + half + 16, 101, half, h - 164);
		var reasons = ["Vulgar Language", "Harassment", "Sensitive Imagery", "Scamming", "Copying (w/o attrib)",
			"Republished Removed Level", "Other…"];
		var durations = [
			{label:"One Hour",value:3600}, {label:"One Day",value:86400}, {label:"Three Days",value:259200},
			{label:"One Week",value:604800}, {label:"Two Weeks",value:1209600}, {label:"One Month",value:2592000},
			{label:"Six Months",value:15768000}, {label:"One Year",value:31536000}
		];
		var reasonScroll = new MobileScrollPane(); scroll = reasonScroll; view.addChild(reasonScroll); reasonScroll.x = inset + 10; reasonScroll.y = 111;
		for (i in 0...reasons.length) {
			var reason = reasons[i];
			reasonScroll.content.button(reason, 0, i * 51, half - 20, function() {
				if (reason == "Other…") show("report-custom"); else { reportReason = reason; render(); }
			}, reportReason == reason, 44);
		}
		reasonScroll.setSize(half - 20, h - 190, reasons.length * 51);
		var durationScroll = new MobileScrollPane(); extraScroll = durationScroll; view.addChild(durationScroll); durationScroll.x = inset + half + 26; durationScroll.y = 111;
		for (i in 0...durations.length) {
			var duration = durations[i];
			durationScroll.content.button(duration.label, 0, i * 51, half - 20,
				function() { reportDuration = duration.value; render(); }, reportDuration == duration.value, 44);
		}
		durationScroll.setSize(half - 20, h - 190, durations.length * 51);
		view.label(message, inset, h - 48, width - 205, 34, 12, false, 0xFFFFFF);
		view.button("BAN USER", w - inset - 186, h - 55, 186, confirmBanReport, true, 44).enabled = !busy;
	}
	private function renderReportCustom():Void {
		beginScreen("CUSTOM REASON", "BAN + UNPUBLISH", "← BAN", function() show("report-ban"));
		view.panel(inset, 105, w - inset * 2, 145);
		view.label("Enter the reason after “Inappropriate Level --”", inset + 18, 120, w - inset * 2 - 36, 25, 14, false, 0x50687A);
		valueInput = view.own(new AuthInput(reportReason)); valueInput.x = inset + 18; valueInput.y = 159;
		valueInput.setSize(w - inset * 2 - 36, 48); valueInput.textField.maxChars = 200;
		view.button("USE REASON", w - inset - 170, 275, 170, function() {
			reportReason = StringTools.trim(valueInput.text); show("report-ban");
		}, true, 48);
	}
	private function confirmBanReport():Void {
		if (busy) return;
		if (StringTools.trim(reportReason) == "") { message = "Choose or enter a reason."; render(); return; }
		if (reportDuration <= 0) { message = "Choose a ban duration."; render(); return; }
		confirm("Socially ban " + EditorReportService.field(selectedReport, "creator") + " and unpublish the level?", banSelectedReport, false);
	}
	private function banSelectedReport():Void {
		if (selectedReport == null || reportBanApplied || busy) return;
		busy = true; message = "Unpublishing and banning…"; screen = "report-detail"; render();
		var generation = ++requestGeneration;
		EditorReportService.ban(selectedReport, reportReason, reportDuration, function(result:Dynamic) {
			if (generation != requestGeneration) return;
			reportBanApplied = true;
			archiveSelectedReport();
			if (result != null && Reflect.hasField(result, "message")) ScreenFactory.message(Std.string(Reflect.field(result, "message")));
		}, function(error:String) { if (generation != requestGeneration) return; busy = false; message = "Error: " + error; render(); });
	}

	private function showBlockOptions(block:EditorBlockObject):Void {
		selectedOptionsBlock = block;
		optionItems = EditorBlockOptions.selectedItems(block.options, allowedItems);
		show("block-options");
	}
	private function renderBlockOptions():Void {
		if (selectedOptionsBlock == null) { show("canvas"); return; }
		view.graphics.beginFill(NAVY, .68); view.graphics.drawRect(0, 64, w, h - 64); view.graphics.endFill();
		var x = inset + 55, y = 91.0, width = w - (inset + 55) * 2;
		view.panel(x, y, width, h - 109);
		var block = selectedOptionsBlock;
		view.label(block.type == null ? "BLOCK OPTIONS" : Std.string(block.type).toUpperCase() + " BLOCK OPTIONS", x + 18, y + 14, width - 36, 30, 21, true);
		if (block.type == BlockType.Item || block.type == BlockType.InfiniteItem) {
			view.label("Choose which items this block can give.", x + 18, y + 43, width - 36, 22, 12, false, MUTED);
			var codes = Items.getAllCodes();
			var cell = (width - 56) / 3;
			for (i in 0...codes.length) {
				var code = codes[i]; var chosen = optionItems.indexOf(code) >= 0;
				view.button((chosen ? "✓ " : "○ ") + Items.getNameFromCode(code), x + 18 + (i % 3) * (cell + 10),
					y + 70 + Std.int(i / 3) * 37, cell, function() { if (optionItems.indexOf(code) >= 0) optionItems.remove(code); else optionItems.push(code); render(); }, chosen, 36);
			}
		} else {
			view.label("Set this block's value or color.", x + 18, y + 55, width - 36, 25, 14, false, MUTED);
			valueInput = view.own(new AuthInput(block.options)); valueInput.x = x + 18; valueInput.y = y + 96; valueInput.setSize(width - 36, 46);
		}
		view.button("REMOVE BLOCK", x + 18, h - 67, 180, function() { deleteBlock(block); selectedOptionsBlock = null; show("canvas"); }, false, 40);
		view.button("DONE", x + width - 168, h - 67, 150, commitBlockOptions, true, 40);
	}
	private function commitBlockOptions():Void {
		var block = selectedOptionsBlock;
		if (block != null) {
			if (block.type == BlockType.Item || block.type == BlockType.InfiniteItem) block.setOptions(EditorBlockOptions.applyItemOptions(optionItems, allowedItems));
			else if (valueInput != null) {
				var text = valueInput.text;
				switch block.type {
					case BlockType.Teleport: var value = Std.parseInt(text); if (value != null) block.setOptions(EditorBlockOptions.applyTeleportColor(value));
					case BlockType.Happy | BlockType.Sad: var value = Std.parseInt(text); if (value != null) block.setOptions(EditorBlockOptions.applyStatChange(block.type, value));
					case BlockType.CustomStats:
						if (text == "reset") block.setOptions("reset");
						else { var p = text.split("-"); if (p.length == 3) {
							var a = Std.parseInt(p[0]), b = Std.parseInt(p[1]), c = Std.parseInt(p[2]);
							if (a != null && b != null && c != null) block.setOptions(EditorBlockOptions.applyCustomStats(false, a, b, c));
						} }
					default:
				}
			}
		}
		selectedOptionsBlock = null; show("canvas");
	}

	private function renderLayers():Void {
		view.graphics.beginFill(NAVY, .65); view.graphics.drawRect(0, 64, w, h - 64); view.graphics.endFill();
		var x = inset + 70, width = w - (inset + 70) * 2;
		view.panel(x, 108, width, h - 125);
		view.label("CHOOSE ART LAYER", x + 18, 123, width - 36, 32, 22, true);
		view.label("Each layer keeps its own drawing and stamps.", x + 18, 156, width - 36, 24, 12, false, MUTED);
		var labels = ["ART 00", "ART 0", "ART 1", "ART 2", "ART 3"];
		var numbers = [5, 4, 1, 2, 3];
		var cell = (width - 48) / 3;
		for (i in 0...labels.length) {
			var label = labels[i], number = numbers[i];
			view.button(label, x + 18 + (i % 3) * (cell + 6), 185 + Std.int(i / 3) * 70, cell,
				function() { setActiveObjectLayer(number); activeLayerLabel = "Art " + label.substr(4); setMode("art"); show("canvas"); },
				activeLayerLabel.toUpperCase() == label, 61);
		}
		view.button("DONE", x + width - 165, h - 55, 150, function() show("canvas"), true, 38);
	}

	private function renderColor():Void {
		beginScreen(mode == "bg" ? "BACKGROUND COLOR" : "BRUSH COLOR", "HEX COLOR", "← CANVAS", function() show("canvas"));
		var width = w - inset * 2;
		view.panel(inset, 105, width, h - 165);
		view.label("Enter six hex digits or choose a swatch.", inset + 18, 120, width - 36, 30, 14, false, MUTED);
		valueInput = view.own(new AuthInput(StringTools.hex(mode == "bg" ? color : brushColor, 6)));
		valueInput.x = inset + 18; valueInput.y = 160; valueInput.setSize(width - 170, 48);
		valueInput.textField.maxChars = 6; valueInput.textField.restrict = "0-9a-fA-F";
		view.button("APPLY", w - inset - 135, 160, 117, applyColor, true, 48);
		var colors = [0xFFFFFF,0xD1ED62,0x9CC9FB,0x5C9C5D,0xF5C86B,0xB68168,0xCBA9EF,0x18334B];
		var cell = (width - 36 - 7 * 7) / 8;
		for (i in 0...colors.length) {
			var value = colors[i];
			view.button(StringTools.hex(value, 6), inset + 18 + i * (cell + 7), 230, cell,
				function() { if (mode == "bg") setColor(value); else setBrushColor(value); show("canvas"); }, false, 46);
		}
		view.button("ADVANCED HSV + EYEDROPPER", w - inset - 304, h - 54, 304, openAdvancedColor, true, 44);
	}
	private function openAdvancedColor():Void {
		if (advancedPicker != null) return;
		advancedPicker = ScreenFactory.advancedColor(mode == "bg" ? color : brushColor);
		var mobilePicker = Std.downcast(advancedPicker, MobileAdvancedColorPopup);
		if (mobilePicker != null) mobilePicker.onSamplingChange = function(active:Bool):Void {
			screen = active ? "canvas" : "color";
			render();
		};
		if (mobilePicker != null) mobilePicker.sampleAt = sampleEditorCanvas;
		advancedPicker.addEventListener(Event.CHANGE, previewAdvancedColor);
		advancedPicker.addEventListener(Event.CLOSE, advancedColorClosed);
		if (AppStage.stage != null) AppStage.stage.addChild(advancedPicker); else addChild(advancedPicker);
		advancedPicker.init();
	}
	private function sampleEditorCanvas(stageX:Float, stageY:Float):Null<Int> {
		if (mobileCanvasBounds == null || !mobileCanvasBounds.contains(stageX, stageY)) return null;
		var pixel:Null<BitmapData> = null;
		try {
			pixel = new BitmapData(1, 1, false, 0);
			var matrix = new Matrix();
			matrix.translate(-(stageX - viewport.x), -(stageY - viewport.y));
			pixel.draw(viewport, matrix, null, null, new Rectangle(0, 0, 1, 1));
			var color = pixel.getPixel(0, 0);
			pixel.dispose();
			return color;
		} catch (_:Dynamic) {
			if (pixel != null) pixel.dispose();
			return null;
		}
	}
	private function previewAdvancedColor(_:Event):Void {
		if (advancedPicker == null) return;
		if (mode == "bg") setColor(advancedPicker.getColor()); else setBrushColor(advancedPicker.getColor());
	}
	private function advancedColorClosed(_:Event):Void {
		if (advancedPicker == null) return;
		var value = advancedPicker.getColor();
		advancedPicker.removeEventListener(Event.CHANGE, previewAdvancedColor);
		advancedPicker.removeEventListener(Event.CLOSE, advancedColorClosed);
		advancedPicker = null;
		if (mode == "bg") setColor(value); else setBrushColor(value);
		var recent = pr2.lobby.account.ColorPicker.recentColors;
		recent.remove(value); recent.unshift(value); if (recent.length > 12) recent.resize(12);
		render();
	}
	private function renderBrushSize():Void {
		beginScreen("BRUSH SIZE", activeLayerLabel.toUpperCase(), "← CANVAS", function() show("canvas"));
		view.label("Choose a drawing size.", inset, 75, w - inset * 2, 30, 16, false, 0xFFFFFF);
		var sizes = [1, 4, 8, 12, 20, 32, 64, 128, 255];
		var width = w - inset * 2;
		var cell = (width - 24) / 3;
		for (i in 0...sizes.length) {
			var size = sizes[i];
			view.button(Std.string(size), inset + (i % 3) * (cell + 12), 113 + Std.int(i / 3) * 78, cell,
				function() { setBrushSize(size); show("canvas"); }, Std.int(brushSize) == size, 67);
		}
	}
	private function renderStamps():Void {
		beginScreen("ART STAMPS", activeLayerLabel.toUpperCase(), "← CANVAS", function() show("canvas"));
		view.label("Choose a stamp, then tap the canvas to place it.", inset, 72, w - inset * 2, 28, 15, false, 0xFFFFFF);
		var width = w - inset * 2;
		var cell = (width - 36) / 4;
		for (i in 0...10) {
			var id = "stamp" + i;
			view.button("STAMP " + (i + 1), inset + (i % 4) * (cell + 12), 108 + Std.int(i / 4) * 72, cell,
				function() { selectedArtTool = id; setMode("art"); show("canvas"); }, selectedArtTool == id, 61);
		}
		view.button("REMOVE STAMP", inset + 2 * (cell + 12), 252, cell * 2 + 12, function() {
			selectedArtTool = "delete"; setMode("art"); show("canvas");
		}, selectedArtTool == "delete", 61);
	}
	private function applyColor():Void {
		if (valueInput == null || !~/^[0-9a-fA-F]{6}$/.match(valueInput.text)) { message = "Enter six hex digits."; render(); return; }
		var value = Std.parseInt("0x" + valueInput.text);
		if (value != null) { if (mode == "bg") setColor(value); else setBrushColor(value); }
		show("canvas");
	}

	private var confirmationText = "";
	private var confirmationAction:Null<Void->Void>;
	private function confirm(text:String, action:Void->Void, offerSave:Bool = true):Void {
		confirmReturnScreen = screen;
		confirmationOfferSave = offerSave;
		confirmationText = text; confirmationAction = action; show("confirm");
	}
	private function renderConfirm():Void {
		view.graphics.beginFill(NAVY, .68); view.graphics.drawRect(0, 64, w, h - 64); view.graphics.endFill();
		var x = (w - 500) / 2;
		view.panel(x, 110, 500, 250);
		view.label("PLEASE CONFIRM", x + 20, 130, 460, 35, 23, true);
		view.label(confirmationText, x + 30, 181, 440, 65, 15, false, MUTED);
		view.button("CANCEL", x + 30, 260, 440, function() { confirmationAction = null; screen = confirmReturnScreen; render(); }, true, 41);
		view.button("CONTINUE", x + 255, 308, 215, function() {
			var action = confirmationAction; confirmationAction = null; screen = confirmReturnScreen;
			if (action != null) action(); else render();
		}, false, 37);
		if (confirmationOfferSave && signature() != savedSignature && LobbySession.group > 0 && !reportsMode) view.button("SAVE FIRST", x + 30, 308, 215, function() {
			returnAfterSave = confirmationAction; confirmationAction = null; openSave();
		}, false, 37);
	}
	private function protectDraft(action:Void->Void):Void {
		if (signature() == savedSignature) action();
		else confirm("This will discard unsaved changes to your draft.", action);
	}
	private function confirmNew():Void protectDraft(function() { clear(); setReportsMode(false); savedSignature = signature(); setMode("blocks"); show("canvas"); });
	private function confirmExit():Void protectDraft(function() { ScreenFactory.editorConnection(); show("canvas"); });
	private function testDraft():Void {
		if (isDrawing()) endSelectedBrush();
		// Reconstructing level vars can normalize serialized defaults. Carry the
		// draft's dirty state, then establish a fresh baseline on return.
		var dirtyMarker = signature() == savedSignature ? null : "__unsaved_draft__";
		if (pageHolder != null) pageHolder.changePage(ScreenFactory.testCourse(getLevelVars(), canViewLevelReports(), reportsMode, dirtyMarker));
	}

	override public function remove():Void {
		requestGeneration++;
		if (advancedPicker != null) {
			advancedPicker.removeEventListener(Event.CHANGE, previewAdvancedColor);
			advancedPicker.removeEventListener(Event.CLOSE, advancedColorClosed);
			advancedPicker.remove(); advancedPicker = null;
		}
		cancelGesture();
		if (AppStage.stage != null) AppStage.stage.removeEventListener(Event.RESIZE, layout);
		viewport.removeEventListener(MouseEvent.MOUSE_DOWN, canvasDown);
		viewport.removeEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(TouchEvent.TOUCH_MOVE, touchMove);
			AppStage.stage.removeEventListener(TouchEvent.TOUCH_END, touchEnd);
			AppStage.stage.removeEventListener(Event.DEACTIVATE, cancelGesture);
		}
		#if (js && html5)
		js.Browser.window.removeEventListener("touchcancel", browserCancelGesture);
		js.Browser.window.removeEventListener("blur", browserCancelGesture);
		js.Browser.document.removeEventListener("visibilitychange", browserCancelGesture);
		#end
		mobileChrome = null; mobileCanvasBounds = null; mobileBlockOptions = null;
		if (scroll != null) scroll.remove();
		if (extraScroll != null) extraScroll.remove();
		view.remove();
		super.remove();
	}
}
