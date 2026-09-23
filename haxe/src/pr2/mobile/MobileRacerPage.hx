package pr2.mobile;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.app.ScreenFactory;
import pr2.character.Parts;
import pr2.lobby.LobbySession;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.account.AccountCustomizeData;
import pr2.lobby.account.CustomizationRules;
import pr2.lobby.account.ManualPart;
import pr2.lobby.account.PartDetails;
import pr2.lobby.account.Presets;
import pr2.lobby.account.RacerModel;
import pr2.lobby.account.Settings;
import pr2.lobby.dialogs.Popup;
import pr2.net.CommandHandler;
import pr2.page.Page;
import pr2.page.auth.AuthDialog;
import pr2.mobile.MobileAuthControls.AuthInput;

/** Landscape account editor. Network/state rules have no dependency on this view. */
class MobileRacerPage extends Page {
	private final model = new RacerModel();
	private final view = new LobbyView();
	private final pane = new MobileScrollPane();
	private var character:AccountCharacter;
	private var confirmation:AuthDialog;
	private var mode = "Style";
	private var selectedPart = "head";
	private var secondColor = false;
	private var draftColor = 0;
	private var draftHex = "000000";
	private var advanced:pr2.lobby.account.ColorPickerPopup;
	private var message = "";
	private var w:Float = 756;
	private var h:Float = 284;
	private var side:Float = 218;
	private var disposedPage = false;
	private var statsDirty = false;
	private var ownerStage:openfl.display.Stage;
	public function new() { super(); addChild(view); addChild(pane); }
	override public function initialize():Void {
		ownerStage = AppStage.stage;
		CommandHandler.commandHandler.defineCommand("setCustomizeInfo", receive);
		LobbySession.onAccountChange(refresh);
		ManualPart.dispatcher.addEventListener(ManualPart.CHANGE, manualPart);
		if (ownerStage != null) {
			ownerStage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			ownerStage.addEventListener(KeyboardEvent.KEY_UP, flushStats);
			ownerStage.addEventListener(openfl.events.MouseEvent.MOUSE_UP, flushStats);
			ownerStage.addEventListener(Event.DEACTIVATE, flushStats);
		}
		refresh();
	}
	private function refresh():Void { flushStats(); message = "Loading your racer…"; model.session.refresh(); draw(); }
	private function flushStats(?_:Event):Void { if (statsDirty) { statsDirty = false; model.save(); } }
	private function receive(args:Array<String>):Void {
		if (disposedPage) return;
		var data = AccountCustomizeData.parse(args);
		if (data == null) { message = "Couldn't read racer data. Try again."; draw(); return; }
		model.accept(data); message = "";
		if (character == null) character = new AccountCharacter(data.hat, data.head, data.body, data.feet);
		model.paint(character); draw();
	}
	public function setLayout(width:Float, height:Float):Void {
		flushStats();
		w = width; h = height; side = Math.min(228, w * .30); draw();
		if (confirmation != null && ownerStage != null) confirmation.resizeViewport(ownerStage.stageWidth, ownerStage.stageHeight);
		placeAdvanced();
	}
	private function choose(value:String):Void { flushStats(); mode = value; message = ""; pane.reset(); if (character != null) model.paint(character); draw(); }
	private function changed():Void { model.paint(character); model.save(); draw(); }
	private function draw():Void {
		if (disposedPage) return;
		var offset = pane.content.y;
		view.clear(); pane.content.clear();
		view.panel(0, 0, side, h - 4); view.panel(side + 12, 0, w - side - 12, h - 4);
		if (model.data == null) {
			view.label(message, 20, 24, w - 40, 70, 22, true);
			view.button("Retry", 20, 110, 120, refresh); pane.visible = false; return;
		}
		pane.visible = true;
		view.singleLine(LobbySession.userName, 14, 10, side - 28, 30, 23, true);
		view.label("Rank " + model.session.rank + " • " + Std.int(Math.max(0, model.data.hats.length - 1)) + " hats", 14, 42, side - 28, 26, 15);
		character.scaleX = character.scaleY = Math.min(2.2, (h - 128) / 90);
		character.x = side / 2; character.y = h - 68; character.mouseEnabled = false; character.mouseChildren = false;
		view.addChild(character);
		if (LobbySession.guildId != 0) view.button(LobbySession.guildName, 12, h - 58, side - 24, function() pr2.ui.GuildName.popupFactory(LobbySession.guildId));
		else view.label("Guild: none", 14, h - 50, side - 28, 24, 15);
		var right = w - side - 40;
		for (i in 0...3) {
			var label = ["Style", "Stats", "Loadouts"][i];
			view.button(label, side + 26 + i * (right + 8) / 3, 12, (right - 16) / 3, function() choose(label), mode == label);
		}
		pane.x = side + 26; pane.y = 66;
		var v = pane.content;
		var total:Float = switch mode {
			case "Stats": drawStats(v, right);
			case "Loadouts": drawLoadouts(v, right);
			case "Catalog": drawCatalog(v, right);
			case "Color": drawColor(v, right);
			default: drawStyle(v, right);
		};
		pane.setSize(right, Math.max(64, h - 82), total + 6); pane.setOffset(offset);
	}
	private function drawStyle(v:LobbyView, width:Float):Float {
		var y:Float = 0;
		for (part in RacerModel.PARTS) {
			if (part == "hat" && model.data.hats.length <= 1) continue;
			var id = model.value(part), name = Parts.getName(part, id);
			v.singleLine(part.toUpperCase() + " • " + name, 0, y, width, 24, 16, true);
			v.button("‹", 0, y + 28, 44, function() { model.step(part, -1); changed(); });
			v.button("›", 50, y + 28, 44, function() { model.step(part, 1); changed(); });
			v.button("Parts", 102, y + 28, width - 210, function() { selectedPart = part; choose("Catalog"); });
			swatch(v, width - 100, y + 28, model.value(part + "Color"), "Primary " + part + " color", function() editColor(part, false));
			if (model.epic(part)) swatch(v, width - 48, y + 28, model.secondary(part), "Epic " + part + " color", function() editColor(part, true));
			y += 84;
		}
		v.button("Randomize style", 0, y, width, function() { model.randomize(); changed(); });
		v.label("Changes apply automatically.", 0, y + 52, width, 24, 14);
		return y + 82;
	}
	private function swatch(v:LobbyView, x:Float, y:Float, color:Int, name:String, action:Void->Void):Void {
		var button = v.button("", x, y, 44, action); button.name = name;
		var chip = new openfl.display.Shape(); chip.graphics.lineStyle(1, 0x18334B); chip.graphics.beginFill(color < 0 ? 0 : color);
		chip.graphics.drawRoundRect(0, 0, 28, 28, 6, 6); chip.graphics.endFill(); chip.x = x + 8; chip.y = y + 8; v.addChild(chip);
	}
	private function drawStats(v:LobbyView, width:Float):Float {
		var remaining = v.label(model.remaining() + " points remaining" + (model.data.happyHour ? " • Happy Hour!" : ""), 0, 0, width, 32, 18, true);
		for (i in 0...3) {
			var field = RacerModel.STATS[i], y = 38 + i * 80;
			var label = v.label(field.toUpperCase() + "  " + model.value(field), 0, y, width, 26, 16, true);
			var slider = v.own(new MobileValueSlider(100, model.value(field)));
			slider.x = 58; slider.y = y + 26; slider.setSize(width - 116, 44);
			function update(next:Int):Void {
				model.stat(field, next); slider.value = model.value(field);
				label.text = field.toUpperCase() + "  " + model.value(field);
				remaining.text = model.remaining() + " points remaining" + (model.data.happyHour ? " • Happy Hour!" : "");
				statsDirty = true;
			}
			slider.onChange = function(value) update(Std.int(value));
			slider.onRelease = function() flushStats();
			v.button("−", 0, y + 26, 44, function() { update(model.value(field) - 1); flushStats(); });
			v.button("+", width - 44, y + 26, 44, function() { update(model.value(field) + 1); flushStats(); });
		}
		v.label("RANK TOKENS", 0, 286, width, 28, 18, true);
		v.label(model.session.used + " used • " + (model.session.available - model.session.used) + " available", 0, 316, width, 28, 16);
		v.button("Remove token", 0, 350, (width - 12) / 2, function() token(false)).enabled = model.session.used > 0;
		v.button("Use token", (width + 12) / 2, 350, (width - 12) / 2, function() token(true), true).enabled = model.session.used < model.session.available;
		return 400;
	}
	private function token(add:Bool):Void { model.save(); model.session.token(add); draw(); }
	private function drawLoadouts(v:LobbyView, width:Float):Float {
		v.label(message == "" ? "Ten loadouts, saved on this device." : message, 0, 0, width, 44, 16);
		for (i in 1...11) {
			var slot = i, preset = Presets.getPreset(i), y = 50 + (i - 1) * 96;
			v.label("LOADOUT " + i + "  •  " + preset.speed + " / " + preset.acceleration + " / " + preset.jumping, 0, y, width, 28, 17, true);
			v.button("Equip", 0, y + 34, (width - 12) / 2, function() equip(slot), true);
			v.button("Save here", (width + 12) / 2, y + 34, (width - 12) / 2, function() {
				confirm("Replace loadout " + slot + "?", "Save your current style and stats in this slot?", function() {
					if (!Settings.isNameSet()) { message = "You are not logged in."; draw(); return; }
					model.savePreset(slot); message = "Saved loadout " + slot + " on this device."; draw();
				});
			});
		}
		return 1010;
	}
	private function equip(slot:Int):Void {
		confirm("Equip loadout " + slot + "?", "This replaces your current style and stats.", function() {
			if (!Settings.isNameSet()) { message = "You are not logged in."; chooseMessageLoadouts(); return; }
			model.applyPreset(Presets.getPreset(slot)); changed();
		});
	}
	private function chooseMessageLoadouts():Void { mode = "Loadouts"; pane.reset(); draw(); }
	private function drawCatalog(v:LobbyView, width:Float):Float {
		v.button("Back to style", 0, 0, width, function() choose("Style"));
		var y:Float = 58;
		var ids = Parts.getPartArray(selectedPart);
		if (ids == null) return y;
		for (id in ids) {
			var owned = model.owned(selectedPart).indexOf(Std.string(id)) >= 0;
			var epic = CustomizationRules.epic(model.epics(selectedPart), id);
			v.label(Parts.getName(selectedPart, id) + (owned ? (epic ? " • Epic" : " • Owned") : " • Locked"), 0, y, width, 28, 18, true);
			var description = Parts.getDesc(selectedPart, id), obtain = PartDetails.mobileObtainText(Parts.getObtain(selectedPart, id));
			var text = v.label("", 0, y + 30, width, 80, 15);
			text.htmlText = (description == null ? "" : description) + (obtain == "" ? "" : "<br/>" + obtain);
			text.height = Math.max(30, text.textHeight + 8);
			y += 34 + text.height;
			var part = selectedPart;
			v.button("Details", 0, y, (width - 12) / 2, function() {
				ScreenFactory.partInfo(part, id, Parts.getName(part, id), description, obtain, owned,
					model.epics(part).indexOf(Std.string(id)) >= 0, model.epics(part).indexOf("*") >= 0);
			});
			if (owned) v.button(model.value(part) == id ? "Equipped" : "Equip", (width + 12) / 2, y, (width - 12) / 2,
				function() { model.select(part, id); changed(); }, model.value(part) == id);
			y += 54;
			y += 16;
		}
		return y;
	}
	private function editColor(part:String, second:Bool):Void {
		selectedPart = part; secondColor = second;
		draftColor = model.value(part + (second ? "Color2" : "Color")); if (draftColor < 0) draftColor = 0;
		draftHex = StringTools.hex(draftColor, 6);
		choose("Color");
	}
	private function drawColor(v:LobbyView, width:Float):Float {
		v.label((secondColor ? "EPIC " : "PRIMARY ") + selectedPart.toUpperCase() + " COLOR", 0, 0, width, 28, 18, true);
		var input = v.own(new AuthInput(draftHex));
		input.x = 0; input.y = 34; input.setSize(width - 116, 44);
		input.textField.restrict = "0-9a-fA-F"; input.textField.maxChars = 6;
		input.onChange = function(value) {
			draftHex = value;
			if (~/^[0-9a-fA-F]{6}$/.match(value)) draftColor = Std.parseInt("0x" + value);
		};
		var error = v.label("", 0, 84, width, 26, 14, false, 0xA52735);
		v.button("Apply", width - 104, 34, 104, function() {
			if (!~/^[0-9a-fA-F]{6}$/.match(input.text)) { error.text = "Enter six hex digits, such as FFCC99."; return; }
			applyColor(Std.parseInt("0x" + input.text));
		}, true);
		var labels = ["Red", "Green", "Blue"];
		for (i in 0...3) {
			var shift = (2 - i) * 8, y = 112 + i * 76;
			var label = v.label(labels[i] + "  " + ((draftColor >> shift) & 255), 0, y, width, 24, 16);
			var slider = v.own(new MobileValueSlider(255, (draftColor >> shift) & 255));
			slider.x = 14; slider.y = y + 24; slider.setSize(width - 28, 44);
			slider.onChange = function(value) {
				draftColor = (draftColor & ~(255 << shift)) | (Std.int(value) << shift);
				label.text = labels[i] + "  " + Std.int(value); input.text = draftHex = StringTools.hex(draftColor, 6);
			};
		}
		v.button("Cancel", 0, 344, width, function() choose("Style"));
		v.button("Advanced color picker", 0, 398, width, openAdvanced);
		var colors:Array<Int> = [];
		for (column in pr2.lobby.account.ColorChoices.populate(pr2.lobby.account.ColorPicker.recentColors))
			for (color in column) if (colors.indexOf(color) < 0) colors.push(color);
		var columns = Std.int(width / 52);
		for (i in 0...colors.length) {
			var color = colors[i];
			swatch(v, (i % columns) * 52, 456 + Std.int(i / columns) * 52, color, "Color " + StringTools.hex(color, 6), function() applyColor(color));
		}
		return 460 + Math.ceil(colors.length / columns) * 52;
	}
	private function openAdvanced():Void {
		if (advanced != null) return;
		advanced = new pr2.lobby.account.ColorPickerPopup(draftColor);
		advanced.addEventListener(Event.CLOSE, advancedClosed);
		if (ownerStage != null) ownerStage.addChild(advanced); else addChild(advanced);
		advanced.init(); placeAdvanced();
	}
	private function placeAdvanced():Void {
		if (advanced == null || ownerStage == null) return;
		advanced.x = Math.max(0, (ownerStage.stageWidth - advanced.width) / 2);
		advanced.y = Math.max(0, (ownerStage.stageHeight - advanced.height) / 2);
	}
	private function advancedClosed(_:Event):Void {
		var color = advanced.getColor(); advanced.removeEventListener(Event.CLOSE, advancedClosed); advanced = null;
		if (!disposedPage) applyColor(color);
	}
	private function applyColor(color:Int):Void {
		model.color(selectedPart, secondColor, color);
		var recent = pr2.lobby.account.ColorPicker.recentColors;
		recent.remove(color); recent.unshift(color); if (recent.length > 12) recent.resize(12);
		mode = "Style"; pane.reset(); changed();
	}
	private function manualPart(_:Event):Void {
		if (model.data == null || ManualPart.selection.length != 2) return;
		model.select(Std.string(ManualPart.selection[0]), Std.int(ManualPart.selection[1])); changed(); model.session.refresh();
	}
	private function confirm(title:String, text:String, action:Void->Void):Void {
		if (confirmation != null) return;
		confirmation = ScreenFactory.authDialog("Confirm", text, ["heading" => title, "confirmLabel" => "Continue", "cancelLabel" => "Cancel"]);
		confirmation.onCancel = closeConfirm; confirmation.onConfirm = function() { closeConfirm(); if (!disposedPage) action(); };
		// Use stage coordinates so this isn't clipped by the lobby's content pane.
		if (ownerStage != null) { ownerStage.addChild(confirmation); confirmation.resizeViewport(ownerStage.stageWidth, ownerStage.stageHeight); }
		else { addChild(confirmation); confirmation.resizeViewport(w, h); }
	}
	private function closeConfirm():Void { if (confirmation != null) confirmation.dismiss(true); confirmation = null; }
	private function keyDown(e:KeyboardEvent):Void {
		if (disposedPage || model.data == null || confirmation != null || advanced != null || Popup.getOpen().length > 0 || !visibleInTree()) return;
		if (ownerStage != null && ownerStage.stageHeight > ownerStage.stageWidth) return;
		if (e.keyCode == 9 && ownerStage != null) {
			var candidates = view.controls.concat(pane.content.controls).filter(function(c) return c.enabled);
			var index = -1;
			for (i in 0...candidates.length) if (ownerStage.focus != null && (candidates[i] == ownerStage.focus || candidates[i].contains(ownerStage.focus))) index = i;
			if (candidates.length > 0) {
				index = index == -1 ? (e.shiftKey ? candidates.length - 1 : 0) : (index + (e.shiftKey ? candidates.length - 1 : 1)) % candidates.length;
				var target = candidates[index]; pr2.ui.controls.NativeControl.showFocusIndicator = true; target.focus();
				if (pane.content.contains(target)) {
					var bottom = target.y + target.height + pane.content.y;
					if (bottom > pane.scrollRect.height) pane.setOffset(pane.content.y - bottom + pane.scrollRect.height);
					if (target.y + pane.content.y < 0) pane.setOffset(-target.y);
				}
			}
			e.preventDefault(); e.stopImmediatePropagation(); return;
		}
		var field = Std.downcast(e.target, TextField); if (field != null && field.selectable) return;
		var slot = CustomizationRules.keyToSlot(e.keyCode);
		if (slot > 0) { e.preventDefault(); equip(slot); }
	}
	private function visibleInTree():Bool {
		var current:openfl.display.DisplayObject = this;
		while (current != null) { if (!current.visible) return false; current = current.parent; }
		return true;
	}
	override public function remove():Void {
		if (disposedPage) return; flushStats(); disposedPage = true;
		closeConfirm(); LobbySession.offAccountChange(refresh);
		if (advanced != null) { advanced.removeEventListener(Event.CLOSE, advancedClosed); advanced.remove(); advanced = null; }
		ManualPart.dispatcher.removeEventListener(ManualPart.CHANGE, manualPart);
		CommandHandler.commandHandler.defineCommand("setCustomizeInfo", null);
		if (ownerStage != null) {
			ownerStage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			ownerStage.removeEventListener(KeyboardEvent.KEY_UP, flushStats);
			ownerStage.removeEventListener(openfl.events.MouseEvent.MOUSE_UP, flushStats);
			ownerStage.removeEventListener(Event.DEACTIVATE, flushStats);
		}
		if (character != null) character.remove(); character = null;
		pane.remove(); view.remove(); super.remove();
	}
}
