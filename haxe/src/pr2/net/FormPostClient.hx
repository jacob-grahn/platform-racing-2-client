package pr2.net;

import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;

/**
	Small form POST wrapper over the shared Flash-compatible `SuperLoader`.
**/
class FormPostClient {
	public static function post(url:String, fields:Map<String, String>, onText:String->Void, ?onError:String->Void):SuperLoader {
		var vars = new URLVariables();
		for (key in fields.keys()) {
			Reflect.setField(vars, key, fields.get(key));
		}

		var request = new URLRequest(url);
		request.method = URLRequestMethod.POST;
		request.data = vars;

		return load(request, onText, onError);
	}

	public static function load(request:URLRequest, onText:String->Void, ?onError:String->Void):SuperLoader {
		return TextRequest.load(request, onText, onError);
	}
}
