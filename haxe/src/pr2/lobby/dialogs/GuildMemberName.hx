package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.NumberFormat;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `dialogs.GuildMemberName`: one linked member row in
	`GuildPopup`'s member list.
**/
class GuildMemberName extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var htmlNameMaker:HtmlNameMaker;

	public function new(member:Dynamic, owner:Bool) {
		super();
		art = PR2MovieClip.fromLinkage("GuildMemberNameGraphic", {maxNestedDepth: 5});
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
			var hat = Std.downcast(LobbyArt.findByName(art, "hat"), PR2MovieClip);
			if (hat != null) {
				hat.gotoAndStop(6);
				var colorMC = Std.downcast(LobbyArt.findByName(hat, "colorMC"), PR2MovieClip);
				var colorMC2 = Std.downcast(LobbyArt.findByName(hat, "colorMC2"), PR2MovieClip);
				if (colorMC != null) colorMC.gotoAndStop(6);
				if (colorMC2 != null) colorMC2.gotoAndStop(6);
			}
		}
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
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
