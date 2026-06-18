package pr2.lobby.dialogs;

import haxe.Json;
import openfl.events.Event;
import pr2.lobby.LobbyArt;
import pr2.net.FormPostClient;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `dialogs.UploadingPopup`: a modal that POSTs a request, shows a
	progress message with a close button, and dispatches `DONE` (with `parsedData`)
	or `ERROR` when the request settles, then fades out.

	The Flash `ProgressBar` art is not yet exported, so the determinate progress
	bar is omitted; the POST round-trip, parsed result, events, and optional
	callbacks are faithful.
**/
class UploadingPopup extends Popup {
	public static inline var DONE:String = "uploadDone";
	public static inline var ERROR:String = "uploadError";

	public var parsedData:Dynamic = null;

	private var art:PR2MovieClip;
	private var closeBinding:Null<LobbyArt.Binding>;

	public function new(url:String, fields:Map<String, String>, dispText:String = "Uploading...", ?onResult:Dynamic->Void, ?onError:String->Void) {
		super();
		art = PR2MovieClip.fromLinkage("UploadingPopupGraphic", {maxNestedDepth: 4});
		var textBox = LobbyArt.text(art, "textBox");
		if (textBox != null) {
			textBox.text = dispText;
		}
		addChild(art);
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), function():Void startFadeOut());

		FormPostClient.post(url, fields, function(body:String):Void {
			try {
				parsedData = Json.parse(body);
			} catch (_:Dynamic) {
				parsedData = null;
			}
			if (onResult != null) {
				onResult(parsedData);
			}
			dispatchEvent(new Event(DONE));
			startFadeOut();
		}, function(message:String):Void {
			if (onError != null) {
				onError(message);
			}
			dispatchEvent(new Event(ERROR));
			startFadeOut();
		});
	}

	override public function remove():Void {
		LobbyArt.unbind(closeBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
