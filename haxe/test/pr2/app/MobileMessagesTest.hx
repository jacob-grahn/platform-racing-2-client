package pr2.app;

import pr2.lobby.messages.MessageData;
import pr2.lobby.messages.MessageRequest;
import pr2.lobby.messages.MessagesSource;
import pr2.lobby.messages.UnreadNotif;
import pr2.mobile.MobileMessagesPage;

@:access(pr2.mobile.MobileMessagesPage)
@:access(pr2.lobby.tabs.MessagesTab)
class MobileMessagesTest {
	static var replies:Array<String->Void> = [];
	static var errors:Array<String->Void> = [];
	static var urls:Array<String> = [];
	static var sends:Array<{url:String, fields:Map<String,String>, done:String->Void, error:String->Void}> = [];
	static var removed:Int = 0;
	static final payload = '{"messages":[{"message_id":"42","name":"Racer","group":"1,0","message":"[b]Hello[/b]\\rNext line","guild_message":"1","time":1720000000}]}';
	public static function main():Void {
		var oldFetch = MessagesSource.fetch; var oldPost = MobileMessagesPage.post;
		MessagesSource.fetch = function(url, done, error) { urls.push(url); replies.push(done); errors.push(error); return {remove:function() removed++}; };
		MobileMessagesPage.post = function(url, fields, done, error) { sends.push({url:url, fields:fields, done:done, error:error}); return {remove:function() removed++}; };
		UnreadNotif.notifyUser(100); var page = new MobileMessagesPage(); page.initialize();
		check(UnreadNotif.numUnread() == 0 && page.loading, "opening inbox clears shared unread badge");
		check(urls[0].indexOf("start=0") >= 0 && urls[0].indexOf("count=10") >= 0, "original ten-message paging");
		page.changePage(2); replies[0](payload); check(page.rows.length == 0, "stale page response ignored");
		check(urls[1].indexOf("start=10") >= 0, "page offset"); replies[1](payload);
		check(page.rows.length == 1 && page.rows[0].guild && page.rows[0].id == 42, "wire coercions");
		page.setLayout(635,269); layout(page);
		page.openMessage(page.rows[0]); layout(page);
		page.compose(true); check(page.draftTo == "Racer" && page.draftBody.indexOf("\n--- \n") == 0, "reply quotes shared filtered body");
		page.toInput.text = "Target"; page.bodyInput.text = "A draft"; page.setLayout(756,284);
		check(page.toInput.text == "Target" && page.bodyInput.text == "A draft", "resize preserves composer");
		page.submit(); check(page.busy && sends.length == 1, "send starts once"); page.submit(); check(sends.length == 1, "duplicate sends blocked");
		check(sends[0].url.indexOf("message_send.php") >= 0 && sends[0].fields.get("to_name") == "Target", "real send request");
		sends[0].done('{"error":"Rejected"}'); check(!page.busy && page.composing && page.draftBody == "A draft" && page.notice == "Rejected", "server error retains draft");
		page.submit(); sends[1].done('{"success":true}'); check(!page.composing && page.notice == "Message sent.", "success closes composer");
		page.confirm("delete"); check(sends.length == 2, "destructive actions require confirmation"); page.back(); check(sends.length == 2, "cancel does not post");
		page.confirm("report"); page.perform("report"); check(sends[2].fields.get("message_id") == "42", "report ID"); sends[2].error("offline");
		check(page.pending == "report" && page.notice == "offline", "failed action can retry"); page.back();
		page.confirm("delete"); page.perform("delete"); sends[3].done('{"success":true}');
		check(page.selected == null && page.loading, "delete refreshes only after success"); replies[replies.length - 1]('{"messages":[]}');
		page.compose(); page.submit(); check(page.notice == "Please enter a name!" && sends.length == 4, "validation sends nothing"); page.back();
		page.confirm("deleteAll"); page.perform("deleteAll"); check(sends[4].url.indexOf("messages_delete_all.php") >= 0, "delete all endpoint");
		sends[4].done('{"success":true}'); check(page.page == 1 && page.loading, "delete all returns to first page");
		replies[replies.length - 1]("invalid"); check(page.failed && !page.loading, "malformed response exposes retry");
		page.refresh(); errors[errors.length - 1]("offline"); check(page.failed, "network error");
		page.refresh(); var late = replies[replies.length - 1]; page.remove(); page.remove(); late(payload); check(page.rows.length == 0, "removed page ignores loading response");
		var classic = new pr2.lobby.tabs.MessagesTab(); classic.initialize(); replies[replies.length - 1](payload);
		check(classic.messages.length == 1 && classic.messages[0].messageId == 42, "classic uses same loading model"); classic.remove();
		check(MessageData.quote(StringTools.lpad("x", "x", 300)).length == 203, "Flash quote cap");
		check(MessageData.html("<script>bad</script>[b]yes[/b]\rline", "1").indexOf("<script>") < 0, "unprivileged HTML escaped before formatting");
		check(new MessageRequest("send", 0, "Guild", "Hi", true).url.indexOf("guild_message.php") >= 0, "classic guild send preserved");
		MessagesSource.fetch = oldFetch; MobileMessagesPage.post = oldPost; UnreadNotif.reset();
		trace("MobileMessagesTest passed"); Sys.exit(0);
	}
	static function layout(page:MobileMessagesPage):Void {
		for (c in page.view.controls) check(c.controlHeight >= 44 && c.x + c.controlWidth <= page.w, "touch header bounds");
		for (c in page.pane.content.controls) check(c.controlHeight >= 44 && c.x + c.controlWidth <= page.pane.scrollRect.width, "touch content bounds");
	}
	static function check(value:Bool, message:String):Void { if (!value) throw message; }
}
