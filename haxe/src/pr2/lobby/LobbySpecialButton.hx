package pr2.lobby;

import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.animation.TimelineClip;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;

/** Authored blank component skin with the XFL text/icon overlay and glow timeline. */
class LobbySpecialButton extends GameButton {
	public final glow:TimelineClip;
	private final overlay:Shape;

	public function new(kind:LobbySpecialButtonKind) {
		super("");
		var isKong = kind == Kong;
		var authoredWidth = isKong ? 111 * 0.960159301757812 : 111 * 0.740097045898438;
		var authoredHeight = 22 * 1.272705078125;
		setSize(authoredWidth, authoredHeight);
		glow = new TimelineClip(isKong ? "assets/ui/lobby_kong_glow.json" : "assets/ui/lobby_vault_glow.json");
		glow.mouseEnabled = false;
		glow.mouseChildren = false;
		addChildAt(glow, 0);
		overlay = NativeAssets.svg(isKong ? StaticSvg.LobbyKongOverlay : StaticSvg.LobbyVaultOverlay);
		addChild(overlay);
		// openfl-svg does not render SVG <text>. Recreate the two authored XFL
		// static fields at their matrix + `left` coordinates while retaining the
		// exact composed vector stars around them.
		if (isKong) {
			addAuthoredText("Get a Hat at ", 15.4, 2, 67.1, 0x000000);
			addAuthoredText("Kongregate.com", 6.8, 13, 82.1, 0xB10101);
		} else {
			addAuthoredText("Vault ", 22, 2, 30.9, 0x000000);
			addAuthoredText("of Magics", 13, 13, 46.95, 0xB10101);
		}
	}

	private function addAuthoredText(value:String, x:Float, y:Float, width:Float, color:Int):Void {
		var field = new TextField();
		field.mouseEnabled = false;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat("Verdana", 10, color);
		field.text = value;
		field.width = width + 4;
		field.height = 12.15 + 4;
		field.x = x - 2;
		field.y = y - 2;
		addChild(field);
	}

	override public function dispose():Void {
		glow.dispose();
		super.dispose();
	}
}

enum LobbySpecialButtonKind {
	Kong;
	Vault;
}
