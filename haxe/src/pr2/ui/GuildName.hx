package pr2.ui;

import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.display.Removable;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.GuildPopup;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;

class GuildName extends Removable {
	public static var popupFactory:Int->Void = defaultPopupFactory;

	private var art:Null<PR2MovieClip>;
	private var emblemLoader:Null<EmblemLoader>;
	private var guildId:Int;

	public function new(id:Int, name:String, emblem:String, boldText:Bool = false, wide:Bool = false) {
		super();
		guildId = id;
		art = PR2MovieClip.fromLinkage("GuildNameGraphic", {maxNestedDepth: 3});
		addChild(art);

		useHandCursor = true;
		buttonMode = true;
		mouseChildren = false;

		var nameBox = field();
		if (nameBox != null) {
			if (boldText) {
				nameBox.htmlText = "<b>" + StringTools.htmlEscape(name) + "</b>";
			} else {
				nameBox.htmlText = StringTools.htmlEscape(name);
			}
			nameBox.width = wide ? 145 : 110;
		}

		emblemLoader = new EmblemLoader(20, 10, ServerConfig.emblemUploadUrl(), ServerConfig.emblemsUrl());
		emblemLoader.x = -23;
		emblemLoader.y = 2;
		emblemLoader.mouseEnabled = false;
		emblemLoader.mouseChildren = false;
		emblemLoader.getImage(emblem == null || emblem == "" ? "default-emblem.jpg" : emblem);
		addChild(emblemLoader);

		addEventListener(MouseEvent.CLICK, clickHandler);
	}

	public function makeWidth(n:Float):Void {
		var nameBox = field();
		if (nameBox != null) {
			nameBox.width = n;
		}
	}

	public function nameWidthForTests():Float {
		var nameBox = field();
		return nameBox == null ? 0 : nameBox.width;
	}

	public function nameHtmlForTests():String {
		var nameBox = field();
		return nameBox == null ? "" : nameBox.htmlText;
	}

	public function emblemForTests():Null<EmblemLoader> {
		return emblemLoader;
	}

	override public function remove():Void {
		removeEventListener(MouseEvent.CLICK, clickHandler);
		if (emblemLoader != null) {
			emblemLoader.remove();
			emblemLoader = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function clickHandler(_:MouseEvent):Void {
		popupFactory(guildId);
	}

	private function field():Null<TextField> {
		return LobbyArt.text(art, "nameBox");
	}

	private static function defaultPopupFactory(guildId:Int):Void {
		new GuildPopup(guildId);
	}
}
