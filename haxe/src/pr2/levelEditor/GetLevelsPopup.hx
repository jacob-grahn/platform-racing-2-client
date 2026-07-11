package pr2.levelEditor;

import haxe.Json;
import openfl.display.DisplayObjectContainer;
import pr2.lobby.LobbySession;
import pr2.lobby.chat.ChatText;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;
import pr2.ui.CustomScrollBar;
import pr2.util.DisplayUtil;
import pr2.levelEditor.EditorPersistenceTypes.GetLevelsPostFactory;
import pr2.levelEditor.EditorPersistenceTypes.GetLevelsLoadFactory;

class GetLevelsPopup extends Popup {
	public static var postFactory:GetLevelsPostFactory = defaultPost;
	public static var loadFactory:GetLevelsLoadFactory = defaultLoad;

	public final art:PR2MovieClip;
	public final listings:Array<GetLevelsPopupItem> = [];
	public var selected(default, null):Null<GetLevelsPopupItem>;
	private var bindings:Array<Binding> = [];
	private var scroll:Null<CustomScrollBar>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("GetLevelsPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		scroll = new CustomScrollBar();
		scroll.x = 119;
		scroll.y = -86;
		addChild(scroll);
		var holder = levelsHolder();
		if (holder != null) {
			scroll.init(holder, 160, 158);
		}
		setText("titleBox", "-- My Levels --");
		bind("cancel_bt", function():Void startFadeOut());
		bind("load_bt", clickLoad);
		bind("delete_bt", clickDelete);
		updateButtons();
		postFactory(ServerConfig.levelsGetUrl(), requestFields(), handleResponse, handleError);
	}

	public function selectListing(listing:Null<GetLevelsPopupItem>):Void {
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
				addListing(new GetLevelsPopupItem(level, this));
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

	private function addListing(listing:GetLevelsPopupItem):Void {
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

	private function clickDelete():Void {
		if (selected == null) {
			return;
		}
		var listing = selected;
		new ConfirmPopup(function():Void {
			new DeletingLevelPopup(listing.levelId);
			startFadeOut();
		}, 'Are you sure you want to delete "' + ChatText.escapeString(listing.title) + '"?');
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
		if (scroll != null) {
			scroll.remove();
			scroll = null;
		}
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
		new LoadingLevelPopup(levelId, version);
	}
}
