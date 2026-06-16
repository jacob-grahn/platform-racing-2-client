package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.Bitmap;
import openfl.display.PixelSnapping;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.Assets;
import pr2.Constants;

/**
	Login menu ported from the Flash `menu.LoginPage`.

	The page art is baked through the Flash -> SVG -> PNG pipeline. The original
	Flash menu buttons are runtime text controls, so only those labels and hit
	areas are rebuilt in Haxe.
**/
class LoginPage extends Page {
	private static inline var LOGIN_PAGE_ASSET = "assets/login/login_page@4x.png";
	private static inline var LOGIN_PAGE_SCALE = 4;
	private static inline var LOGIN_PAGE_TRIM_X = 21;
	private static inline var LOGIN_PAGE_TRIM_Y = 370;

	private static inline var MENU_X:Float = 275;
	private static inline var MENU_Y:Float = 228;
	private static inline var MENU_SPACING:Float = 22;

	private var background:Null<LoginBackground>;
	private var pageArt:Null<Bitmap>;
	private var buttons:Array<LoginPageMenuButton> = [];
	private var muteButton:Null<LoginMuteButton>;
	private var kongHitArea:Null<Sprite>;

	public function new() {
		super();
	}

	override public function initialize():Void {
		background = new LoginBackground();
		addChild(background);

		pageArt = createBitmap(LOGIN_PAGE_ASSET, LOGIN_PAGE_TRIM_X, LOGIN_PAGE_TRIM_Y, LOGIN_PAGE_SCALE);
		addChild(pageArt);

		addMenuButton("Log In", noop);
		addMenuButton("Play as Guest", noop);
		addMenuButton("Create Account", noop);
		addMenuButton("Instructions", openInstructions);
		addMenuButton("Credits", noop);

		kongHitArea = createHitArea(5, 364, 183, 31, noop);
		addChild(kongHitArea);

		muteButton = new LoginMuteButton();
		muteButton.x = 491;
		muteButton.y = 363;
		addChild(muteButton);
	}

	override public function remove():Void {
		for (button in buttons) {
			button.remove();
			if (button.parent != null) {
				button.parent.removeChild(button);
			}
		}
		buttons = [];

		if (muteButton != null) {
			muteButton.remove();
			if (muteButton.parent != null) {
				muteButton.parent.removeChild(muteButton);
			}
			muteButton = null;
		}

		if (kongHitArea != null && kongHitArea.parent != null) {
			kongHitArea.parent.removeChild(kongHitArea);
		}
		kongHitArea = null;

		if (pageArt != null && pageArt.parent != null) {
			pageArt.parent.removeChild(pageArt);
		}
		pageArt = null;

		if (background != null) {
			background.remove();
			if (background.parent != null) {
				background.parent.removeChild(background);
			}
			background = null;
		}
		super.remove();
	}

	private function addMenuButton(label:String, clickHandler:Void->Void):Void {
		var button = new LoginPageMenuButton(label, clickHandler);
		button.x = MENU_X;
		button.y = MENU_Y + buttons.length * MENU_SPACING;
		buttons.push(button);
		addChild(button);
	}

	private function openInstructions():Void {
		#if js
		Browser.window.open("/instructions.php", "_blank");
		#end
	}

	private function noop():Void {}

	private static function createBitmap(assetPath:String, trimX:Int, trimY:Int, scale:Int):Bitmap {
		var bitmap = new Bitmap(Assets.getBitmapData(assetPath), PixelSnapping.AUTO, true);
		bitmap.x = trimX / scale;
		bitmap.y = trimY / scale;
		bitmap.scaleX = 1 / scale;
		bitmap.scaleY = 1 / scale;
		return bitmap;
	}

	private static function createHitArea(x:Float, y:Float, width:Float, height:Float, clickHandler:Void->Void):Sprite {
		var hitArea = new Sprite();
		hitArea.x = x;
		hitArea.y = y;
		hitArea.buttonMode = true;
		hitArea.useHandCursor = true;
		hitArea.graphics.beginFill(0xFFFFFF, 0);
		hitArea.graphics.drawRect(0, 0, width, height);
		hitArea.graphics.endFill();
		hitArea.addEventListener(MouseEvent.CLICK, function(_):Void {
			clickHandler();
		});
		return hitArea;
	}
}

private class LoginBackground extends Sprite {
	private var layers:Array<LoginBackgroundLayer>;

	public function new() {
		super();
		layers = [
			new LoginBackgroundLayer("assets/login/bg_sky@4x.png", -245, -162, 4, 0, 0, 1.0, 1.00010681152344, 1, 0, 0),
			new LoginBackgroundLayer("assets/login/bg_far@4x.png", 46, 0, 4, -15.65, 240.25, 1.0, 1.0, 1508, 1276.0, -1276.0),
			new LoginBackgroundLayer("assets/login/bg_mid@4x.png", 119, -615, 4, -36.75, 263.4, 1.00004577636719, 1.0006103515625, 383, 1237.0, -1235.7),
			new LoginBackgroundLayer("assets/login/bg_front@4x.png", -21, 2, 4, -7.2, 279.9, 1.0, 1.0, 134, -0.65, -1250.25),
		];

		for (layer in layers) {
			addChild(layer);
		}

		var stageMask = new Shape();
		stageMask.graphics.beginFill(0xFFFFFF);
		stageMask.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		stageMask.graphics.endFill();
		addChild(stageMask);
		mask = stageMask;
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(_:Event):Void {
		for (layer in layers) {
			layer.advance();
		}
	}
}

private class LoginBackgroundLayer extends Sprite {
	private var bitmap:Bitmap;
	private var parentX:Float;
	private var parentY:Float;
	private var parentScaleX:Float;
	private var parentScaleY:Float;
	private var totalFrames:Int;
	private var startTx:Float;
	private var endTx:Float;
	private var frame:Int = 0;

	public function new(
		assetPath:String,
		trimX:Int,
		trimY:Int,
		scale:Int,
		parentX:Float,
		parentY:Float,
		parentScaleX:Float,
		parentScaleY:Float,
		totalFrames:Int,
		startTx:Float,
		endTx:Float
	) {
		super();
		this.parentX = parentX;
		this.parentY = parentY;
		this.parentScaleX = parentScaleX;
		this.parentScaleY = parentScaleY;
		this.totalFrames = totalFrames;
		this.startTx = startTx;
		this.endTx = endTx;

		bitmap = new Bitmap(Assets.getBitmapData(assetPath), PixelSnapping.AUTO, true);
		bitmap.x = trimX / scale;
		bitmap.y = trimY / scale;
		bitmap.scaleX = 1 / scale;
		bitmap.scaleY = 1 / scale;
		addChild(bitmap);
		updatePosition();
	}

	public function advance():Void {
		if (totalFrames <= 1) {
			return;
		}
		frame = (frame + 1) % totalFrames;
		updatePosition();
	}

	private function updatePosition():Void {
		var tx = startTx;
		if (totalFrames > 1) {
			tx = startTx + (endTx - startTx) * (frame / (totalFrames - 1));
		}
		x = parentX + tx;
		y = parentY;
		scaleX = parentScaleX;
		scaleY = parentScaleY;
	}
}

private class LoginPageMenuButton extends Sprite {
	private static inline var HIT_WIDTH:Float = 116;
	private static inline var HIT_HEIGHT:Float = 20;

	private var label:String;
	private var clickHandler:Void->Void;
	private var frontText:TextField;
	private var shadowText:TextField;

	public function new(label:String, clickHandler:Void->Void) {
		super();
		this.label = label;
		this.clickHandler = clickHandler;

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		alpha = 0.75;
		drawHitArea();

		shadowText = buildTextField(0xFFFFFF);
		shadowText.x = -HIT_WIDTH / 2 + 1;
		shadowText.y = 1;
		addChild(shadowText);

		frontText = buildTextField(0x333333);
		frontText.x = -HIT_WIDTH / 2;
		addChild(frontText);
		setLabel(label);

		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		addEventListener(MouseEvent.CLICK, onClick);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		removeEventListener(MouseEvent.CLICK, onClick);
	}

	private function buildTextField(color:Int):TextField {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 12, color, false, false, false, null, null, CENTER);
		text.selectable = false;
		text.mouseEnabled = false;
		text.autoSize = TextFieldAutoSize.NONE;
		text.width = HIT_WIDTH;
		text.height = HIT_HEIGHT;
		return text;
	}

	private function setLabel(value:String):Void {
		frontText.text = value;
		shadowText.text = value;
	}

	private function drawHitArea():Void {
		graphics.beginFill(0xFFFFFF, 0);
		graphics.drawRect(-HIT_WIDTH / 2, 0, HIT_WIDTH, HIT_HEIGHT);
		graphics.endFill();
	}

	private function onOver(_:MouseEvent):Void {
		alpha = 1;
		setLabel("- " + label + " -");
	}

	private function onOut(_:MouseEvent):Void {
		alpha = 0.75;
		setLabel(label);
	}

	private function onClick(_:MouseEvent):Void {
		clickHandler();
	}
}

private class LoginMuteButton extends Sprite {
	private static inline var MUTE_BUTTON_ASSET = "assets/login/mute_button@4x.png";
	private static inline var MUTE_BUTTON_SCALE = 4;
	private static inline var MUTE_BUTTON_TRIM_X = -57;
	private static inline var MUTE_BUTTON_TRIM_Y = -73;
	private static var muted:Bool = false;

	private var bitmap:Bitmap;

	public function new() {
		super();
		bitmap = new Bitmap(Assets.getBitmapData(MUTE_BUTTON_ASSET), PixelSnapping.AUTO, true);
		bitmap.x = MUTE_BUTTON_TRIM_X / MUTE_BUTTON_SCALE;
		bitmap.y = MUTE_BUTTON_TRIM_Y / MUTE_BUTTON_SCALE;
		bitmap.scaleX = 1 / MUTE_BUTTON_SCALE;
		bitmap.scaleY = 1 / MUTE_BUTTON_SCALE;
		addChild(bitmap);

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;

		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		applyMutedState();
	}

	public function remove():Void {
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
	}

	private function onClick(_:MouseEvent):Void {
		muted = !muted;
		applyMutedState();
	}

	private function onOver(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 127, 127, 127, 0);
	}

	private function onOut(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform();
	}

	private function applyMutedState():Void {
		alpha = muted ? 0.7 : 1;
		SoundMixer.soundTransform = new SoundTransform(muted ? 0 : 1);
	}
}
