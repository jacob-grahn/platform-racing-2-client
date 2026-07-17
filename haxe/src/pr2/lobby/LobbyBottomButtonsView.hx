package pr2.lobby;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native lobby footer with the same named action targets as the Flash strip. */
class LobbyBottomButtonsView extends NativeView {
	private final siteLabel:TextField;

	public function new(member:Bool) {
		super();
		y = 374;
		graphics.beginFill(0xE7E7E7, 0.96);
		graphics.lineStyle(1, 0x777777);
		graphics.drawRoundRect(7, 0, 536, 38, 8, 8);
		graphics.endFill();
		var specs = [
			{name: "logoutButton", label: "Log Out"},
			{name: "levelEditorButton", label: "Level Editor"},
			{name: "moreGamesButton", label: "More Games"},
			{name: "optionsButton", label: "Options"},
			{name: "vaultButton", label: "Vault"},
			{name: "creditsButton", label: "Credits"}
		];
		for (index in 0...specs.length) {
			var spec = specs[index];
			var button = ownControl(new GameButton(spec.label));
			button.name = spec.name;
			button.x = 15 + index * 86;
			button.y = 7;
			button.setSize(78, 24);
			addChild(button);
		}
		siteLabel = new TextField();
		siteLabel.x = 375;
		siteLabel.y = -15;
		siteLabel.width = 160;
		siteLabel.height = 14;
		siteLabel.selectable = false;
		siteLabel.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 9, 0x555555, false, null, null, null, null,
			TextFormatAlign.RIGHT);
		addChild(siteLabel);
		setMemberVariant(member);
	}

	public function setMemberVariant(member:Bool):Void {
		siteLabel.text = member ? "Kongregate member" : "Sponsored guest";
	}
}
