package pr2.lobby.store;

import openfl.filters.DropShadowFilter;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSlider;
import pr2.ui.view.NativeView;

/** Explicit native composition of the authored QuantityPopupGraphic. */
class QuantityPopupView extends NativeView {
	public final maxQuantity:TextField;
	public final selectedQuantity:TextField;
	public final cost:TextField;
	public final quantitySlider:GameSlider;
	public final buyButton:GameButton;
	public final cancelButton:GameButton;

	public var onBuy:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new(maximum:Int) {
		super();

		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -122.45;
		panel.y = -90;
		panel.scaleX = 0.900650024414062;
		panel.scaleY = 0.942291259765625;
		panel.filters = [new DropShadowFilter(2, 90, 0, 0.6, 3, 3, 1, 2)];
		addChild(panel);

		addChild(textField("-- Quantity --", -108, -81, 217, 18, 14, true, TextFormatAlign.CENTER));
		addChild(textField("How many of this item would\nyou like to purchase?", -108, -57, 217, 31, 12, false, TextFormatAlign.CENTER));
		addChild(textField("1", -105.45, -20.65, 8, 16, 12, false, TextFormatAlign.CENTER));

		maxQuantity = textField(Std.string(maximum), 97.05, -21.15, 30, 16, 12);
		selectedQuantity = textField("Selected: 1", -120.45, 2.9, 241, 16, 12, false, TextFormatAlign.CENTER);
		cost = textField("Cost: 0 Coins", -120.2, 21.45, 241, 16, 12, true, TextFormatAlign.CENTER);
		addChild(maxQuantity);
		addChild(selectedQuantity);
		addChild(cost);

		quantitySlider = ownControl(new GameSlider(1, maximum, 1, 1));
		quantitySlider.setSize(180, 22);
		quantitySlider.x = -90.15;
		quantitySlider.y = -21.05;
		quantitySlider.tabIndex = 1;
		addChild(quantitySlider);

		buyButton = ownControl(new GameButton("Buy"));
		buyButton.setSize(74, 22);
		buyButton.x = -80;
		buyButton.y = 49.95;
		buyButton.tabIndex = 2;
		buyButton.onPress = function():Void if (onBuy != null) onBuy();
		addChild(buyButton);

		cancelButton = ownControl(new GameButton("Cancel"));
		cancelButton.setSize(74, 22);
		cancelButton.x = 7;
		cancelButton.y = 49.95;
		cancelButton.tabIndex = 3;
		cancelButton.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancelButton);

		listen(this, KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	public function showSelection(quantity:Int, totalCost:Int, canAfford:Bool):Void {
		selectedQuantity.text = "Selected: " + quantity;
		cost.htmlText = '<font color="#' + (canAfford ? "006600" : "BB0000") + '">Cost: $totalCost Coins</font>';
		buyButton.enabled = canAfford;
	}

	override public function dispose():Void {
		onBuy = null;
		onCancel = null;
		super.dispose();
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.ESCAPE && onCancel != null) onCancel();
	}

	private static function textField(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool = false,
			align:TextFormatAlign = TextFormatAlign.LEFT):TextField {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.mouseEnabled = false;
		field.multiline = value.indexOf("\n") >= 0;
		field.wordWrap = field.multiline;
		field.autoSize = TextFieldAutoSize.NONE;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x000000, bold, false, false, null, null, align);
		field.text = value;
		return field;
	}
}
