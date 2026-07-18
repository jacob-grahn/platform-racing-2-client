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
import pr2.ui.view.LoadingView;
import pr2.ui.view.NativeView;

/** Exact native composition of the authored GuildPopupGraphic states. */
class GuildView extends NativeView {
	public final shadow:Sprite;
	public final loadingGraphic:LoadingView;
	public final messageButton:GameButton;
	public final closeButton:GameButton;

	public function new() {
		super();
		shadow = new Sprite();
		shadow.name = "shadow";
		shadow.x = -150;
		shadow.y = -155;
		shadow.scaleX = 1.10287475585938;
		shadow.scaleY = 1.62298583984375;
		shadow.addChild(NativeAssets.svg(StaticSvg.QuantityPanel));
		addChild(shadow);

		field("titleBox", -147.95, -140, 296.95, 14.55, 12, false, TextFormatAlign.CENTER);
		field("gpTodayBox", -30, -110, 173, 14.55, 12, false, TextFormatAlign.LEFT);
		field("gpTotalBox", -30, -91, 173, 14.55, 12, false, TextFormatAlign.LEFT);
		field("membersCount", -30, -72, 173, 14.55, 12, false, TextFormatAlign.LEFT);
		field("guildProse", -138, 77, 273.95, 40.45, 10, false, TextFormatAlign.LEFT, true, 0x666666);
		field(null, -138, -46, 29.3, 12.15, 10, false, TextFormatAlign.LEFT, false, 0x666666, "Name");
		field(null, -18, -46, 44.6, 12.15, 10, false, TextFormatAlign.LEFT, false, 0x666666, "GP today");
		field(null, 53, -46, 40, 12.15, 10, false, TextFormatAlign.LEFT, false, 0x666666, "GP total");

		var emblemBacking = new Sprite();
		emblemBacking.name = "emblemBacking";
		emblemBacking.x = -140;
		emblemBacking.y = -109;
		emblemBacking.graphics.beginFill(0xCCCCCC);
		emblemBacking.graphics.drawRect(0, 0, 100, 50);
		emblemBacking.graphics.endFill();
		addChild(emblemBacking);

		var holder = new Sprite();
		holder.name = "membersHolder";
		holder.x = -140;
		holder.y = -26;
		addChild(holder);

		link("edit_bt", "edit", -140, 125.85, 27);
		link("delete_bt", "delete", 103.1, 125.85, 34.85);
		messageButton = button("messageButton", "PM Everyone", -93, 123, 85);
		closeButton = button("close_bt", "Close", -49, 123, 100);

		loadingGraphic = new LoadingView();
		loadingGraphic.name = "loadingGraphic";
		addChild(loadingGraphic);
		setMember(false);
	}

	public function setMember(member:Bool):Void {
		if (member && messageButton.parent != this) addChild(messageButton);
		if (!member && messageButton.parent == this) removeChild(messageButton);
		closeButton.x = member ? 8 : -49;
		closeButton.setSize(member ? 85 : 100, 22);
	}

	override public function dispose():Void {
		loadingGraphic.dispose();
		super.dispose();
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float):GameButton {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
		return control;
	}

	private function link(name:String, value:String, x:Float, y:Float, width:Float):Void {
		var control = new GuildPopupLink(value, width);
		control.name = name;
		control.x = x;
		control.y = y;
		addChild(control);
	}

	private function field(name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		multiline:Bool = false, color:Int = 0x000000, value:String = ""):Void {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.multiline = multiline;
		text.wordWrap = multiline;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		text.text = value;
		addChild(text);
	}
}

private class GuildPopupLink extends Sprite {
	private final field:TextField;

	public function new(value:String, width:Float) {
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
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x4E4EFE);
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
