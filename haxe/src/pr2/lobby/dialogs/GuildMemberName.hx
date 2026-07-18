package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.character.CharacterRig;
import pr2.character.CharacterRig.RigPartChannels;
import pr2.lobby.LobbyArt;
import pr2.lobby.NumberFormat;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.runtime.SvgAsset;

/**
	Port of Flash `dialogs.GuildMemberName`: one linked member row in
	`GuildPopup`'s member list.
**/
class GuildMemberName extends Sprite {
	private var art:Null<Sprite>;
	private var htmlNameMaker:HtmlNameMaker;

	public function new(member:Dynamic, owner:Bool) {
		super();
		art = new Sprite();
		art.addChild(createField("nameBox", 2, 2, 111.95));
		art.addChild(createField("gpTodayBox", 122, 2, 64.95));
		art.addChild(createField("gpTotalBox", 193, 2, 66.95));
		addChild(art);

		htmlNameMaker = new HtmlNameMaker();
		var nameBox:Null<TextField> = LobbyArt.directText(art, "nameBox");
		if (nameBox != null) {
			nameBox.htmlText = htmlNameMaker.makeName(strField(member, "name"), strField(member, "group"));
			htmlNameMaker.listenForLink(nameBox);
			if (owner) {
				nameBox.x += 14;
				nameBox.width -= 14;
			}
		}
		setText("gpTodayBox", NumberFormat.withCommas(intField(member, "gp_today")));
		setText("gpTotalBox", NumberFormat.withCommas(intField(member, "gp_total")));

		if (owner) {
			var hat = createOwnerHat();
			hat.name = "hat";
			hat.transform.matrix = new Matrix(0.117431640625, 0.0137786865234375, -0.0137786865234375, 0.117431640625, 6, 15);
			art.addChild(hat);
		}
	}

	private static function createOwnerHat():Sprite {
		var result = new Sprite();
		var channels = ownerHatChannels();
		var fixed = SvgAsset.create(channels.fixed);
		fixed.name = "fixed";
		result.addChild(fixed);
		var primary = SvgAsset.create(channels.primary);
		primary.name = "colorMC";
		result.addChild(primary);
		var secondary = SvgAsset.create(channels.secondary);
		secondary.name = "colorMC2";
		result.addChild(secondary);
		return result;
	}

	private static function ownerHatChannels():RigPartChannels {
		for (variant in CharacterRig.loadClassic().parts.hat.variants) if (variant.id == 6) return variant;
		throw "Character rig has no crown hat";
	}

	private function createField(name:String, x:Float, y:Float, width:Float):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = 14.55;
		field.multiline = true;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0);
		return field;
	}

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.directText(art, name);
		if (field != null) field.text = value;
	}

	private static function intField(ret:Dynamic, name:String):Int {
		var value:Dynamic = Reflect.field(ret, name);
		if (value == null) return 0;
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.int(value);
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? 0 : parsed;
	}

	private static function strField(ret:Dynamic, name:String):String {
		var value:Dynamic = Reflect.field(ret, name);
		return value == null ? "" : Std.string(value);
	}

	public function remove():Void {
		if (htmlNameMaker != null) {
			htmlNameMaker.remove();
			htmlNameMaker = null;
		}
		if (art != null) {
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
