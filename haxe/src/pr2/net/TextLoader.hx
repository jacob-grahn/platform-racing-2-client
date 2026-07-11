package pr2.net;

import openfl.net.URLRequest;

/**
	Minimal async text fetch over the shared Flash-compatible `SuperLoader`.
	Cross-origin requests to pr2hub.com require CORS headers on the html5 target.
**/
class TextLoader {
	/**
		Fetch `url` as text. `onText` receives the body on success; `onError`
		receives a human-readable message on failure. Exactly one callback fires.
	**/
	public static function load(url:String, onText:String->Void, ?onError:String->Void):SuperLoader {
		return TextRequest.load(new URLRequest(url), onText, onError);
	}
}
