package pr2.lobby.dialogs;

import haxe.Json;
import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbySession;
import pr2.net.FormPostClient;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.runtime.FlTextInput;
import pr2.runtime.PR2MovieClip;
import pr2.ui.EmblemLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.DisplayUtil;

typedef GuildInfoFactory = Int->(Dynamic->Void)->(String->Void)->Void;
typedef GuildSaveFactory = String->Map<String, String>->(Dynamic->Void)->(String->Void)->Void;

class CreateGuildPopup extends Popup {
	private static inline var DEFAULT_EMBLEM:String = "default-emblem.jpg";

	public static var infoFactory:GuildInfoFactory = defaultInfoLoad;
	public static var saveFactory:GuildSaveFactory = defaultSave;
	public static var transferFactory:Void->Void = function():Void new MessagePopup("Guild transfer is not available yet.");

	private var art:Null<PR2MovieClip>;
	private var guildId:Int;
	private var loading:Bool = false;
	private var emblem:Null<EmblemLoader>;
	private var bindings:Array<Null<Binding>> = [];
	private var transferBinding:Null<Binding>;
	private var deleteBinding:Null<Binding>;
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();

	public function new(id:Int = 0) {
		super();
		guildId = id;
		art = PR2MovieClip.fromLinkage("CreateGuildPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		setVisible("transfer_bg", false);
		setVisible("transfer_bt", false);
		setVisible("deleteEmblem_bt", false);
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), clickCancel));
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, "confirm_bt"), clickConfirm));
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, "changeEmblem_bt"), clickChangeEmblem));

		emblem = new EmblemLoader(100, 50, ServerConfig.emblemUploadUrl(), ServerConfig.emblemsUrl());
		emblem.x = -43;
		emblem.y = -27;
		emblem.getImage(DEFAULT_EMBLEM);
		addChild(emblem);

		if (guildId != 0) {
			loading = true;
			setText("titleBox", "-- Edit Guild --");
			infoFactory(guildId, asyncGuard.wrap(populateResult), asyncGuard.wrap(function(_:String):Void loading = false));
			if (LobbySession.guildId == guildId && LobbySession.guildOwner) {
				setVisible("transfer_bg", true);
				setVisible("transfer_bt", true);
				transferBinding = LobbyArt.bind(DisplayUtil.findByName(art, "transfer_bt"), clickTransfer);
			}
		}
	}

	private function clickTransfer():Void {
		if (LobbySession.canUseRememberMeAccountAction()) {
			transferFactory();
			startFadeOut();
		} else {
			new MessagePopup(LobbySession.REMEMBER_ME_REQUIRED_COPY);
		}
	}

	private function clickDeleteEmblem():Void {
		if (emblem != null) {
			emblem.getImage(DEFAULT_EMBLEM);
		}
		setVisible("deleteEmblem_bt", false);
		LobbyArt.unbind(deleteBinding);
		deleteBinding = null;
		new MessagePopup("Once you press Confirm, this change will be final. To revert this change, click Cancel.");
	}

	private function populateResult(parsed:Dynamic):Void {
		var ret:Dynamic = Reflect.field(parsed, "guild");
		if (ret == null) ret = parsed;
		setText("nameBox", strAny(ret, ["guild_name", "guildName"]));
		setText("proseBox", strAny(ret, ["note"]));
		var nextEmblem = strAny(ret, ["emblem"]);
		if (emblem != null) {
			emblem.getImage(nextEmblem == "" ? DEFAULT_EMBLEM : nextEmblem);
		}
		if (nextEmblem != "" && nextEmblem != DEFAULT_EMBLEM && guildId != 0) {
			setVisible("deleteEmblem_bt", true);
			deleteBinding = LobbyArt.bind(DisplayUtil.findByName(art, "deleteEmblem_bt"), clickDeleteEmblem);
		}
		loading = false;
	}

	private function clickChangeEmblem():Void {
		if (emblem != null) {
			emblem.openBrowse();
		}
	}

	private function clickCancel():Void {
		startFadeOut();
	}

	private function clickConfirm():Void {
		if (loading) {
			return;
		}
		loading = true;
		var confirm = DisplayUtil.findByName(art, "confirm_bt");
		if (confirm != null) {
			confirm.alpha = 0.33;
		}
		if (emblem != null && emblem.isLoading()) {
			emblem.addEventListener(EmblemLoader.FINISH_LOADING, emblemFinished);
		} else {
			doConfirm();
		}
	}

	private function emblemFinished(_:Event):Void {
		if (emblem != null) {
			emblem.removeEventListener(EmblemLoader.FINISH_LOADING, emblemFinished);
		}
		doConfirm();
	}

	private function doConfirm():Void {
		var fields:Map<String, String> = [
			"note" => textValue("proseBox"),
			"name" => textValue("nameBox"),
			"emblem" => emblem == null ? DEFAULT_EMBLEM : emblem.getFileName(),
		];
		if (guildId != 0) {
			fields.set("guild_id", Std.string(guildId));
		}
		saveFactory(guildId == 0 ? ServerConfig.guildCreateUrl() : ServerConfig.guildEditUrl(), fields, asyncGuard.wrap(saveSuccess), asyncGuard.wrap(saveError));
	}

	private function saveError(_:String):Void {
		loading = false;
		var confirm = DisplayUtil.findByName(art, "confirm_bt");
		if (confirm != null) {
			confirm.alpha = 1;
		}
	}

	private function saveSuccess(ret:Dynamic):Void {
		if (loading && LobbySession.guildId != guildId) {
			startFadeOut();
			return;
		}
		LobbySession.updateGuildFromData(ret, true);
		startFadeOut();
	}

	public function emblemFileNameForTests():String {
		return emblem == null ? "" : emblem.getFileName();
	}

	public function setEmblemFileNameForTests(fileName:String, loading:Bool = false):Void {
		if (emblem != null) {
			emblem.setFileNameForTests(fileName, loading);
		}
	}

	private function setVisible(name:String, visible:Bool):Void {
		var target = DisplayUtil.findByName(art, name);
		if (target != null) {
			target.visible = visible;
		}
	}

	private function setText(name:String, value:String):Void {
		var field = textField(name);
		if (field != null) {
			field.text = value;
			return;
		}
		var input = textInput(name);
		if (input != null) {
			input.text = value;
		}
	}

	private function textValue(name:String):String {
		var input = textInput(name);
		if (input != null) return input.text;
		var field = textField(name);
		return field == null ? "" : field.text;
	}

	private function textField(name:String):Null<TextField> {
		return LobbyArt.text(art, name);
	}

	private function textInput(name:String):Null<FlTextInput> {
		return Std.downcast(DisplayUtil.findByName(art, name), FlTextInput);
	}

	private static function intAny(ret:Dynamic, names:Array<String>):Int {
		for (name in names) {
			var value:Dynamic = Reflect.field(ret, name);
			if (value != null) {
				var parsed = Std.parseInt(Std.string(value));
				return parsed == null ? 0 : parsed;
			}
		}
		return 0;
	}

	private static function strAny(ret:Dynamic, names:Array<String>):String {
		for (name in names) {
			var value:Dynamic = Reflect.field(ret, name);
			if (value != null) return Std.string(value);
		}
		return "";
	}

	override public function remove():Void {
		asyncGuard.remove();
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		LobbyArt.unbind(deleteBinding);
		LobbyArt.unbind(transferBinding);
		deleteBinding = null;
		transferBinding = null;
		if (emblem != null) {
			emblem.removeEventListener(EmblemLoader.FINISH_LOADING, emblemFinished);
			emblem.remove();
			emblem = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private static function defaultInfoLoad(id:Int, onResult:Dynamic->Void, onError:String->Void):Void {
		TextLoader.load(ServerConfig.guildInfoUrl(id), function(body:String):Void onResult(Json.parse(body)), onError);
	}

	private static function defaultSave(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
		FormPostClient.post(url, fields, function(body:String):Void onResult(Json.parse(body)), onError);
	}
}
