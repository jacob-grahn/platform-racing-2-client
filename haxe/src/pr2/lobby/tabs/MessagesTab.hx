package pr2.lobby.tabs;

import openfl.display.DisplayObjectContainer;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.MessagesItem;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.messages.UnreadNotif;
import pr2.page.Page;
import pr2.ui.view.LoadingView;
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

	Loading and message rules are shared with mobile; reporting/deleting POST
	through the shared `UploadingPopup`.
**/
class MessagesTab extends Page implements Paginated {
	private var art:MessagesView;
	private var holder:Null<DisplayObjectContainer>;
	private var scrollBar:CustomScrollBar;
	private var loading:LoadingView;
	private var pageNavigation:PageNavigation;
	private var messages:Array<MessagesItem> = [];
	private var currentPage:Int = 1;

	private var sendBinding:Null<LobbyArt.Binding>;
	private var deleteAllBinding:Null<LobbyArt.Binding>;
	private var uploading:Null<UploadingPopup>;
	private var source = new pr2.lobby.messages.MessagesSource();

	public function new() {
		super();
	}

	override public function initialize():Void {
		art = new MessagesView();
		holder = Std.downcast(DisplayUtil.directChildByName(art, "var_295"), DisplayObjectContainer);

		scrollBar = new CustomScrollBar();
		scrollBar.x = 176;
		if (holder != null) {
			scrollBar.init(holder, 340, 330);
		}
		addChild(scrollBar);

		pageNavigation = new PageNavigation(this, "minimal", 1, 99, 110);
		pageNavigation.x = 33;

		sendBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "sendMessage_bt"), clickSend);
		deleteAllBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "deleteAll_bt"), clickDeleteAll);
		addChild(art);

		loading = new LoadingView();
		loading.x = 88;
		loading.y = 150;

		getMessages();
		UnreadNotif.updateLastRead();
	}

	private function clickSend():Void {
		pr2.app.ScreenFactory.composeMessage();
	}

	private function getMessages():Void {
		removeMessages();
		addChild(loading);
		source.load(currentPage, handleMessages, handleError);
	}

	private function handleMessages(list:Array<pr2.lobby.messages.MessageData>):Void {
		if (loading.parent == this) removeChild(loading);
		pageNavigation.y = 50;
		if (holder != null) holder.addChild(pageNavigation);
		scrollBar.position(0);
		for (msg in list) messages.push(new MessagesItem(this, msg.id, msg.name, msg.group, msg.body, msg.guild, msg.time));
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
		var request = new pr2.lobby.messages.MessageRequest("report", item.messageId);
		uploading = new UploadingPopup(request.url, request.fields, "Reporting message...");
	}

	public function doDelete(item:MessagesItem):Void {
		item.alpha = 0.25;
		var request = new pr2.lobby.messages.MessageRequest("delete", item.messageId);
		uploading = new UploadingPopup(request.url, request.fields, "Deleting message...");
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
		var request = new pr2.lobby.messages.MessageRequest("deleteAll");
		new UploadingPopup(request.url, request.fields, "Deleting messages...");
		removeMessages();
	}

	// Paginated
	public function setPageNum(pageNum:Int):Void {
		currentPage = pageNum;
		getMessages();
	}

	override public function remove():Void {
		source.remove();
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
		if (loading != null) loading.dispose();
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
