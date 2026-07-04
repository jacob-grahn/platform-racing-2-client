package pr2.lobby.tabs;

import haxe.Json;
import openfl.display.DisplayObjectContainer;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.MessagesItem;
import pr2.lobby.dialogs.SendMessagePopup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.messages.MessagesPaging;
import pr2.lobby.messages.UnreadNotif;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;
import pr2.ui.CustomScrollBar;
import pr2.ui.PageNavigation;
import pr2.ui.PageNavigation.Paginated;
import pr2.util.DisplayUtil;

/**
	Port of Flash `chat.Messages` (the PMs tab). Loads the caller's private
	messages from `messages_get.php` (10 per page), lays them out in the scrollable
	`var_295` holder with a `CustomScrollBar`, paginates with the "minimal"
	`PageNavigation`, and exposes the compose / delete-all / per-message
	report & delete flows. Only shown to logged-in accounts (enforced by
	`LobbyLeft`).

	Faithful differences: the swear filter and unread-notification badge are not
	yet ported; reporting/deleting POST through the shared `UploadingPopup`.
**/
class MessagesTab extends Page implements Paginated {
	private static inline var ITEMS_PER_PAGE:Int = MessagesPaging.ITEMS_PER_PAGE;

	private var art:PR2MovieClip;
	private var holder:Null<DisplayObjectContainer>;
	private var scrollBar:CustomScrollBar;
	private var loading:PR2MovieClip;
	private var pageNavigation:PageNavigation;
	private var messages:Array<MessagesItem> = [];
	private var currentPage:Int = 1;

	private var sendBinding:Null<LobbyArt.Binding>;
	private var deleteAllBinding:Null<LobbyArt.Binding>;
	private var uploading:Null<UploadingPopup>;

	public function new() {
		super();
	}

	override public function initialize():Void {
		art = PR2MovieClip.fromLinkage("MessagesGraphic", {maxNestedDepth: 8});
		holder = Std.downcast(DisplayUtil.findByName(art, "var_295"), DisplayObjectContainer);

		scrollBar = new CustomScrollBar();
		scrollBar.x = 176;
		if (holder != null) {
			scrollBar.init(holder, 340, 330);
		}
		addChild(scrollBar);

		pageNavigation = new PageNavigation(this, "minimal", 1, 99, 110);
		pageNavigation.x = 33;

		sendBinding = LobbyArt.bind(DisplayUtil.findByName(art, "sendMessage_bt"), clickSend);
		deleteAllBinding = LobbyArt.bind(DisplayUtil.findByName(art, "deleteAll_bt"), clickDeleteAll);
		addChild(art);

		loading = PR2MovieClip.fromLinkage("LoadingGraphic", {maxNestedDepth: 4});
		loading.x = 88;
		loading.y = 150;

		getMessages();
		UnreadNotif.updateLastRead();
	}

	private function clickSend():Void {
		new SendMessagePopup();
	}

	private function getMessages():Void {
		removeMessages();
		addChild(loading);
		var start = MessagesPaging.startIndex(currentPage, ITEMS_PER_PAGE);
		TextLoader.load(ServerConfig.messagesGetUrl(start, ITEMS_PER_PAGE), handleData, handleError);
	}

	private function handleData(body:String):Void {
		if (loading.parent == this) {
			removeChild(loading);
		}
		var parsed:Dynamic = null;
		try {
			parsed = Json.parse(body);
		} catch (_:Dynamic) {
			return;
		}
		var list:Array<Dynamic> = parsed != null && parsed.messages != null ? parsed.messages : [];

		pageNavigation.y = 50;
		if (holder != null) {
			holder.addChild(pageNavigation);
		}
		scrollBar.position(0);

		for (msg in list) {
			messages.push(new MessagesItem(this, intField(msg.message_id), strField(msg.name), strField(msg.group), strField(msg.message),
				boolField(msg.guild_message), intField(msg.time)));
		}
		populateMessages();
	}

	private function populateMessages():Void {
		var nextY = 0.0;
		for (item in messages) {
			item.y = nextY;
			if (holder != null) {
				holder.addChild(item);
			}
			nextY += Math.round(item.height) + 18;
		}
		pageNavigation.y = nextY + 10;
	}

	private function removeMessages():Void {
		for (item in messages) {
			item.remove();
		}
		messages = [];
		if (holder != null && pageNavigation.parent == holder) {
			holder.removeChild(pageNavigation);
		}
	}

	public function doReport(item:MessagesItem):Void {
		item.alpha = 0.5;
		uploading = new UploadingPopup(ServerConfig.messageReportUrl(), ["message_id" => Std.string(item.messageId)], "Reporting message...");
	}

	public function doDelete(item:MessagesItem):Void {
		item.alpha = 0.25;
		uploading = new UploadingPopup(ServerConfig.messageDeleteUrl(), ["message_id" => Std.string(item.messageId)], "Deleting message...");
	}

	private function handleError(_:String):Void {
		if (loading.parent == this) {
			removeChild(loading);
		}
	}

	private function clickDeleteAll():Void {
		new ConfirmPopup(doDeleteAll, "Are you sure you want to delete all of your messages?");
	}

	public function doDeleteAll():Void {
		new UploadingPopup(ServerConfig.messagesDeleteAllUrl(), new Map<String, String>(), "Deleting messages...");
		removeMessages();
	}

	// Paginated
	public function setPageNum(pageNum:Int):Void {
		currentPage = pageNum;
		getMessages();
	}

	private static function strField(value:Dynamic):String {
		return value == null ? "" : Std.string(value);
	}

	private static function intField(value:Dynamic):Int {
		if (value == null) {
			return 0;
		}
		var n = Std.parseInt(Std.string(value));
		return n == null ? 0 : n;
	}

	private static function boolField(value:Dynamic):Bool {
		var raw = Std.string(value);
		return raw == "1" || raw == "true";
	}

	override public function remove():Void {
		removeMessages();
		LobbyArt.unbind(sendBinding);
		LobbyArt.unbind(deleteAllBinding);
		if (pageNavigation != null) {
			pageNavigation.remove();
		}
		if (scrollBar != null) {
			scrollBar.remove();
		}
		if (uploading != null) {
			uploading.remove();
			uploading = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
