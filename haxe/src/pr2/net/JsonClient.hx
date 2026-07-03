package pr2.net;

import haxe.Json;

/** JSON GET/POST wrapper for lobby API endpoints. */
class JsonClient {
	private function new() {}

	public static function get(url:String, onJson:Dynamic->Void, ?onError:String->Void):Void {
		TextLoader.load(url, body -> decode(url, body, onJson, onError), onError);
	}

	public static function post(url:String, fields:Map<String, String>, onJson:Dynamic->Void, ?onError:String->Void):Void {
		FormPostClient.post(url, fields, body -> decode(url, body, onJson, onError), onError);
	}

	/** Exposed for deterministic response parsing tests and cached API bodies. */
	public static function decode(source:String, body:String, onJson:Dynamic->Void, ?onError:String->Void):Void {
		var result = SuperLoader.decodeJson(source, body);
		if (result.success) onJson(result.data) else if (onError != null) onError(result.message);
	}
}
