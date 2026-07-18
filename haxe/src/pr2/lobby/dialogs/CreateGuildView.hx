package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextArea;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Exact native composition of the authored CreateGuildPopupGraphic. */
class CreateGuildView extends NativeView {
	public final panel:Sprite;
	public final transferPanel:Sprite;
	public final nameInput:GameTextInput;
	public final proseInput:GameTextArea;

	public function new() {
		super();
		panel = panelAt("panel", -135.2, -108.8, 0.994140625, 1.26116943359375);
		transferPanel = panelAt("transfer_bg", -135.2, -138.8, 0.994140625, 0.15704345703125);

		label("-- Create Guild --", "titleBox", -98, -95.5, 196, 17.05, 14, true, TextFormatAlign.CENTER, 0x000000);
		label("name:", null, -87.9, -58.05, 39.1, 14.55, 12, false, TextFormatAlign.LEFT, 0x000000);
		label("emblem:", null, -102.5, -30.05, 53.8, 14.55, 12, false, TextFormatAlign.LEFT, 0x000000);
		label("prose:", null, -87.35, 33.95, 38.45, 14.55, 12, false, TextFormatAlign.LEFT, 0x000000);
		label("100x50", null, 62, -28, 37.55, 12.15, 10, false, TextFormatAlign.LEFT, 0x666666);

		var emblemBacking = new Sprite();
		emblemBacking.name = "emblemBacking";
		emblemBacking.x = -43;
		emblemBacking.y = -27;
		emblemBacking.graphics.beginFill(0xCCCCCC);
		emblemBacking.graphics.drawRect(0, 0, 100, 50);
		emblemBacking.graphics.endFill();
		addChild(emblemBacking);

		nameInput = ownControl(new GameTextInput());
		nameInput.name = "nameBox";
		nameInput.x = -44;
		nameInput.y = -60;
		nameInput.setSize(100 * 1.49998474121094, 22);
		nameInput.maxChars = 20;
		addChild(nameInput);

		proseInput = ownControl(new GameTextArea());
		proseInput.name = "proseBox";
		proseInput.x = -44;
		proseInput.y = 32;
		proseInput.setSize(160 * 1.5, 100);
		proseInput.maxChars = 100;
		proseInput.wordWrap = true;
		addChild(proseInput);

		link("changeEmblem_bt", "change", 60, 8, 40.15, TextFormatAlign.LEFT);
		link("deleteEmblem_bt", "delete", 60, -7.85, 34.85, TextFormatAlign.LEFT);
		link("transfer_bt", "Transfer Guild", -36.85, -131.85, 73.7, TextFormatAlign.CENTER);
		button("confirm_bt", "Confirm", -114, 95);
		button("cancel_bt", "Cancel", 15, 95);
	}

	private function panelAt(name:String, x:Float, y:Float, scaleX:Float, scaleY:Float):Sprite {
		var holder = new Sprite();
		holder.name = name;
		holder.x = x;
		holder.y = y;
		holder.scaleX = scaleX;
		holder.scaleY = scaleY;
		holder.addChild(NativeAssets.svg(StaticSvg.QuantityPanel));
		addChild(holder);
		return holder;
	}

	private function button(name:String, value:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(100, 22);
		addChild(control);
	}

	private function link(name:String, value:String, x:Float, y:Float, width:Float, align:TextFormatAlign):Void {
		var control = new GuildTextLink(value, width, align);
		control.name = name;
		control.x = x;
		control.y = y;
		addChild(control);
	}

	private function label(value:String, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign, color:Int):Void {
		var field = new TextField();
		if (name != null) field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}
}

private class GuildTextLink extends Sprite {
	private final field:TextField;

	public function new(value:String, width:Float, align:TextFormatAlign) {
		super();
		buttonMode = true;
		mouseChildren = false;
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, width, 16.15);
		graphics.endFill();
		field = new TextField();
		field.x = 2;
		field.y = 2;
		field.width = width - 4;
		field.height = 12.15;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x4E4EFE, false, null, null, null, null, align);
		field.text = value;
		addChild(field);
		addEventListener(MouseEvent.MOUSE_OVER, setOver);
		addEventListener(MouseEvent.MOUSE_OUT, setOut);
	}

	private function setOver(_:MouseEvent):Void setColor(0x000000);
	private function setOut(_:MouseEvent):Void setColor(0x4E4EFE);
	private function setColor(color:Int):Void {
		var format = field.defaultTextFormat;
		format.color = color;
		field.defaultTextFormat = format;
		field.setTextFormat(format);
	}
}
