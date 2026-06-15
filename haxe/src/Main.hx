package;

#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import pr2.Constants;
import pr2.app.QueryParams;
import pr2.app.Screen;
import pr2.harness.GameplayHarness;
import pr2.page.IntroPage;
import pr2.page.LoginPage;
import pr2.page.PageHolder;

/**
	Application entry point. Boots into a screen selected by the `?screen=`
	query flag (default `intro`), which lets development and the OpenFL test
	harness jump straight to any screen.
**/
class Main extends Sprite {
	public function new() {
		super();

		if (stage != null) {
			init();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, init);

		stage.frameRate = Constants.FRAME_RATE;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		try {
			var query = currentQuery();
			addChild(buildScreen(Screen.fromQuery(query), query));
		} catch (error:Dynamic) {
			reportFatalError(error);
		}
	}

	private function reportFatalError(error:Dynamic):Void {
		var message = Std.string(error);
		trace("Fatal error: " + message);
		#if js
		Browser.console.error(error);
		Browser.document.body.setAttribute("data-pr2-error", message);
		#end
	}

	private function currentQuery():Null<String> {
		#if js
		return Browser.location.search;
		#else
		return null;
		#end
	}

	private function buildScreen(screen:Screen, query:Null<String>):DisplayObject {
		return switch (screen) {
			case Harness: new GameplayHarness();
			case Login: new PageHolder(new LoginPage());
			case Intro: new PageHolder(new IntroPage(null, QueryParams.get(query, "intro")));
		};
	}
}
