package pr2.lobby.account;

import openfl.display.Sprite;
import pr2.character.CharacterDisplay;

/**
	Editable customize-preview character, the slice of Flash `character.Character`
	the Account tab drives: a single visible hat plus head/body/feet, each with a
	primary colour and an optional epic (secondary) colour. Wraps the shared
	`CharacterDisplay` and re-applies appearance on every change, exactly like the
	original `applyAppearance` round-trip.

	`-1` for an epic colour means the part is not epic (no second colour); the
	preview then hides that part's secondary tint.
**/
class AccountCharacter extends Sprite {
	/** Authored transform retained by CharacterGraphic's state children. */
	public static inline final INTERNAL_GRAPHIC_SCALE:Float = 0.15;

	public var hat1:Int;
	public var head:Int;
	public var body:Int;
	public var feet:Int;

	public var hat1Color:Int = 0;
	public var headColor:Int = 0;
	public var bodyColor:Int = 0;
	public var feetColor:Int = 0;

	public var hat1Color2:Int = -1;
	public var headColor2:Int = -1;
	public var bodyColor2:Int = -1;
	public var feetColor2:Int = -1;

	public final display:CharacterDisplay;

	public function new(hatId:Int = 1, headId:Int = 1, bodyId:Int = 1, feetId:Int = 1) {
		super();
		this.hat1 = hatId;
		this.head = headId;
		this.body = bodyId;
		this.feet = feetId;
		display = new CharacterDisplay({hat: hatId, head: headId, body: bodyId, feet: feetId});
		// CharacterDisplay instantiates the exported CharacterGraphic. Its state
		// children already retain their authored ~0.15 matrices, so the wrapper
		// itself remains at scale 1 exactly like Flash's Character instance.
		addChild(display);
		// Flash's customize/account preview is a live Character MovieClip, so the
		// standing idle plays continuously. Drive it from the stage clock; the
		// listener is released automatically when the preview is detached.
		display.enableIdleAnimation();
		applyAppearance();
	}

	public function setColors(hatColor:Int, hatColor2:Int, headColor:Int, headColor2:Int, bodyColor:Int, bodyColor2:Int, feetColor:Int,
			feetColor2:Int):Void {
		this.hat1Color = hatColor;
		this.hat1Color2 = hatColor2;
		this.headColor = headColor;
		this.headColor2 = headColor2;
		this.bodyColor = bodyColor;
		this.bodyColor2 = bodyColor2;
		this.feetColor = feetColor;
		this.feetColor2 = feetColor2;
		applyAppearance();
	}

	public function setHatId(id:Int):Void {
		hat1 = id;
		applyAppearance();
	}

	public function setHeadId(id:Int):Void {
		head = id;
		applyAppearance();
	}

	public function setBodyId(id:Int):Void {
		body = id;
		applyAppearance();
	}

	public function setFeetId(id:Int):Void {
		feet = id;
		applyAppearance();
	}

	public function setHatColors(color:Int, epic:Int):Void {
		hat1Color = color;
		hat1Color2 = epic;
		applyAppearance();
	}

	public function setHeadColors(color:Int, epic:Int):Void {
		headColor = color;
		headColor2 = epic;
		applyAppearance();
	}

	public function setBodyColors(color:Int, epic:Int):Void {
		bodyColor = color;
		bodyColor2 = epic;
		applyAppearance();
	}

	public function setFeetColors(color:Int, epic:Int):Void {
		feetColor = color;
		feetColor2 = epic;
		applyAppearance();
	}

	private function applyAppearance():Void {
		display.setPartIds({hat: hat1, head: head, body: body, feet: feet});
		display.setPartColor("hat", hat1Color, hat1Color2);
		display.setPartColor("head", headColor, headColor2);
		display.setPartColor("body", bodyColor, bodyColor2);
		display.setPartColor("feet", feetColor, feetColor2);
	}

	/**
		Serialised customize payload used by `set_customize_info`, matching the
		original field order:
		`hat1Color`headColor`bodyColor`feetColor`hat1Color2`headColor2`bodyColor2`feetColor2`hat`head`body`feet`.
	**/
	public function getPartInfoStr():String {
		return hat1Color
			+ "`" + headColor
			+ "`" + bodyColor
			+ "`" + feetColor
			+ "`" + hat1Color2
			+ "`" + headColor2
			+ "`" + bodyColor2
			+ "`" + feetColor2
			+ "`" + hat1
			+ "`" + head
			+ "`" + body
			+ "`" + feet;
	}

	public function remove():Void {
		if (display.parent == this) {
			removeChild(display);
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
