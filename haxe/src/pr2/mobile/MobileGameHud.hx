package pr2.mobile;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;
import pr2.gameplay.Course;
import pr2.gameplay.GameHud;
import pr2.mobile.MobileAuthControls.AuthInput;
import pr2.runtime.SvgAsset;
import pr2.lobby.Memory;

/** Landscape HUD over the shared, authoritative Course. Menus never pause a race. */
class MobileGameHud extends GameHud {
	private var course:Course;
	private var quit:Void->Void;
	private var isDone:Void->Bool;
	private var view = new LobbyView();
	private var overlay = new LobbyView();
	private var jump = new MobileHoldControl();
	private var item = new MobileHoldControl();
	private var stick = new MobileHoldControl();
	private var thumb:Shape;
	private var clock:TextField;
	private var status:TextField;
	private var transcript:TextField;
	private var swapped:Bool = false;
	private var panelKind:String = "";
	private var ownerStage:Stage;
	private var w:Float = 844;
	private var h:Float = 390;
	private var inset:Float = 44;
	private var done:Bool = false;
	private var resultsOpen:Bool = false;
	private var lastMap:DisplayObject;
	private var lastChat:String = "";
	private var portrait:Bool = false;
	private var songList:MobileScrollPane;
	private var chatLinks:pr2.lobby.chat.HtmlNameMaker;
	private var eventViews:Array<DisplayObject> = [];
	private var oldTouchMode:MultitouchInputMode;
	private var editorTestRestart:Null<Void->Void>;
	private var editorTestStats:Null<Void->Void>;
	private var editorTestHats:Null<Void->Void>;

	public function new(quit:Void->Void, isDone:Void->Bool) {
		super(); fullViewport = true; this.quit = quit; this.isDone = isDone;
		swapped = Memory.get("mobileControlsSwapped") == true;
		addChild(view); addChild(overlay);
		addEventListener(Event.ADDED_TO_STAGE, added);
		addEventListener(Event.ENTER_FRAME, refresh);
	}
	public function configureEditorTest(restart:Void->Void, stats:Void->Void, hats:Void->Void):Void {
		editorTestRestart = restart; editorTestStats = stats; editorTestHats = hats;
	}
	private function added(_:Event):Void {
		ownerStage = stage;
		ownerStage.addEventListener(Event.RESIZE, resize);
		ownerStage.addEventListener(Event.DEACTIVATE, cancel);
		oldTouchMode = Multitouch.inputMode;
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		#if (js && html5)
		js.Browser.window.addEventListener("touchcancel", browserCancel);
		js.Browser.window.addEventListener("blur", browserCancel);
		js.Browser.document.addEventListener("visibilitychange", browserCancel);
		#end
		resize(null);
	}
	#if (js && html5)
	private function browserCancel(_:js.html.Event):Void cancel(null);
	#end
	override public function mount(value:Course):Void {
		course = value;
		course.itemDisplay.compact();
		if (course.raceChat != null) {
			course.raceChat.visible = false;
			course.raceChat.keyboardShortcutEnabled = false;
		}
		course.timer.visible = false;
		course.statsDisplay.visible = false;
		course.musicSelection.visible = false;
		course.spectatePicker.visible = false;
		jump.onHold = function(held, _, _) { course.touchInput.jump = held; jump.alpha = held ? .7 : 1; };
		item.onHold = function(held, _, _) { course.touchInput.item = held; item.alpha = held ? .7 : 1; };
		stick.onHold = function(held, x, y) {
			var dx = held ? (x - 72) / 50 : 0;
			var dy = held ? (y - 72) / 50 : 0;
			MobileRaceInput.joystick(course.touchInput, dx, dy);
			var length = Math.sqrt(dx * dx + dy * dy);
			if (length > 1) { dx /= length; dy /= length; }
			if (thumb != null) { thumb.x = 41 + dx * 35; thumb.y = 41 + dy * 35; }
		};
		resize(null);
	}
	private function cancel(_:Event):Void {
		jump.release(); item.release(); stick.release();
		if (course != null) course.releaseControls();
	}
	private function resize(_:Event):Void {
		cancel(null);
		w = ownerStage == null ? 844 : ownerStage.stageWidth;
		h = ownerStage == null ? 390 : ownerStage.stageHeight;
		inset = w >= 760 ? 44 : 16;
		portrait = h > w;
		eventViews = [for (d in eventViews) if (d.parent != null) d];
		for (d in eventViews) { d.x = w / 2; d.y = h / 2; }
		if (course != null) {
			var scale = h / 400;
			course.scaleX = course.scaleY = scale;
			course.x = (w - 550 * scale) / 2; course.y = 0;
			course.levelRenderer.setViewport(new Rectangle(-course.x / scale, 0, w / scale, 400));
		}
		draw();
	}
	private function draw():Void {
		// Reparented course-owned views survive rebuilding this surface.
		if (course != null) {
			var borrowed:Array<DisplayObject> = [course.itemDisplay, course.miniMap, course.hearts, course.roguelikeProgressText];
			for (d in borrowed)
				if (d != null && d.parent != null) d.parent.removeChild(d);
		}
		view.clear();
		if (editorTestRestart == null) view.button("Chat", w - inset - 192, 16, 88, function() openPanel("chat"), false, 48);
		view.button("Menu", w - inset - 92, 16, 92, function() openPanel("menu"), false, 48);
		view.panel(inset, 16, 100, 48);
		clock = view.label("--:--", inset + 12, 22, 88, 36, 26, true);
		var mapW = Math.max(80, w - inset * 2 - 316);
		view.panel(inset + 112, 16, mapW, 48);
		status = view.label("", inset, 70, w - inset * 2, 28, 16, true);
		if (course != null) {
			attachMap(mapW);
			view.addChild(course.hearts); course.hearts.x = w - inset - 120; course.hearts.y = 74;
			if (course.roguelikeProgressText != null) { view.addChild(course.roguelikeProgressText); course.roguelikeProgressText.x = inset + 130; course.roguelikeProgressText.y = 76; }
		}
		var s = Math.min(1, Math.min((w - inset * 2 - 170) / 380, (h - 112) / 220));
		jump.graphics.clear(); circle(jump, 116, 0xD1ED62);
		while (jump.numChildren > 0) jump.removeChildAt(0);
		var text = view.label("JUMP", 0, 0, 96, 40, 26, true); text.x = 16; text.y = 39; jump.addChild(text);
		item.graphics.clear(); circle(item, 76, 0xFFFFFF);
		stick.graphics.clear(); circle(stick, 144, 0xF3F8FA);
		while (stick.numChildren > 0) stick.removeChildAt(0);
		stick.addChild(SvgAsset.create("assets/mobile/joystick-directions.svg"));
		thumb = SvgAsset.create("assets/mobile/joystick-thumb.svg"); thumb.x = thumb.y = 41; stick.addChild(thumb);
		for (control in [jump, item, stick]) { view.addChild(control); control.scaleX = control.scaleY = s; }
		jump.x = swapped ? w - inset - 116 * s : inset;
		item.x = swapped ? jump.x - 92 * s : inset + 132 * s;
		stick.x = swapped ? inset : w - inset - 144 * s;
		jump.y = h - 20 - 116 * s; item.y = h - 20 - 76 * s; stick.y = h - 20 - 144 * s;
		if (course != null) { item.addChild(course.itemDisplay); course.itemDisplay.x = 4; course.itemDisplay.y = 2; }
		view.button("", w / 2 - 52, h - 64, 104, swapSides).name = "Swap controls";
		var swap = SvgAsset.create("assets/mobile/swap-sides.svg"); swap.x = w / 2 - 16; swap.y = h - 56; view.addChild(swap);
		drawPanel(); refresh(null);
	}
	private function attachMap(mapW:Float):Void {
		course.miniMap.compact();
		lastMap = course.miniMap; view.addChild(lastMap);
		lastMap.x = inset + 120; lastMap.y = 23;
		lastMap.scaleX = (mapW - 16) / 407; lastMap.scaleY = .68;
	}
	private static function circle(control:Sprite, size:Float, color:Int):Void {
		control.graphics.lineStyle(3, 0x18334B); control.graphics.beginFill(color, .92);
		control.graphics.drawCircle(size / 2, size / 2, size / 2 - 2); control.graphics.endFill();
	}
	public function swapSides():Void {
		cancel(null); swapped = !swapped; Memory.set("mobileControlsSwapped", swapped); draw();
	}
	private function openPanel(kind:String):Void {
		cancel(null); panelKind = kind;
		if (ownerStage != null) ownerStage.focus = ownerStage;
		drawPanel();
	}
	private function drawPanel():Void {
		if (songList != null) { songList.remove(); songList = null; }
		if (chatLinks != null) { chatLinks.remove(); chatLinks = null; }
		overlay.clear(); transcript = null;
		if (course != null) course.inputBlocked = resultsOpen || panelKind != "" || portrait;
		view.mouseChildren = !resultsOpen && !portrait && panelKind == "";
		if (portrait) {
			overlay.graphics.beginFill(0x18334B); overlay.graphics.drawRect(0, 0, w, h); overlay.graphics.endFill();
			overlay.label("Turn your device sideways to race", 24, h / 2 - 50, w - 48, 120, 28, true, 0xFFFFFF); return;
		}
		if (panelKind == "") return;
		overlay.graphics.beginFill(0x0A1F33, .6); overlay.graphics.drawRect(0, 0, w, h); overlay.graphics.endFill();
		var pw = Math.min(600, w - 32); var px = (w - pw) / 2;
		overlay.panel(px, 12, pw, h - 28);
		overlay.label(panelKind == "chat" ? "Race chat" : panelKind == "music" ? "Choose music" : editorTestRestart != null ? "Test menu" : "Race menu", px + 20, 24, pw - 140, 38, 28, true);
		overlay.button("Back", px + pw - 100, 22, 80, function() openPanel(panelKind == "music" ? "menu" : ""));
		if (panelKind == "music" && course != null) {
			songList = new MobileScrollPane(); overlay.addChild(songList); songList.x = px + 20; songList.y = 78;
			var songs = course.musicSelection.availableSongs();
			for (i in 0...songs.length) {
				var song = songs[i];
				songList.content.button(song.label, 0, i * 54, pw - 44, function() { course.musicSelection.setSong(song.id); openPanel("menu"); }, song.id == course.musicSelection.selectedSongId(), 46);
			}
			songList.setSize(pw - 40, h - 110, songs.length * 54);
		} else if (panelKind == "menu" && editorTestRestart != null) {
			overlay.label("Test your draft before saving it.", px + 20, 75, pw - 40, 28, 15);
			var cell = (pw - 56) / 2;
			overlay.button("Back to editor", px + 20, 115, cell, function() { openPanel(""); quit(); }, true, 50);
			overlay.button("Restart", px + 36 + cell, 115, cell, function() { openPanel(""); editorTestRestart(); }, false, 50);
			overlay.button("Stats", px + 20, 179, cell, function() { openPanel(""); editorTestStats(); }, false, 50);
			overlay.button("Hats", px + 36 + cell, 179, cell, function() { openPanel(""); editorTestHats(); }, false, 50);
			overlay.button("Music", px + 20, 243, pw - 40, function() openPanel("music"), false, 50);
		} else if (panelKind == "chat" && course != null && course.raceChat != null) {
			transcript = overlay.label("", px + 20, 72, pw - 40, h - 166, 16);
			transcript.mouseEnabled = true; transcript.selectable = true;
			transcript.htmlText = course.raceChat.outputHtml(); lastChat = course.raceChat.outputHtml();
			transcript.scrollV = transcript.maxScrollV;
			chatLinks = new pr2.lobby.chat.HtmlNameMaker(); chatLinks.listenForLink(transcript);
			var input = overlay.own(new AuthInput()); input.x = px + 20; input.y = h - 80; input.setSize(pw - 140, 44); input.textField.maxChars = 100;
			var send = function() { course.raceChat.submitText(input.textField.text); input.textField.text = ""; };
			input.textField.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, function(e:openfl.events.KeyboardEvent) { if (e.keyCode == openfl.ui.Keyboard.ENTER) send(); });
			overlay.button("Send", px + pw - 108, h - 80, 88, send);
		} else if (panelKind == "quit") {
			overlay.label("Leave this race?", px + 20, 94, pw - 40, 44, 24, true);
			overlay.button("Keep racing", px + 20, 160, (pw - 52) / 2, function() openPanel(""), true);
			overlay.button("Quit race", px + pw / 2 + 6, 160, (pw - 52) / 2, function() { openPanel(""); quit(); });
		} else {
			overlay.label("Online race continues while this menu is open.", px + 20, 70, pw - 40, 28, 15);
			overlay.button(pr2.audio.AudioMute.muted ? "Sound: off" : "Sound: on", px + 20, 104, (pw - 52) / 2, function() { pr2.audio.AudioMute.setMuted(!pr2.audio.AudioMute.muted); drawPanel(); });
			overlay.button(isDone() ? "Results" : "Quit race", px + pw / 2 + 6, 104, (pw - 52) / 2, function() { if (isDone()) { openPanel(""); quit(); } else openPanel("quit"); });
			if (course != null) {
				var state = course.localCharacter.stateSnapshot();
				overlay.label('Speed: ${Math.round(state.speedStat)}    Accel: ${Math.round(state.accelerationStat)}    Jump: ${Math.round(state.jumpStat)}', px + 20, 160, pw - 40, 30, 16);
				var track = course.musicSelection.dropdown.selectedItem;
				overlay.button("Music: " + (track == null ? "None" : track.label), px + 20, 194, pw - 40, function() openPanel("music"));
				if (course.canSpectate) {
					overlay.button("Next racer", px + 20, 250, (pw - 52) / 2, function() {
						var ids = [for (p in course.playerArray) if (p != null) p.tempID];
						if (ids.length > 0) { var i = ids.indexOf(course.spectatePicker.pickedID); course.spectatePicker.setPlayer(ids[(i + 1) % ids.length]); }
						openPanel("");
					});
					overlay.button("Free camera", px + pw / 2 + 6, 250, (pw - 52) / 2, function() { course.spectatePicker.stopSpectating(); openPanel(""); });
				}
			}
		}
	}
	private function refresh(_:Event):Void {
		if (_ != null && !pr2.runtime.FrameClock.shouldRunSimulationFrame()) return;
		if (course == null || clock == null) return;
		clock.text = course.timer.debugText() == "" ? "--:--" : course.timer.debugText();
		clock.textColor = course.timer.debugTextColor() == 0xFF0000 ? 0xB32939 : 0x18334B;
		if (course.miniMap != lastMap) attachMap(Math.max(80, w - inset * 2 - 316));
		var hasItem = course.itemDisplay.itemCode != 0 && !done;
		if (!hasItem && item.active) item.release();
		item.visible = hasItem; jump.visible = !done;
		stick.visible = !done || (course.canSpectate && course.playerSpectating == null);
		status.text = done ? course.playerSpectating == null ? "Race finished" : "Watching " + course.playerSpectating.getName() : !course.raceStarted ? "Get ready…" : "";
		if (transcript != null && course.raceChat != null && lastChat != course.raceChat.outputHtml()) {
			lastChat = course.raceChat.outputHtml(); transcript.htmlText = lastChat; transcript.scrollV = transcript.maxScrollV;
		}
	}
	override public function setDone():Void { done = true; cancel(null); panelKind = ""; drawPanel(); refresh(null); }
	override public function setResultsOpen(value:Bool):Void { resultsOpen = value; cancel(null); drawPanel(); }
	override public function placeEvent(display:DisplayObject):Void { eventViews.push(display); display.x = w / 2; display.y = h / 2; }
	override public function remove():Void {
		if (songList != null) { songList.remove(); songList = null; }
		if (chatLinks != null) { chatLinks.remove(); chatLinks = null; }
		cancel(null); jump.dispose(); item.dispose(); stick.dispose();
		removeEventListener(Event.ADDED_TO_STAGE, added); removeEventListener(Event.ENTER_FRAME, refresh);
		if (ownerStage != null) { ownerStage.removeEventListener(Event.RESIZE, resize); ownerStage.removeEventListener(Event.DEACTIVATE, cancel); Multitouch.inputMode = oldTouchMode; }
		#if (js && html5)
		js.Browser.window.removeEventListener("touchcancel", browserCancel);
		js.Browser.window.removeEventListener("blur", browserCancel);
		js.Browser.document.removeEventListener("visibilitychange", browserCancel);
		#end
		view.remove(); overlay.remove(); super.remove();
	}
}
