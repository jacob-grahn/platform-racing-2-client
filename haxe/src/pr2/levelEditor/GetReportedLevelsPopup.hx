package pr2.levelEditor;

import haxe.Json;
import openfl.display.DisplayObjectContainer;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.util.DisplayUtil;
import pr2.levelEditor.EditorPersistenceTypes.GetLevelsPostFactory;
import pr2.levelEditor.EditorPersistenceTypes.GetLevelsLoadFactory;

class GetReportedLevelsPopup extends Popup {
	public static var postFactory:GetLevelsPostFactory = defaultPost;
	public static var loadFactory:GetLevelsLoadFactory = defaultLoad;

	public final art:GetLevelsView;
	public final listings:Array<GetReportedLevelsPopupItem> = [];
	public var selected(default, null):Null<GetReportedLevelsPopupItem>;
	private var bindings:Array<Binding> = [];

	public function new() {
		super();
		art = new GetLevelsView();
		addChild(art);
		setText("titleBox", "-- Reported Levels --");
		var handle = DisplayUtil.findByName(art, "delete_bt");
		Reflect.setProperty(handle, "label", "Handle");
		bind("cancel_bt", function():Void startFadeOut());
		bind("load_bt", clickLoad);
		bind("delete_bt", clickHandle);
		updateButtons();
		postFactory(ServerConfig.levelsGetReportedUrl(), requestFields(), handleResponse, handleError);
	}

	public function selectListing(listing:Null<GetReportedLevelsPopupItem>):Void {
		selected = listing;
		for (item in listings) {
			item.setSelected(item == selected);
		}
		updateButtons();
	}

	public function loadSelected():Void {
		clickLoad();
	}

	private function handleResponse(ret:Dynamic):Void {
		var levels:Dynamic = ret == null ? null : Reflect.field(ret, "levels");
		if (Std.isOfType(levels, Array)) {
			for (level in cast(levels, Array<Dynamic>)) {
				addListing(new GetReportedLevelsPopupItem(level, this));
			}
		}
		hideLoadingGraphic();
	}

	private function handleError(message:String):Void {
		hideLoadingGraphic();
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private function addListing(listing:GetReportedLevelsPopupItem):Void {
		listing.y = listings.length * 18;
		var holder = levelsHolder();
		if (holder != null) {
			holder.addChild(listing);
		}
		listings.push(listing);
	}

	private function clickLoad():Void {
		if (selected == null) {
			return;
		}
		loadFactory(selected.levelId, selected.version);
		startFadeOut();
	}

	private function clickHandle():Void {
		if (selected == null) {
			return;
		}
		new HandleLevelReportPopup(this, selected.level);
	}

	private function updateButtons():Void {
		Reflect.setProperty(DisplayUtil.findByName(art, "load_bt"), "enabled", selected != null);
		Reflect.setProperty(DisplayUtil.findByName(art, "delete_bt"), "enabled", selected != null);
	}

	private function hideLoadingGraphic():Void {
		var loading = DisplayUtil.findByName(art, "loadingGraphic");
		if (loading != null && loading.parent != null) {
			loading.parent.removeChild(loading);
		}
	}

	private function levelsHolder():Null<DisplayObjectContainer> {
		return Std.downcast(DisplayUtil.findByName(art, "levelsHolder"), DisplayObjectContainer);
	}

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.text(art, name);
		if (field != null) {
			field.text = value;
		}
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	override public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		for (listing in listings.copy()) {
			listing.remove();
		}
		listings.resize(0);
		selected = null;
		art.dispose();
		super.remove();
	}

	private static function requestFields():Map<String, String> {
		var fields = new Map<String, String>();
		fields.set("token", LobbySession.token);
		return fields;
	}

	private static function defaultPost(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
		FormPostClient.post(url, fields, function(body:String):Void {
			if (body == null || body == "") {
				onResult({levels: []});
				return;
			}
			try {
				onResult(Json.parse(body));
			} catch (_:Dynamic) {
				onError("The loaded data was not in the expected format.");
			}
		}, onError);
	}

	private static function defaultLoad(levelId:Int, version:Int):Void {
		new LoadingLevelPopup(levelId, version, true);
	}
}
