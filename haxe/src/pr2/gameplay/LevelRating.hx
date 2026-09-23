package pr2.gameplay;

import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

typedef RatingTransport = String->Map<String, String>->(String->Void)->(String->Void)->AsyncRemovable;

/** Confirmed rating submission shared by desktop and mobile controls. */
class LevelRating {
	public static var transport:RatingTransport = post;
	public var pending(default, null):Bool = false;
	public var submitted(default, null):Int = 0;
	public var message(default, null):String = "";
	public var failed(default, null):Bool = false;
	public var onChange:Void->Void;
	private var guard = new AsyncRemovalGuard();
	private var levelId:Int;
	public function new(levelId:Int) this.levelId = levelId;
	public static function fields(levelId:Int, value:Int):Map<String, String> return ["level_id" => Std.string(levelId), "rating" => Std.string(value)];
	public function submit(value:Int, ?send:RatingTransport):Void {
		if (!guard.isActive() || pending || value < 1 || value > 5) return;
		pending = true; failed = false; message = "Submitting rating…"; changed();
		guard.watch((send == null ? transport : send)(ServerConfig.submitRatingUrl(), fields(levelId, value), guard.wrap(function(text) {
			pending = false; submitted = value; message = text == "" ? "Rating submitted. Thanks!" : text; changed();
		}), guard.wrap(function(error) {
			pending = false; failed = true; message = error == "" ? "Could not submit your rating. Please try again." : error; changed();
		})));
	}
	private function changed():Void { if (onChange != null) onChange(); }
	public function remove():Void { guard.remove(); onChange = null; }
	private static function post(url:String, values:Map<String, String>, success:String->Void, failure:String->Void):AsyncRemovable {
		return FormPostClient.post(url, values, function(body) {
			var result = SuperLoader.decodeJson(url, body, false);
			if (result.success) success(result.message); else failure(result.message);
		}, failure);
	}
}
