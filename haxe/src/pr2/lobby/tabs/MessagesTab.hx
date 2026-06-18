package pr2.lobby.tabs;

/**
	Port-in-progress of Flash `chat.Messages` (the PMs tab).

	Renders the real `MessagesGraphic` art. Only appears for logged-in accounts
	(`LobbySession.isMember()`), which is enforced by `LobbyLeft`. Message list
	loading via `messages_get.php`, paging, the send/delete/report/delete-all
	flows, and the unread badge are still being ported.
**/
class MessagesTab extends ScaffoldTab {
	public function new() {
		super("MessagesGraphic", null, null, "Private messages — list loading via messages_get.php is being ported.");
	}
}
