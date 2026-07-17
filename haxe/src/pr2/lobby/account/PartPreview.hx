package pr2.lobby.account;

import openfl.display.Sprite;

/** Live character-backed preview for a single catalog part. */
class PartPreview extends Sprite {
	public final character:AccountCharacter;
	public final epicTarget:Sprite;
	public var secondaryVisible(default, null):Bool;

	public function new(type:String, id:Int, owned:Bool) {
		super();
		name = "partPreview";
		var hat = type == "HAT" ? id : 1;
		var head = type == "HEAD" ? id : 1;
		var body = type == "BODY" ? id : 1;
		var feet = type == "FEET" ? id : 1;
		character = new AccountCharacter(hat, head, body, feet);
		character.setColors(0x6C91C2, -1, 0xD2A779, -1, 0x7399C8, -1, 0x545E70, -1);
		addChild(character);
		epicTarget = new Sprite();
		epicTarget.name = "epicTarget";
		epicTarget.graphics.lineStyle(3, 0x9D68D6, 0.8);
		epicTarget.graphics.drawCircle(0, 0, 28);
		epicTarget.visible = false;
		addChild(epicTarget);
		secondaryVisible = type == "HAT" && id == 16;
		if (secondaryVisible) character.setHatColors(0xD3B13B, 0xF2DE79);
		alpha = owned ? 1 : 0.1;
	}

	public function showEpic():Void {
		secondaryVisible = true;
		epicTarget.visible = true;
	}

	public function remove():Void {
		character.remove();
		if (parent != null) parent.removeChild(this);
	}
}
