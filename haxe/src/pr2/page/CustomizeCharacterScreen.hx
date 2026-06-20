package pr2.page;

import openfl.display.Sprite;
import pr2.Constants;
import pr2.character.Parts;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.account.AccountState;
import pr2.lobby.account.PlayerDisplay;

/**
	Standalone dev screen for the lobby character customizer: just the character
	preview plus the hat/head/body/feet part steppers and colour selectors (Flash
	`player_profile.PlayerDisplay`), without the surrounding Account tab chrome
	(rank tokens, stats, loadouts) or a live gameserver session.

	Reached via `?screen=customize_character`. Because there is no socket to send
	`get_customize_info`, the part lists are seeded from `Parts` with the full set
	of real part ids, so every part can be cycled and recoloured.
**/
class CustomizeCharacterScreen extends Sprite {
	private var character:Null<AccountCharacter>;
	private var playerDisplay:Null<PlayerDisplay>;

	public function new() {
		super();

		graphics.beginFill(Constants.BACKGROUND_COLOR);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();

		var hats = ids(Parts.getPartArray("HAT"));
		var heads = ids(Parts.getPartArray("HEAD"));
		var bodies = ids(Parts.getPartArray("BODY"));
		var feet = ids(Parts.getPartArray("FEET"));
		var none:Array<String> = [];

		var hat = 1;
		var head = 1;
		var body = 1;
		var feetSel = 1;
		var hatColor = 0xFFFFFF;
		var headColor = 0xFFCC99;
		var bodyColor = 0x3399FF;
		var feetColor = 0x333333;

		character = new AccountCharacter(hat, head, body, feetSel);
		character.setColors(hatColor, -1, headColor, -1, bodyColor, -1, feetColor, -1);
		AccountState.currentHat = hat;

		// The controls live up-and-left of the character preview, matching the
		// relative placement in `AccountTab` (playerDisplay 23,95 / character 80,182).
		var group = new Sprite();

		playerDisplay = new PlayerDisplay(character, hats, heads, bodies, feet, hat, head, body, feetSel, hatColor, headColor, bodyColor, feetColor, none,
			none, none, none, -1, -1, -1, -1);
		playerDisplay.x = 0;
		playerDisplay.y = 0;
		group.addChild(playerDisplay);

		var characterHolder = new Sprite();
		characterHolder.addChild(character);
		characterHolder.x = 57;
		characterHolder.y = 87;
		characterHolder.scaleX = characterHolder.scaleY = 1.5;
		group.addChild(characterHolder);

		addChild(group);

		var bounds = group.getBounds(this);
		group.x = (Constants.STAGE_WIDTH - bounds.width) / 2 - bounds.x;
		group.y = (Constants.STAGE_HEIGHT - bounds.height) / 2 - bounds.y;
	}

	private static function ids(parts:Null<Array<Int>>):Array<String> {
		return parts == null ? [] : [for (id in parts) Std.string(id)];
	}
}
