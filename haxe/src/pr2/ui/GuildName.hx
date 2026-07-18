package pr2.ui;

import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.display.Removable;
import pr2.lobby.dialogs.GuildPopup;

class GuildName extends Removable {
	public static var popupFactory:Int->Void = defaultPopupFactory;

	private var nameBox:Null<TextField>;
	private var guildId:Int;

	public function new(id:Int, name:String, emblem:String, boldText:Bool = false, wide:Bool = false) {
		super();
		guildId = id;
		nameBox = new TextField();
		nameBox.name = "nameBox";
		nameBox.x = 2;
		nameBox.y = 2;
		nameBox.width = wide ? 145 : 110;
		nameBox.height = 14.55;
		nameBox.selectable = false;
		nameBox.mouseEnabled = false;
		nameBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0);
		addChild(nameBox);

		useHandCursor = true;
		buttonMode = true;
		mouseChildren = false;

		if (nameBox != null) {
			if (boldText) {
				nameBox.htmlText = "<b>" + StringTools.htmlEscape(name) + "</b>";
			} else {
				nameBox.htmlText = StringTools.htmlEscape(name);
			}
		}

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

	override public function remove():Void {
		removeEventListener(MouseEvent.CLICK, clickHandler);
		nameBox = null;
		super.remove();
	}

	private function clickHandler(_:MouseEvent):Void {
		popupFactory(guildId);
	}

	private function field():Null<TextField> {
		return nameBox;
	}

	private static function defaultPopupFactory(guildId:Int):Void {
		new GuildPopup(guildId);
	}
}
