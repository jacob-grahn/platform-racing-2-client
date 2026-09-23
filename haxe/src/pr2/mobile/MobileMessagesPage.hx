package pr2.mobile;

import pr2.page.Page;
import pr2.lobby.messages.MessageData;
import pr2.lobby.messages.MessageRequest;
import pr2.lobby.messages.MessagesSource;
import pr2.lobby.messages.UnreadNotif;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.mobile.MobileAuthControls.AuthInput;
import pr2.net.FormPostClient;
import pr2.net.SuperLoader;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/** Landscape inbox, message reader and composer sharing classic message rules. */
class MobileMessagesPage extends Page {
	public static var post:String->Map<String, String>->(String->Void)->(String->Void)->AsyncRemovable = FormPostClient.post;
	private var view = new LobbyView();
	private var pane = new MobileScrollPane();
	private var source = new MessagesSource();
	private var guard = new AsyncRemovalGuard();
	private var links = new HtmlNameMaker();
	private var rows:Array<MessageData> = [];
	private var page:Int = 1;
	private var selected:MessageData;
	private var composing:Bool = false;
	private var draftTo:String = "";
	private var draftBody:String = "";
	private var toInput:AuthInput;
	private var bodyInput:AuthInput;
	private var pending:String = "";
	private var busy:Bool = false;
	private var loading:Bool = false;
	private var notice:String = "";
	private var failed:Bool = false;
	private var disposedPage:Bool = false;
	private var w:Float = 756;
	private var h:Float = 284;
	private var standalone:Bool = false;
	private var guildMessage:Bool = false;
	public var onComposerClose:Void->Void;
	/** Reuse the same editor from profiles, chat, guilds and level sharing. */
	public function setupComposer(to:String, body:String, guild:Bool):Void {
		standalone = true; composing = true; draftTo = to; draftBody = body; guildMessage = guild;
	}
	public function focusComposer(recipient:Bool):Void {
		var input = recipient && !guildMessage ? toInput : bodyInput;
		if (input != null) input.focus();
	}
	public function new() super();
	override public function initialize():Void {
		addChild(view); addChild(pane);
		if (standalone) render(); else { UnreadNotif.updateLastRead(); refresh(); }
	}
	public function setLayout(width:Float, height:Float):Void { saveDraft(); w = width; h = height; render(); }
	private function saveDraft():Void {
		if (toInput != null) draftTo = toInput.text;
		if (bodyInput != null) draftBody = bodyInput.text;
	}
	private function refresh():Void {
		if (disposedPage || busy) return;
		loading = true; notice = ""; failed = false; rows = []; pane.reset(); render();
		source.load(page, function(value) { rows = value; loading = false; render(); }, function(error) {
			loading = false; failed = true; notice = error; render();
		});
	}
	private function changePage(value:Int):Void { page = Std.int(Math.max(1, Math.min(99, value))); refresh(); }
	private function openMessage(row:MessageData):Void { selected = row; notice = ""; pane.reset(); render(); }
	private function compose(reply:Bool = false):Void {
		composing = true; notice = "";
		draftTo = reply && selected != null ? selected.name : "";
		draftBody = reply && selected != null ? MessageData.quote(MessageData.filtered(selected.body)) : "";
		pane.reset(); render();
	}
	private function back():Void {
		if (busy) return;
		if (standalone) { if (onComposerClose != null) onComposerClose(); return; }
		if (pending != "") pending = "";
		else if (composing) { composing = false; draftTo = ""; draftBody = ""; }
		else selected = null;
		notice = ""; pane.reset(); render();
	}
	private function confirm(action:String):Void { pending = action; notice = ""; pane.reset(); render(); }
	private function submit():Void {
		saveDraft(); notice = MessageData.validate(draftTo, draftBody);
		if (notice != "") { render(); return; }
		perform("send");
	}
	private function perform(action:String):Void {
		if (busy || disposedPage) return;
		var request = new MessageRequest(action, selected == null ? 0 : selected.id, draftTo, draftBody, guildMessage);
		busy = true; notice = "Working…"; render();
		guard.watch(post(request.url, request.fields, guard.wrap(function(body) {
			var result = SuperLoader.decodeJson(request.url, body, false);
			if (!result.success) { actionError(result.message); return; }
			busy = false; pending = "";
			if (action == "send" && standalone) { if (onComposerClose != null) onComposerClose(); return; }
			if (action == "send") { composing = false; draftTo = ""; draftBody = ""; notice = "Message sent."; }
			else if (action == "report") notice = "Message reported.";
			else { selected = null; if (action == "deleteAll") page = 1; refresh(); return; }
			render();
		}), guard.wrap(actionError)));
	}
	private function actionError(error:String):Void { busy = false; notice = error == "" ? "Request failed. Please try again." : error; render(); }
	private function render():Void {
		if (disposedPage) return;
		var focused = stage == null ? null : stage.focus;
		var focusTo = toInput != null && focused == toInput.textField;
		var focusBody = bodyInput != null && focused == bodyInput.textField;
		var focusInput = focusTo ? toInput : focusBody ? bodyInput : null;
		var selectionStart = focusInput == null ? 0 : focusInput.selectionBeginIndex;
		var selectionEnd = focusInput == null ? 0 : focusInput.selectionEndIndex;
		toInput = null; bodyInput = null;
		links.remove(); links = new HtmlNameMaker(); view.clear(); pane.content.clear();
		view.panel(0, 56, w, Math.max(80, h - 56));
		pane.x = 12; pane.y = 68;
		var v = pane.content; var width = w - 24; var total:Float = 0;
		if (pending != "") {
			view.button("Back", 0, 0, 100, back).enabled = !busy;
			view.button("Confirm", w - 128, 0, 128, function() perform(pending), true).enabled = !busy;
			var prompt = pending == "deleteAll" ? "Delete all of your messages? This cannot be undone." : pending == "report" ? "Report this message to the moderators? Report password requests, harassment, or spam." : "Delete this message from " + selected.name + "?";
			v.label(prompt, 12, 8, width - 24, 90, 20);
			v.label(notice, 12, 100, width - 24, 64, 17);
			total = 172;
		} else if (composing) {
			view.button("Cancel", 0, 0, 100, back).enabled = !busy;
			view.button("Send", w - 112, 0, 112, submit, true).enabled = !busy;
			view.label(notice == "" ? "WRITE A MESSAGE" : notice, 116, 0, w - 240, 48, notice == "" ? 24 : 17, notice == "", 0xFFFFFF);
			v.label("To racer", 12, 4, 100, 28);
			toInput = v.own(new AuthInput(draftTo)); toInput.x = 116; toInput.y = 0; toInput.setSize(width - 128, 44); toInput.maxChars = 20; toInput.enabled = !busy;
			toInput.editable = !guildMessage;
			bodyInput = v.own(new AuthInput(draftBody)); bodyInput.x = 12; bodyInput.y = 54; bodyInput.setSize(width - 24, 130);
			bodyInput.textField.multiline = true; bodyInput.textField.wordWrap = true; bodyInput.maxChars = 1000; bodyInput.enabled = !busy;
			var count = v.label(draftBody.length + " / 1000", 12, 190, width - 24, 28);
			bodyInput.onChange = function(_) { saveDraft(); count.text = draftBody.length + " / 1000"; };
			toInput.onChange = function(_) saveDraft();
			var help = v.label("Rich formatting\n[b]bold[/b]  [i]italic[/i]  [u]underline[/u]\n[color=#FF0000]colored text[/color]\n[tiny]text[/tiny]  [small]text[/small]  [medium]text[/medium]\n[big]text[/big]  [large]text[/large]\n[url]https://pr2hub.com/[/url]\n[url=https://pr2hub.com/]link label[/url]\n[user]Racer[/user]  [level=50815]Newbieland 2[/level]\n[guild=183]PR2 Staff[/guild]", 12, 230, width - 24, 240, 16);
			help.height = help.textHeight + 8; total = 242 + help.height;
		} else if (selected != null) {
			view.button("Inbox", 0, 0, 100, back).enabled = !busy;
			view.button("Delete", 112, 0, 108, function() confirm("delete")).enabled = !busy;
			view.button("Report", 232, 0, 108, function() confirm("report")).enabled = !busy;
			view.button("Reply", w - 108, 0, 108, function() compose(true), true).enabled = !busy;
			var sender = v.label("", 8, 0, width - 16, 34, 22, true); sender.mouseEnabled = true;
			sender.htmlText = links.makeName(selected.name, selected.group); links.listenForLink(sender);
			v.label((selected.guild ? "Guild message • " : "") + Date.fromTime(selected.time * 1000.0).toString(), 8, 38, width - 16, 28, 15);
			var body = v.label("", 8, 76, width - 16, 30, 18); body.mouseEnabled = true;
			body.htmlText = MessageData.html(MessageData.filtered(selected.body), selected.group); links.listenForLink(body);
			body.height = Math.max(36, body.textHeight + 8);
			var y = 88 + body.height;
			v.label(notice, 8, y, width - 16, 68, 17); total = y + (notice == "" ? 0 : 76);
		} else {
			view.button("Compose", 0, 0, 128, function() compose(), true);
			view.button("Refresh", 140, 0, 112, refresh).enabled = !loading;
			view.button("Delete all", w - 124, 0, 124, function() confirm("deleteAll")).enabled = !loading && !failed;
			if (loading || failed || rows.length == 0) {
				v.label(loading ? "Loading messages…" : failed ? notice : "No messages on this page.", 8, 12, width - 16, 72, 18);
				if (failed) v.button("Try again", 8, 90, 144, refresh, true);
				total = failed ? 150 : 96;
			} else {
				for (i in 0...rows.length) {
					var row = rows[i]; var y = i * 82;
					v.singleLine((row.guild ? "[Guild] " : "") + row.name, 8, y, width - 120, 32, 22, true);
					var preview = new openfl.text.TextField();
					preview.multiline = true;
					preview.htmlText = MessageData.html(MessageData.filtered(row.body), row.group);
					v.singleLine(StringTools.replace(StringTools.replace(preview.text, "\r", " "), "\n", " "), 8, y + 36, width - 120, 30, 16);
					v.button("Read", width - 104, y + 12, 96, function() openMessage(row));
				} total = rows.length * 82;
			}
			if (!loading) {
				v.button("Previous", 8, total, 120, function() changePage(page - 1)).enabled = page > 1;
				v.label("Page " + page, 144, total + 8, width - 288, 30, 18);
				v.button("Next", width - 128, total, 120, function() changePage(page + 1)).enabled = page < 99;
				total += 60;
				if (!failed && notice != "") { v.label(notice, 8, total, width - 16, 60, 17); total += 64; }
			}
		}
		pane.setSize(width, Math.max(44, h - 80), total);
		var restoreInput = focusTo ? toInput : focusBody ? bodyInput : null;
		if (restoreInput != null && !busy) { restoreInput.focus(); restoreInput.setSelection(selectionStart, selectionEnd); }
	}
	override public function remove():Void {
		if (disposedPage) return; disposedPage = true;
		source.remove(); guard.remove(); links.remove(); pane.remove(); view.remove();
		draftTo = ""; draftBody = ""; super.remove();
	}
}
