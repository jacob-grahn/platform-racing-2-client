package pr2.page;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.app.AppStage;
import pr2.app.ScreenFactory;
import pr2.audio.AudioMute;
import pr2.lobby.account.AccountCharacter;
import pr2.mobile.MobileButton;

/** Landscape title presentation. Authentication belongs to the composed LoginFlow. */
class MobileLoginPage extends Page {
	public final siteMode:String;
	public var flow(default, null):LoginFlow;
	private var content:Sprite;
	private var background:LoginBackground;
	private var racer:AccountCharacter;
	private var buttons:Array<MobileButton> = [];
	private var sound:MobileButton;
	private var rotate:TextField;

	public function new(?siteMode:String) {
		super();
		this.siteMode = siteMode == null ? "kongregate" : siteMode;
		fullViewport = true;
		isLoginScreen = true;
		flow = new LoginFlow(function(userName, server):Void {
			if (pageHolder != null) pageHolder.changePage(ScreenFactory.lobby(userName, server));
		});
	}

	override public function initialize():Void {
		content = new Sprite();
		addChild(content);
		background = new LoginBackground();
		background.scaleX = 844 / 550;
		background.scaleY = 390 / 400;
		content.addChild(background);
		var title = label("Platform Racing\n-- 2 --", "Gwibble", 43, 414, 136);
		title.textColor = 0x000000;
		title.x = 44;
		title.y = 58;
		title.filters = [new GlowFilter(0xFFFFFF, 1, 6, 6, 2, 3)];
		content.addChild(title);

		racer = new AccountCharacter();
		racer.setColors(0, -1, 0xE56565, -1, 0x8960C9, -1, 0x8960C9, -1);
		var bounds = racer.getBounds(racer);
		// Rig bounds include unpainted registration space around the standing art.
		var scale = 192 / bounds.height;
		racer.scaleX = racer.scaleY = scale;
		racer.x = 184 - bounds.x * scale;
		racer.y = 182 - bounds.y * scale;
		content.addChild(racer);

		button("LOG IN", "loginButton", 500, 88, 300, 64, flow.openLoginDialog, 0xD1ED62, 26);
		button("Play as Guest", "guestButton", 500, 166, 300, 56, flow.openGuestDialog);
		button("Create Account", "createAccountButton", 500, 236, 300, 56, function():Void flow.openCreateAccountDialog());
		button("Instructions", "instructionsButton", 500, 328, 174, 44, flow.openInstructions);
		button("Credits", "creditsButton", 686, 328, 114, 44, flow.openCreditsDialog);
		sound = button(soundLabel(), "soundButton", 668, 20, 132, 44, function():Void {
			AudioMute.setMuted(!AudioMute.muted);
			sound.setLabel(soundLabel());
		});
		var credit = label("A game by Jiggmin", "Nunito Bold", 15, 414, 24);
		credit.x = 44;
		credit.y = 346;
		content.addChild(credit);

		// Authentication panels use viewport pixels for touch targets and keyboard resizing.
		rotate = label("Turn your device sideways to play", "Lilita One", 22, 844, 44);
		addChild(rotate);
		addChild(flow);
		if (AppStage.stage != null) AppStage.stage.addEventListener(Event.RESIZE, layout);
		layout();
		flow.start();
	}

	private static function soundLabel():String return AudioMute.muted ? "Sound: Off" : "Sound: On";

	private function button(text:String, name:String, x:Float, y:Float, w:Float, h:Float, action:Void->Void, color:Int = 0xFFFFFF, size:Int = 20):MobileButton {
		var view = new MobileButton(text, w, h, action, color, true, size);
		view.name = name;
		view.x = x;
		view.y = y;
		content.addChild(view);
		buttons.push(view);
		return view;
	}

	private static function label(text:String, font:String, size:Int, width:Float, height:Float):TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(font, size, 0x18334B, false, false, false, null, null, TextFormatAlign.CENTER);
		field.embedFonts = true;
		field.width = width;
		field.height = height;
		field.multiline = true;
		field.selectable = false;
		field.mouseEnabled = false;
		field.text = text;
		return field;
	}

	private function layout(?event:Event):Void {
		var stage = AppStage.stage;
		var w:Float = stage == null ? 844 : stage.stageWidth;
		var h:Float = stage == null ? 390 : stage.stageHeight;
		var scale = Math.min(w / 844, h / 390);
		content.scaleX = content.scaleY = scale;
		content.x = (w - 844 * scale) / 2;
		content.y = (h - 390 * scale) / 2;
		flow.resizeViewport(w, h);
		rotate.visible = h > w;
		rotate.width = w;
		rotate.y = Math.max(12, content.y - 64);
		graphics.clear();
		graphics.beginFill(0xA5C8D8);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
	}

	override public function remove():Void {
		if (AppStage.stage != null) AppStage.stage.removeEventListener(Event.RESIZE, layout);
		flow.remove();
		if (background != null) background.remove();
		if (racer != null) racer.remove();
		for (view in buttons) view.remove();
		buttons = [];
		super.remove();
	}
}
