package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.gameplay.Items;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameSlider;
import pr2.ui.view.NativeView;

/** Shared native shell for item, teleport, stat, and custom-stat block options. */
class EditorBlockOptionsView extends NativeView {
	private final named:Map<String, DisplayObject> = [];
	public function childNamed(name:String):Null<DisplayObject> return named.get(name);

	public function new(kind:String) {
		super();
		switch (kind) {
			case "StatBlockOptionsGraphic": statView();
			case "ItemBlockOptionsGraphic": itemView();
			case "CustomStatsBlockOptionsGraphic": customStatsView();
			case "TeleportBlockOptionsGraphic": title("-- Teleport Color --");
			default: title("-- Block Options --");
		}
	}

	private function statView():Void {
		background(-117.7, -59.95, 0.867233276367188, 0.68072509765625);
		var title = field("titleBox", -56, -49, 115.95, 14.55, 12, true, TextFormatAlign.CENTER);
		title.scaleX = 1.00047302246094;
		title.text = "-- Happy Block --";
		var desc = field("descBox", -103, -23, 206, 31.1, 12, false, TextFormatAlign.CENTER);
		desc.multiline = true;
		desc.wordWrap = true;
		desc.text = "All the stats of players that bump this block will be increased by:";
		var slider = ownControl(new GameSlider(5, 100, 5, 5));
		slider.name = "slider";
		slider.x = -90;
		slider.y = 24.85;
		slider.setSize(184.5, 22);
		addChild(slider);
		named.set(slider.name, slider);
		var stat = field("statBox", -12.95, 46.5, 23.5, 14.55, 12, false, TextFormatAlign.CENTER);
		stat.multiline = true;
		stat.text = "5";
	}

	private function itemView():Void {
		background(-118, -105, 0.86767578125, 1.09947204589844);
		var itemTitle = field("title", -57.1, -92.6, 116, 14.55, 12, true, TextFormatAlign.CENTER);
		itemTitle.scaleX = 1.00047302246094;
		itemTitle.text = "-- Item Block --";
		var desc = field("description", -104.55, -70.6, 206.1, 31.1, 12, false, TextFormatAlign.CENTER);
		desc.multiline = true;
		desc.wordWrap = true;
		desc.text = "This block will be able to give\nthe following items:";
		var codes = [Items.LASER_GUN, Items.MINE, Items.LIGHTNING, Items.TELEPORT, Items.SUPER_JUMP, Items.JET_PACK, Items.SPEED_BURST,
			Items.SWORD, Items.ICE_WAVE];
		var labels = ["Laser Gun", "Mine", "Lightning", "Teleport", "Super Jump", "Jet Pack", "Speed Burst", "Sword", "Ice Wave"];
		var xs = [-101.05, 6.95, -101.05, -101.05, 6.95, -101.05, 6.95, 6.95, -101.05];
		var ys = [-31.6, 43.4, 18.4, 43.4, -6.6, -6.6, -31.6, 18.4, 68.4];
		for (i in 0...codes.length) {
			var code = codes[i];
			var check = ownControl(new GameCheckBox(labels[i]));
			check.name = "check" + code;
			check.x = xs[i];
			check.y = ys[i];
			check.scaleX = 1.00042724609375;
			addChild(check);
			named.set(check.name, check);
		}
	}

	private function customStatsView():Void {
		background(-120, -115, 0.88232421875, 1.20414733886719);
		var customTitle = field("title", -79.45, -103.15, 165.9, 14.55, 12, true, TextFormatAlign.CENTER);
		customTitle.scaleX = 1.00047302246094;
		customTitle.text = "-- Custom Stats Block --";
		var desc = field("description", -103, -80.6, 206, 31.1, 12, false, TextFormatAlign.CENTER);
		desc.multiline = true;
		desc.wordWrap = true;
		desc.text = "Players that bump this block will have their stats set to:";
		var reset = ownControl(new GameCheckBox("Reset To Starting Stats"));
		reset.name = "resetChk";
		reset.x = -75;
		reset.y = 80;
		reset.scaleX = 1.5;
		addChild(reset);
		named.set(reset.name, reset);
	}

	private function title(value:String):Void {
		background(-117.7, -59.95, 0.867233276367188, 0.68072509765625);
		var heading = field("title", -68, -49, 135.95, 14.55, 12, true, TextFormatAlign.CENTER);
		heading.scaleX = 1.00047302246094;
		heading.text = value == "-- Teleport Color --" ? "-- Teleport Block --" : value;
		if (value == "-- Teleport Color --") {
			var desc = field("description", -103, -28, 206, 47.65, 12, false, TextFormatAlign.CENTER);
			desc.multiline = true;
			desc.wordWrap = true;
			desc.text = "Choose the background color of this block. Blocks with the same color will be linked to this one.";
		}
	}

	private function background(x:Float, y:Float, scaleX:Float, scaleY:Float):Void {
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = x;
		background.y = y;
		background.scaleX = scaleX;
		background.scaleY = scaleY;
		addChild(background);
		named.set(background.name, background);
	}

	private function field(name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
		if (name != null) named.set(name, text);
		return text;
	}
}
