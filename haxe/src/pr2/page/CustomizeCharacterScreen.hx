package pr2.page;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.geom.Point;
import pr2.Constants;
import pr2.character.CharacterView;
import pr2.character.CharacterRig;
import pr2.character.PhysicsParticle;
import pr2.character.Parts;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.account.AccountState;
import pr2.lobby.account.PlayerDisplay;
import pr2.runtime.FontResolver;

/**
	Standalone dev screen for the lobby character customizer: just the character
	preview plus the hat/head/body/feet part steppers and colour selectors (Flash
	`player_profile.PlayerDisplay`), without the surrounding Account tab chrome
	(rank tokens, stats, loadouts) or a live gameserver session.

	Reached via `?screen=customize_character`. Because there is no socket to send
	`get_customize_info`, the part lists are seeded from `Parts` with the full set
	of real part ids, so every part can be cycled and recoloured.
**/
class CustomizeCharacterScreen extends Sprite {
	private var character:Null<AccountCharacter>;
	private var playerDisplay:Null<PlayerDisplay>;
	private final parityViews:Array<CharacterView> = [];

	public function new(?parityCase:String) {
		super();

		graphics.beginFill(Constants.BACKGROUND_COLOR);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();
		if (parityCase != null && parityCase != "") {
			buildParityMatrix(parityCase);
			return;
		}

		var hats = ids(Parts.getPartArray("HAT"));
		var heads = ids(Parts.getPartArray("HEAD"));
		var bodies = ids(Parts.getPartArray("BODY"));
		var feet = ids(Parts.getPartArray("FEET"));
		var none:Array<String> = [];

		var hat = 1;
		var head = 1;
		var body = 1;
		var feetSel = 1;
		var hatColor = 0xFFFFFF;
		var headColor = 0xFFCC99;
		var bodyColor = 0x3399FF;
		var feetColor = 0x333333;

		character = new AccountCharacter(hat, head, body, feetSel);
		character.setColors(hatColor, -1, headColor, -1, bodyColor, -1, feetColor, -1);
		AccountState.currentHat = hat;

		// The controls live up-and-left of the character preview, matching the
		// relative placement in `AccountTab` (playerDisplay 23,95 / character 80,182).
		var group = new Sprite();

		playerDisplay = new PlayerDisplay(character, hats, heads, bodies, feet, hat, head, body, feetSel, hatColor, headColor, bodyColor, feetColor, none,
			none, none, none, -1, -1, -1, -1);
		playerDisplay.x = 0;
		playerDisplay.y = 0;
		group.addChild(playerDisplay);

		var characterHolder = new Sprite();
		characterHolder.addChild(character);
		characterHolder.x = 57;
		characterHolder.y = 87;
		characterHolder.scaleX = characterHolder.scaleY = 1.5;
		group.addChild(characterHolder);

		addChild(group);

		var bounds = group.getBounds(this);
		group.x = (Constants.STAGE_WIDTH - bounds.width) / 2 - bounds.x;
		group.y = (Constants.STAGE_HEIGHT - bounds.height) / 2 - bounds.y;
	}

	public function parityCount():Int return parityViews.length;
	public function parityView(index:Int):CharacterView return parityViews[index];

	private function buildParityMatrix(parityCase:String):Void {
		var normalized = StringTools.trim(parityCase).toLowerCase();
		var title = makeLabel('Character parity: $normalized', 0, 8, Constants.STAGE_WIDTH, 20, 13, true);
		addChild(title);
		if (StringTools.startsWith(normalized, "parts-")) {
			var page = Std.parseInt(normalized.substr("parts-".length));
			if (page == null || page < 0) throw 'Unknown character parity case $parityCase';
			addPartPage(page);
		} else if (StringTools.startsWith(normalized, "items-")) {
			var page = Std.parseInt(normalized.substr("items-".length));
			if (page == null || page < 0) throw 'Unknown character parity case $parityCase';
			addItemPage(page);
		} else switch (normalized) {
			case "default":
				var frames = [1, 8, 16, 24, 1, 4, 25, 50, 48];
				var states = ["stand", "stand", "stand", "stand", "run", "run", "jump", "superJump", "frozen"];
				for (index in 0...states.length) {
					var view = makeView(states[index], {head: 1, body: 1, feet: 1}, [1, 1, 1, 1]);
					view.gotoFrame(frames[index]);
					addParityCell('${states[index]} ${frames[index]}', view, index);
					if (index % 2 == 1) view.scaleX = -0.88;
				}
			case "colors":
				var palettes = [
					[0x2E8BFF, -1, 0xFFD24A, -1],
					[0x112233, 0x99CCFF, 0xCC3344, 0xFFCC66],
					[0x44AA55, 0xDDF7AA, 0x7733AA, 0xFF99DD],
					[0xF4F4F4, 0x555555, 0x111111, 0xAAAAAA],
					[0xFF7700, 0xFFFF33, 0x0066CC, 0x66DDFF],
					[0xCC2266, 0x66FFAA, 0x442288, 0xFFAA22],
					[0x000000, 0xFFFFFF, 0xFFFFFF, 0x000000],
					[0x3689E6, 0xCBE5FF, 0xE66A36, 0xFFE0CB],
					[0x4F8A10, 0xB8E986, 0x8A104F, 0xE986B8]
				];
				var hats = [1, 6, 5, 13, 16, 6, 5, 13, 16];
				for (index in 0...palettes.length) {
					var palette = palettes[index];
					var view = makeView("stand", {head: 23, body: 28, feet: 40}, [hats[index], 1, 1, 1]);
					view.setAppearance({head: 23, body: 28, feet: 40}, {
						head: {primary: palette[0], secondary: palette[1]},
						body: {primary: palette[2], secondary: palette[3]},
						feet: {primary: palette[0], secondary: palette[3]}
					});
					view.setHatSlotColors([{primary: palette[2], secondary: palette[1]}, emptyColor(), emptyColor(), emptyColor()]);
					view.gotoFrame(1 + index * 3);
					addParityCell('palette ${index + 1}', view, index);
				}
			case "mixed-parts":
				var states = CharacterView.STATE_NAMES;
				var items = ["Speed Burst", "Laser", "Mine", "Lightning", "Teleport", "Super Jump", "Jet Pack", "Sword", "Ice Wave"];
				var heads = [1, 14, 23, 37, 50, 9, 32, 44, 18];
				var bodies = [1, 14, 28, 35, 46, 9, 20, 31, 42];
				var feet = [1, 14, 40, 35, 45, 9, 20, 30, 43];
				for (index in 0...states.length) {
					var view = makeView(states[index], {head: heads[index], body: bodies[index], feet: feet[index]}, [index % 4 == 0 ? 6 : 1, 1, 1, 1]);
					view.gotoFrame(Std.int(Math.max(1, Math.ceil(view.frameCount / 2))));
					view.setItemFrameName(items[index]);
					if (items[index] == "Laser" || items[index] == "Sword") view.gotoItemActionFrame(7);
					if (items[index] == "Jet Pack") view.setJetActive(true);
					addParityCell('${states[index]} / ${items[index]}', view, index);
				}
			case "tricky-parts":
				addTrickyCases();
			case "all-hats":
				for (index in 0...8) {
					var first = 2 + index * 2;
					var second = first + 1 <= 16 ? first + 1 : 1;
					var view = makeView(index % 2 == 0 ? "stand" : "run", {head: 1 + index * 6, body: 1, feet: 1}, [first, second, 1, 1]);
					view.gotoFrame(1 + index % 6);
					addParityCell('hats $first${second > 1 ? "/" + second : ""}', view, index);
				}
				var shifted = makeView("stand", {head: 23, body: 28, feet: 40}, [6, 5, 13, 16]);
				addParityCell("head 23 / four hats", shifted, 8);
			case "fred-states":
				for (index in 0...CharacterView.STATE_NAMES.length) {
					var state = CharacterView.STATE_NAMES[index];
					var view = makeView(state, {head: 37, body: 29, feet: 40}, [6, 5, 13, 16]);
					view.gotoFrame(Std.int(Math.max(1, Math.ceil(view.frameCount / 2))));
					addParityCell('Fred / $state', view, index);
				}
			case "attachments":
				for (index in 0...CharacterView.STATE_NAMES.length) {
					var state = CharacterView.STATE_NAMES[index];
					var view = makeView(state, {head: 23, body: 28, feet: 40}, [6, 1, 1, 1]);
					view.gotoFrame(Std.int(Math.max(1, Math.ceil(view.frameCount / 2))));
					for (slot in ["head", "body", "frontFoot", "backFoot", "heldItem"]) addAttachmentMarker(view.effectTarget(slot));
					addParityCell('$state sockets', view, index);
				}
			case "djinn-ice":
				addDjinnIceCases();
			default:
				throw 'Unknown character parity case $parityCase';
		}
		var titleBand = new Shape();
		titleBand.graphics.beginFill(Constants.BACKGROUND_COLOR, 0.94);
		titleBand.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, 30);
		titleBand.graphics.endFill();
		addChild(titleBand);
		addChild(title);
	}

	private function addItemPage(page:Int):Void {
		var specs:Array<{name:String, frame:Int}> = [];
		var rig = CharacterRig.loadClassic();
		for (name in ["Speed Burst", "Laser", "Mine", "Lightning", "Teleport", "Super Jump", "Jet Pack", "Sword", "Ice Wave"]) {
			var item = CharacterRig.item(rig, name);
			if (item != null) for (frame in 1...item.frames.length + 1) specs.push({name: name, frame: frame});
		}
		var offset = page * 9;
		if (offset >= specs.length) throw 'Character item page $page is outside ${specs.length} frames';
		for (index in 0...9) {
			var specIndex = offset + index;
			if (specIndex >= specs.length) break;
			var spec = specs[specIndex];
			var state = CharacterView.STATE_NAMES[specIndex % CharacterView.STATE_NAMES.length];
			var view = makeView(state, {head: 23, body: 28, feet: 40}, [specIndex % 4 == 0 ? 6 : 1, 1, 1, 1]);
			view.gotoFrame(Std.int(Math.max(1, Math.ceil(view.frameCount / 2))));
			view.setItemFrameName(spec.name);
			view.gotoItemActionFrame(spec.frame);
			addParityCell('${spec.name} ${spec.frame} / $state', view, index);
			if (specIndex % 2 == 1) view.scaleX = -0.88;
		}
	}

	private function addPartPage(page:Int):Void {
		var specs:Array<{kind:String, id:Int}> = [];
		for (kind in ["head", "body", "feet"]) {
			var partIds = ids(Parts.getPartArray(kind.toUpperCase()));
			for (encoded in partIds) {
				var parsed = Std.parseInt(encoded);
				if (parsed != null && !(kind == "body" && parsed == 29)) specs.push({kind: kind, id: parsed});
			}
		}
		var offset = page * 9;
		if (offset >= specs.length) throw 'Character part page $page is outside ${specs.length} parts';
		for (index in 0...9) {
			var specIndex = offset + index;
			if (specIndex >= specs.length) break;
			var spec = specs[specIndex];
			var state = CharacterView.STATE_NAMES[specIndex % CharacterView.STATE_NAMES.length];
			var partIds = {head: 1, body: 1, feet: 1};
			Reflect.setField(partIds, spec.kind, spec.id);
			var view = makeView(state, partIds, [specIndex % 5 == 0 ? 6 : 1, 1, 1, 1]);
			view.setColors(specIndex % 2 == 0 ? 0x42A5F5 : 0xFF7043, specIndex % 3 == 0 ? 0xFFE082 : 0x81D4FA);
			view.gotoFrame(Std.int(Math.max(1, Math.ceil(view.frameCount / 2))));
			addParityCell('${spec.kind} ${spec.id} / $state', view, index);
			if (specIndex % 2 == 1) view.scaleX = -0.88;
		}
	}

	private function addDjinnIceCases():Void {
		for (index in 0...CharacterView.STATE_NAMES.length) {
			var state = CharacterView.STATE_NAMES[index];
			var view = makeView(state, {head: 23, body: 35, feet: 35}, [6, 1, 1, 1]);
			view.gotoFrame(Std.int(Math.max(1, Math.ceil(view.frameCount / 2))));
			addParityCell('$state djinn', view, index);
			if (index % 2 == 1) view.scaleX = -0.88;
			addDjinnParticle(view.effectTarget("body"), true, 0x89E8FF, 0.0, -15, -10);
			addDjinnParticle(view.effectTarget("body"), true, 0x245A9C, 0.999, 15, -10);
			for (slot in ["frontFoot", "backFoot"]) {
				addDjinnParticle(view.effectTarget(slot), false, 0xB8F4FF, 0.0, -2, -2);
				addDjinnParticle(view.effectTarget(slot), false, 0x3B78C8, 0.999, 2, 2);
			}
		}
	}

	private function addDjinnParticle(target:Sprite, bodyParticle:Bool, color:Int, randomValue:Float, offsetX:Float, offsetY:Float):Void {
		var point = globalToLocal(target.localToGlobal(new Point(offsetX, offsetY)));
		var particle = new PhysicsParticle({
			graphic: "DjinnIceGraphic",
			colors: [color],
			life: bodyParticle ? 16 : 8,
			startAlpha: bodyParticle ? 0.5 : 0.1,
			minVelAlpha: 0,
			maxVelAlpha: bodyParticle ? 0.5 : 0,
			minVelX: bodyParticle ? null : -2,
			maxVelX: bodyParticle ? null : 2,
			minVelY: bodyParticle ? 2 : null,
			maxVelY: bodyParticle ? 3 : null,
			velScaleX: 0.1,
			velScaleY: 0.1,
			fricX: bodyParticle ? 1.05 : null,
			fricY: bodyParticle ? 0.9 : null,
			minOffsetX: bodyParticle ? -5 : -5,
			maxOffsetX: bodyParticle ? 5 : 5,
			minOffsetY: bodyParticle ? -10 : -5,
			maxOffsetY: bodyParticle ? 10 : 5,
			minScale: bodyParticle ? -1 : 0.075,
			maxScale: bodyParticle ? -0.75 : 0.1,
			minX: point.x,
			maxX: point.x,
			minY: point.y,
			maxY: point.y
		}, function():Float return randomValue);
		particle.name = bodyParticle ? "djinnBodyParticle" : "djinnFeetParticle";
		addChild(particle);
	}

	private function addTrickyCases():Void {
		var fred = makeView("stand", {head: 37, body: 29, feet: 40}, [1, 1, 1, 1]);
		addParityCell("Fred", fred, 0);
		var fredHats = makeView("crouch", {head: 37, body: 29, feet: 40}, [6, 5, 13, 16]);
		fredHats.setHatSlotColors([
			{primary: 0xFF3333, secondary: 0xFFAAAA},
			{primary: 0x33AAFF, secondary: 0xAAEEFF},
			{primary: 0x55CC55, secondary: 0xCCFFCC},
			{primary: 0xAA55DD, secondary: 0xEECCFF}
		]);
		addParityCell("Fred / four hats", fredHats, 1);
		var shifted = makeView("run", {head: 23, body: 28, feet: 40}, [6, 5, 13, 16]);
		shifted.gotoFrame(4);
		addParityCell("head 23 / hats", shifted, 2);
		var extremes = makeView("swim", {head: 50, body: 46, feet: 45}, [16, 1, 1, 1]);
		extremes.setColors(0x101010, 0xF0F0F0);
		extremes.gotoFrame(7);
		addParityCell("extreme silhouettes", extremes, 3);
		var frozen = makeView("frozen", {head: 44, body: 42, feet: 43}, [13, 1, 1, 1]);
		frozen.gotoFrame(frozen.frameCount);
		addParityCell("frozen complete", frozen, 4);
		var bumped = makeView("bumped", {head: 32, body: 31, feet: 30}, [5, 1, 1, 1]);
		bumped.gotoFrame(bumped.frameCount);
		addParityCell("bumped end", bumped, 5);
		var jet = makeView("superJump", {head: 18, body: 20, feet: 20}, [6, 1, 1, 1]);
		jet.gotoFrame(25);
		jet.setItemFrameName("Jet Pack");
		jet.setJetActive(true);
		jet.setJetFlame(0.625, 0.875);
		addParityCell("jet / flame", jet, 6);
		var sword = makeView("stand", {head: 9, body: 9, feet: 9}, [1, 1, 1, 1]);
		sword.setItemFrameName("Sword");
		sword.gotoItemActionFrame(7);
		addParityCell("sword frame 7", sword, 7);
		var attachments = makeView("jump", {head: 1, body: 1, feet: 1}, [6, 1, 1, 1]);
		attachments.gotoFrame(25);
		for (slot in ["head", "body", "frontFoot", "backFoot", "heldItem"]) addAttachmentMarker(attachments.effectTarget(slot));
		addParityCell("effect sockets", attachments, 8);
	}

	private function makeView(state:String, parts:pr2.character.CharacterView.CharacterViewPartIds, hats:Array<Int>):CharacterView {
		var view = new CharacterView(0x2E8BFF, 0xFFD24A, null, state, parts, hats);
		view.name = "characterParityView";
		return view;
	}

	private function addParityCell(label:String, view:CharacterView, index:Int):Void {
		var column = index % 3;
		var row = Std.int(index / 3);
		var centerX = 92 + column * 183;
		var centerY = 100 + row * 115;
		var cellLabel = makeLabel(label, centerX - 82, centerY + 38, 164, 18, 9, false);
		addChild(cellLabel);
		view.x = centerX;
		view.y = centerY;
		view.scaleX = view.scaleY = 0.88;
		parityViews.push(view);
		addChild(view);
	}

	private static function addAttachmentMarker(target:Sprite):Void {
		var marker = new Shape();
		marker.name = "attachmentMarker";
		marker.graphics.lineStyle(1, 0xFF00FF, 0.9);
		marker.graphics.drawCircle(0, 0, 4);
		marker.graphics.moveTo(-6, 0);
		marker.graphics.lineTo(6, 0);
		marker.graphics.moveTo(0, -6);
		marker.graphics.lineTo(0, 6);
		target.addChild(marker);
	}

	private static function makeLabel(text:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool):TextField {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.mouseEnabled = false;
		field.defaultTextFormat = new TextFormat(FontResolver.resolve("Verdana"), size, 0xF4F6FA, bold, null, null, null, null, TextFormatAlign.CENTER);
		field.text = text;
		return field;
	}

	private static function emptyColor():pr2.character.CharacterView.CharacterViewPartColor return {primary: 0, secondary: -1};

	private static function ids(parts:Null<Array<Int>>):Array<String> {
		return parts == null ? [] : [for (id in parts) Std.string(id)];
	}
}
