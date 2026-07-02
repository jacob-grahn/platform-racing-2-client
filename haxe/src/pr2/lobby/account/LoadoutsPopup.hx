package pr2.lobby.account;

import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.Popup;
import pr2.runtime.FlButton;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Flash-faithful loadout chooser built from `GetLevelsPopupGraphic`. */
class LoadoutsPopup extends Popup {
	private var character:Null<AccountCharacter>;
	private var stats:Null<StatsSelect>;
	private var display:Null<PlayerDisplay>;
	private var art:Null<PR2MovieClip>;
	private var holder:Null<DisplayObjectContainer>;
	private var listings:Array<LoadoutListing> = [];
	private var selected:Null<LoadoutListing>;
	private var loadButton:Null<FlButton>;
	private var saveButton:Null<FlButton>;
	private var cancelBinding:Null<LobbyArt.Binding>;
	private var loadBinding:Null<LobbyArt.Binding>;
	private var saveBinding:Null<LobbyArt.Binding>;

	public function new(character:Null<AccountCharacter>, stats:Null<StatsSelect>, display:Null<PlayerDisplay>) {
		super();
		this.character = character;
		this.stats = stats;
		this.display = display;
		art = PR2MovieClip.fromLinkage("GetLevelsPopupGraphic", {maxNestedDepth: 8});
		addChild(art);

		var title = LobbyArt.text(art, "titleBox");
		if (title != null) title.text = "-- Loadouts --";
		var loading = DisplayUtil.findByName(art, "loadingGraphic");
		if (loading != null && loading.parent != null) loading.parent.removeChild(loading);
		holder = Std.downcast(DisplayUtil.findByName(art, "levelsHolder"), DisplayObjectContainer);
		loadButton = Std.downcast(DisplayUtil.findByName(art, "load_bt"), FlButton);
		saveButton = Std.downcast(DisplayUtil.findByName(art, "delete_bt"), FlButton);
		if (saveButton != null) saveButton.label = "Save";

		for (preset in Presets.getPresets()) addListing(preset);
		cancelBinding = LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), startFadeOut);
		loadBinding = LobbyArt.bind(loadButton, applySelected);
		saveBinding = LobbyArt.bind(saveButton, saveSelected);
		if (holder != null) holder.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		updateButtons();
	}

	private function addListing(preset:Preset):Void {
		if (holder == null) return;
		var listing = new LoadoutListing(preset);
		listing.y = listings.length * 68;
		listing.addEventListener(MouseEvent.CLICK, onListingClick);
		listing.addEventListener(MouseEvent.DOUBLE_CLICK, onListingDoubleClick);
		holder.addChild(listing);
		listings.push(listing);
	}

	private function onListingClick(e:MouseEvent):Void {
		select(Std.downcast(e.currentTarget, LoadoutListing));
	}

	private function onListingDoubleClick(e:MouseEvent):Void {
		select(Std.downcast(e.currentTarget, LoadoutListing));
		applySelected();
	}

	private function select(value:Null<LoadoutListing>):Void {
		selected = value;
		for (listing in listings) listing.setSelected(listing == selected);
		updateButtons();
	}

	private function updateButtons():Void {
		if (loadButton != null) loadButton.enabled = selected != null;
		if (saveButton != null) saveButton.enabled = selected != null;
	}

	private function applySelected():Void {
		if (selected == null) return;
		if (character != null && stats != null && display != null) Presets.apply(selected.preset, character, stats, display);
		startFadeOut();
	}

	private function saveSelected():Void {
		if (selected == null || character == null || stats == null || display == null) return;
		var preset = selected.preset;
		var values = stats.getStats();
		preset.speed = values.speed;
		preset.acceleration = values.acceleration;
		preset.jumping = values.jumping;
		preset.hat = character.hat1;
		preset.head = character.head;
		preset.body = character.body;
		preset.feet = character.feet;
		preset.hatColor = character.hat1Color;
		preset.headColor = character.headColor;
		preset.bodyColor = character.bodyColor;
		preset.feetColor = character.feetColor;
		preset.hatColor2 = display.hatSelect.getColorCP2();
		preset.headColor2 = display.headSelect.getColorCP2();
		preset.bodyColor2 = display.bodySelect.getColorCP2();
		preset.feetColor2 = display.feetSelect.getColorCP2();
		Presets.savePresets();
		startFadeOut();
	}

	private function onWheel(e:MouseEvent):Void {
		if (holder == null) return;
		var minY = Math.min(0, 158 - listings.length * 68);
		holder.y = Math.max(minY - 85, Math.min(-85, holder.y + e.delta * 12));
	}

	override public function remove():Void {
		LobbyArt.unbind(cancelBinding);
		LobbyArt.unbind(loadBinding);
		LobbyArt.unbind(saveBinding);
		if (holder != null) holder.removeEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		for (listing in listings) listing.remove();
		listings = [];
		holder = null;
		selected = null;
		loadButton = null;
		saveButton = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		character = null;
		stats = null;
		display = null;
		super.remove();
	}
}

private class LoadoutListing extends Sprite {
	public final preset:Preset;
	private var art:Null<PR2MovieClip>;
	private var preview:Null<AccountCharacter>;
	private var selected:Bool = false;

	public function new(preset:Preset) {
		super();
		this.preset = preset;
		mouseChildren = false;
		doubleClickEnabled = true;
		buttonMode = true;
		art = PR2MovieClip.fromLinkage("PresetListingGraphic", {maxNestedDepth: 4});
		art.gotoAndStop("up");
		setText("loadoutSpeed", "Speed: " + preset.speed);
		setText("loadoutAccel", "Acceleration: " + preset.acceleration);
		setText("loadoutJump", "Jumping: " + preset.jumping);
		setText("loadoutNum", Std.string(preset.num));
		addChild(art);
		preview = new AccountCharacter(preset.hat, preset.head, preset.body, preset.feet);
		preview.setColors(preset.hatColor, preset.hatColor2, preset.headColor, preset.headColor2,
			preset.bodyColor, preset.bodyColor2, preset.feetColor, preset.feetColor2);
		// PresetListing.as compensates for CharacterGraphic's authored 0.15
		// animation transform to produce a final thumbnail scale of 0.13.
		preview.scaleX = preview.scaleY = 0.13 * (1 / AccountCharacter.INTERNAL_GRAPHIC_SCALE);
		preview.x = 58;
		preview.y = 61;
		art.addChild(preview);
		addEventListener(MouseEvent.ROLL_OVER, onOver);
		addEventListener(MouseEvent.ROLL_OUT, onOut);
	}

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.text(art, name);
		if (field != null) field.text = value;
	}

	public function setSelected(value:Bool):Void {
		selected = value;
		if (art != null) art.gotoAndStop(value ? "selected" : "up");
	}

	private function onOver(_:MouseEvent):Void {
		if (!selected && art != null) art.gotoAndStop("over");
	}

	private function onOut(_:MouseEvent):Void {
		if (!selected && art != null) art.gotoAndStop("up");
	}

	public function remove():Void {
		removeEventListener(MouseEvent.ROLL_OVER, onOver);
		removeEventListener(MouseEvent.ROLL_OUT, onOut);
		if (preview != null) {
			preview.remove();
			preview = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) parent.removeChild(this);
	}
}
