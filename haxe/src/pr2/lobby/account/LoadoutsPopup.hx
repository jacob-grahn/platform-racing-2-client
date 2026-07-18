package pr2.lobby.account;

import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.Popup;
import pr2.levelEditor.GetLevelsView;
import pr2.ui.controls.GameButton;
import pr2.util.DisplayUtil;

/** Flash-faithful loadout chooser built from `GetLevelsPopupGraphic`. */
class LoadoutsPopup extends Popup {
	private var character:Null<AccountCharacter>;
	private var stats:Null<StatsSelect>;
	private var display:Null<PlayerDisplay>;
	private var art:Null<GetLevelsView>;
	private var holder:Null<DisplayObjectContainer>;
	private var listings:Array<LoadoutListing> = [];
	private var selected:Null<LoadoutListing>;
	private var loadButton:Null<GameButton>;
	private var saveButton:Null<GameButton>;
	private var cancelBinding:Null<LobbyArt.Binding>;
	private var loadBinding:Null<LobbyArt.Binding>;
	private var saveBinding:Null<LobbyArt.Binding>;

	public function new(character:Null<AccountCharacter>, stats:Null<StatsSelect>, display:Null<PlayerDisplay>) {
		super();
		this.character = character;
		this.stats = stats;
		this.display = display;
		art = new GetLevelsView();
		addChild(art);

		var title = LobbyArt.directText(art, "titleBox");
		if (title != null) title.text = "-- Loadouts --";
		var loading = DisplayUtil.directChildByName(art, "loadingGraphic");
		if (loading != null && loading.parent != null) loading.parent.removeChild(loading);
		holder = Std.downcast(DisplayUtil.directChildByName(art, "levelsHolder"), DisplayObjectContainer);
		loadButton = Std.downcast(DisplayUtil.directChildByName(art, "load_bt"), GameButton);
		saveButton = Std.downcast(DisplayUtil.directChildByName(art, "delete_bt"), GameButton);
		if (saveButton != null) saveButton.label = "Save";

		for (preset in Presets.getPresets()) addListing(preset);
		cancelBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "cancel_bt"), startFadeOut);
		loadBinding = LobbyArt.bind(loadButton, applySelected);
		saveBinding = LobbyArt.bind(saveButton, saveSelected);
		if (holder != null) holder.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		updateButtons();
	}

	private function addListing(preset:Preset):Void {
		if (holder == null) return;
		var listing = new LoadoutListing(preset, display);
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

	public function previewsForTests():Array<AccountCharacter> {
		var previews:Array<AccountCharacter> = [];
		for (listing in listings) {
			var preview = listing.previewForTests();
			if (preview != null) previews.push(preview);
		}
		return previews;
	}

	public function listingArtForTests():Array<Sprite> {
		return [for (listing in listings) listing.artForTests()];
	}

	public function listingFillForTests(index:Int):Int return listings[index].fillForTests();
	public function selectListingForTests(index:Int):Void select(listings[index]);

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
	private var art:Null<Sprite>;
	private var preview:Null<AccountCharacter>;
	private var selected:Bool = false;
	private var currentFill:Int = 0x333333;
	private var background:Sprite;

	public function new(preset:Preset, playerDisplay:Null<PlayerDisplay>) {
		super();
		this.preset = preset;
		mouseChildren = false;
		doubleClickEnabled = true;
		buttonMode = true;
		art = new Sprite();
		background = new Sprite();
		background.name = "stateBackground";
		art.addChild(background);
		art.addChild(createText("loadoutNum", 10, 25, 23.5, 16, 19.45));
		art.addChild(createText("loadoutSpeed", 92, 7, 116, 12, 14.55));
		art.addChild(createText("loadoutAccel", 92, 27, 116, 12, 14.55));
		art.addChild(createText("loadoutJump", 92, 47, 116, 12, 14.55));
		redraw(0x333333, 0.101960784313725);
		setText("loadoutSpeed", "Speed: " + preset.speed);
		setText("loadoutAccel", "Acceleration: " + preset.acceleration);
		setText("loadoutJump", "Jumping: " + preset.jumping);
		setText("loadoutNum", Std.string(preset.num));
		addChild(art);
		preview = new AccountCharacter(preset.hat, preset.head, preset.body, preset.feet);
		var hatColor2 = playerDisplay != null && playerDisplay.hatSelect.isPartEpic(preset.hat) ? preset.hatColor2 : -1;
		var headColor2 = playerDisplay != null && playerDisplay.headSelect.isPartEpic(preset.head) ? preset.headColor2 : -1;
		var bodyColor2 = playerDisplay != null && playerDisplay.bodySelect.isPartEpic(preset.body) ? preset.bodyColor2 : -1;
		var feetColor2 = playerDisplay != null && playerDisplay.feetSelect.isPartEpic(preset.feet) ? preset.feetColor2 : -1;
		preview.setColors(preset.hatColor, hatColor2, preset.headColor, headColor2, preset.bodyColor, bodyColor2, preset.feetColor, feetColor2);
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
		var field = LobbyArt.directText(art, name);
		if (field != null) field.text = value;
	}

	private function createText(name:String, x:Float, y:Float, width:Float, size:Int, height:Float):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0, name == "loadoutNum");
		return field;
	}

	private function redraw(fill:Int, alpha:Float = 1):Void {
		if (art == null) return;
		currentFill = fill;
		background.graphics.clear();
		background.graphics.beginFill(fill, alpha);
		background.graphics.drawRect(0, 1, 248, 67);
		background.graphics.endFill();
	}

	public function setSelected(value:Bool):Void {
		selected = value;
		redraw(value ? 0x42D75F : 0x333333, value ? 1 : 0.101960784313725);
	}

	public function previewForTests():Null<AccountCharacter> {
		return preview;
	}

	public function artForTests():Sprite return art;
	public function fillForTests():Int return currentFill;

	private function onOver(_:MouseEvent):Void {
		if (!selected) redraw(0xCCCCCC);
	}

	private function onOut(_:MouseEvent):Void {
		if (!selected) redraw(0x333333, 0.101960784313725);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.ROLL_OVER, onOver);
		removeEventListener(MouseEvent.ROLL_OUT, onOut);
		if (preview != null) {
			preview.remove();
			preview = null;
		}
		if (art != null) {
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		if (parent != null) parent.removeChild(this);
	}
}
