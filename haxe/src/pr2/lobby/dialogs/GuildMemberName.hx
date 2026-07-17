package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.lobby.LobbyArt;
import pr2.lobby.NumberFormat;
import pr2.lobby.chat.HtmlNameMaker;

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
		art.addChild(createField("nameBox", 2, 2, 112));
		art.addChild(createField("gpTodayBox", 122, 2, 65));
		art.addChild(createField("gpTotalBox", 193, 2, 67));
		addChild(art);

		htmlNameMaker = new HtmlNameMaker();
		var nameBox:Null<TextField> = LobbyArt.text(art, "nameBox");
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
			var hat = new Shape();
			hat.name = "hat";
			hat.x = 6;
			hat.y = 15;
			hat.graphics.beginFill(0xFFD447);
			hat.graphics.lineStyle(1, 0x8A6913);
			hat.graphics.moveTo(0, 0);
			hat.graphics.lineTo(4, -9);
			hat.graphics.lineTo(8, -3);
			hat.graphics.lineTo(13, -10);
			hat.graphics.lineTo(16, 0);
			hat.graphics.lineTo(0, 0);
			hat.graphics.endFill();
			art.addChild(hat);
		}
	}

	private function createField(name:String, x:Float, y:Float, width:Float):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = 15;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0);
		return field;
	}

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.text(art, name);
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
