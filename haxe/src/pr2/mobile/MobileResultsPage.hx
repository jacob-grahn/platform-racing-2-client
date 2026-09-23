package pr2.mobile;

import openfl.display.Shape;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.gameplay.LevelRating;
import pr2.gameplay.RaceResults;
import pr2.gameplay.ResultsState;
import pr2.lobby.LobbySession;
import pr2.lobby.NumberFormat;
import pr2.lobby.dialogs.Popup;
import pr2.page.auth.AuthDialog;
import pr2.ui.controls.NativeControl;

/** Landscape results: server awards, shared XP progression, and confirmed rating. */
class MobileResultsPage extends Popup implements RaceResults {
	private var view:LobbyView;
	private var rewards:MobileScrollPane;
	private var details:MobileScrollPane;
	private var state = new ResultsState();
	private var rating:LevelRating;
	private var selection:Int = 0;
	private var confirmation:AuthDialog;
	private var onReturn:Void->Void;
	private var onClose:RaceResults->Void;
	private var returning:Bool = false;
	private var levelTitle:String;
	private var outcome:String;
	private var viewportW:Float = 844;
	private var viewportH:Float = 390;
	private var progressFill:Shape;
	private var progressText:TextField;
	private var progressWidth:Float = 0;
	private var lastRatingMessage:String = "";
	private var ownerStage:openfl.display.Stage;

	public function new(levelId:Int, title:String, outcome:String, onReturn:Void->Void, onClose:RaceResults->Void) {
		super(false);
		this.onReturn = onReturn; this.onClose = onClose;
		this.levelTitle = title == "" ? "Level " + levelId : title; this.outcome = outcome;
		rating = new LevelRating(levelId); rating.onChange = redraw;
		view = new LobbyView(); addChild(view);
		rewards = new MobileScrollPane(); details = new MobileScrollPane();
		ownerStage = AppStage.stage;
		if (ownerStage != null) {
			ownerStage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown, true, 1500);
			layoutForSize(ownerStage.stageWidth, ownerStage.stageHeight);
		} else layoutForSize(844, 390);
		addEventListener(Event.ENTER_FRAME, animateProgress);
	}
	override public function layoutForSize(w:Float, h:Float):Void {
		x = y = 0; scaleX = scaleY = 1; viewportW = w; viewportH = h;
		if (view != null) redraw();
		if (confirmation != null) confirmation.resizeViewport(w, h);
	}
	private function redraw():Void {
		if (isRemoved() || fadeOutStarted || view == null) return;
		var oldRewardOffset = rewards.content.y, oldDetailOffset = details.content.y;
		view.clear(); rewards.content.clear(); details.content.clear();
		progressFill = null; progressText = null;
		var w = viewportW, h = viewportH;
		view.graphics.beginFill(0x0A1F33, .82); view.graphics.drawRect(0, 0, w, h); view.graphics.endFill();
		if (h > w) {
			view.panel(16, h / 2 - 70, w - 32, 140);
			view.label("Rotate to landscape", 32, h / 2 - 48, w - 64, 54, 26, true);
			view.label("Your race results will be here.", 32, h / 2 + 8, w - 64, 48, 16);
			return;
		}
		var inset = w >= 760 ? 44 : 16;
		var pw = w - inset * 2;
		view.panel(inset, 12, pw, h - 24);
		view.label(outcome, inset + 18, 22, pw - 36, 40, 30, true);
		view.singleLine(levelTitle, inset + 18, 61, pw - 36, 28, 17);
		var split = w >= 640;
		var inner = pw - 36;
		var col = split ? (inner - 20) / 2 : inner;
		var bodyH = Math.max(48, h - 168);
		view.addChild(rewards); view.addChild(details);
		rewards.x = inset + 18; rewards.y = 94;
		details.x = split ? rewards.x + col + 20 : rewards.x; details.y = 94;
		var left = rewards.content;
		left.label("RACE REWARDS", 0, 0, col, 28, 20, true);
		var cursor:Float = 36;
		if (state.awards.length == 0) {
			left.label(LobbySession.isGuest() ? "Playing as a guest.\nNo rewards reported." : "No rewards reported yet.", 0, cursor, col, 64, 16);
			cursor += 70;
		} else {
			for (award in state.awards) {
				var bonus = left.label(award.bonus, 0, cursor, col - 82, 40, 16);
				bonus.height = Math.max(32, bonus.textHeight + 6);
				var xp = left.label(award.exp, col - 80, cursor, 80, 40, 18, true);
				xp.height = Math.max(32, xp.textHeight + 6);
				cursor += Math.max(bonus.height, xp.height) + 8;
			}
		}
		var right = split ? details.content : left;
		var top = split ? 0 : cursor + 20;
		right.label(state.hasExperience ? (state.gained >= 0 ? "+" : "") + NumberFormat.withCommas(state.gained) + " XP" : "EXPERIENCE", 0, top, col, 32, 24, true);
		if (state.hasExperience) {
			progressWidth = col - 4;
			right.graphics.lineStyle(2, 0x18334B); right.graphics.beginFill(0xD5E2E9);
			right.graphics.drawRoundRect(2, top + 32, progressWidth, 14, 10, 10); right.graphics.endFill();
			progressFill = new Shape(); progressFill.x = 3; progressFill.y = top + 33; right.addChild(progressFill);
			progressText = right.label("", 0, top + 48, col, 22, 15);
			updateProgress();
		} else {
			right.label("No experience update received.", 0, top + 36, col, 44, 15);
		}
		right.label("Rate this level", 0, top + 70, col, 26, 18, true);
		var cell = Math.min(56, (col - 16) / 5);
		for (i in 1...6) {
			var value = i;
			var button = right.button("", (i - 1) * (cell + 4), top + 100, cell, function() { selection = value; redraw(); }, i <= selection, 44);
			button.name = value + (value == 1 ? " star" : " stars"); button.enabled = !rating.pending;
			var star = pr2.assets.NativeAssets.svg(pr2.assets.NativeAssetIds.StaticSvg.RatingStarHighlight);
			var bounds = star.getBounds(star);
			star.scaleX = star.scaleY = 26 / Math.max(bounds.width, bounds.height);
			star.x = button.x + (cell - bounds.width * star.scaleX) / 2 - bounds.x * star.scaleX;
			star.y = button.y + (44 - bounds.height * star.scaleY) / 2 - bounds.y * star.scaleY;
			star.alpha = i <= selection ? 1 : .35; right.addChild(star);
		}
		var submit = right.button(rating.pending ? "Submitting…" : rating.failed ? "Retry rating" : "Submit rating", 0, top + 154, col, confirmRating, true);
		submit.enabled = selection != 0 && !rating.pending;
		var detailHeight = top + 202;
		if (rating.message != "") {
			var message = right.label(rating.message, 0, top + 208, col, 54, 14, false, rating.failed ? 0xA52735 : 0x18334B);
			message.height = Math.max(28, message.textHeight + 6);
			detailHeight = top + 208 + message.height;
		}
		rewards.setSize(col, bodyH, split ? cursor : detailHeight);
		details.visible = split; if (split) details.setSize(col, bodyH, detailHeight);
		rewards.setOffset(oldRewardOffset); details.setOffset(oldDetailOffset);
		if (rating.message != lastRatingMessage && rating.message != "") {
			(split ? details : rewards).setOffset(-Math.min(top + 208, Math.max(0, detailHeight - bodyH)));
		}
		lastRatingMessage = rating.message;
		var footerY = h - 62;
		view.button("Keep watching", inset + 18, footerY, (inner - 12) * .43, function() startFadeOut());
		view.button("Return to lobby", inset + 30 + (inner - 12) * .43, footerY, (inner - 12) * .57, returnToLobby, true);
	}
	private function confirmRating():Void {
		if (selection == 0 || rating.pending || confirmation != null || fadeOutStarted) return;
		var chosen = selection;
		confirmation = pr2.app.ScreenFactory.authDialog("Confirm", "Rate this level " + chosen + (chosen == 1 ? " star?" : " stars?"), ["heading" => "Submit your rating?", "confirmLabel" => "Submit rating", "cancelLabel" => "Back"]);
		confirmation.onCancel = dismissConfirmation;
		confirmation.onConfirm = function() { dismissConfirmation(); rating.submit(chosen); };
		addChild(confirmation); confirmation.resizeViewport(viewportW, viewportH);
	}
	private function dismissConfirmation():Void {
		if (confirmation == null) return;
		confirmation.dismiss(true); confirmation = null;
	}
	public function award(bonus:String, exp:String):Void { if (!isRemoved() && state.award(bonus, exp)) redraw(); }
	public function setExpGain(old:Int, next:Int, toRank:Int):Void { if (isRemoved()) return; state.setExpGain(old, next, toRank); redraw(); }
	private function animateProgress(_:Event):Void {
		if (!pr2.runtime.FrameClock.shouldRunSimulationFrame()) return;
		if (!state.hasExperience || !state.progress.active) return;
		state.progress.tick(); updateProgress();
	}
	private function updateProgress():Void {
		if (progressFill == null || progressText == null) return;
		progressFill.graphics.clear(); progressFill.graphics.beginFill(0xD1ED62);
		progressFill.graphics.drawRoundRect(0, 0, Math.max(0, Math.min(1, state.progress.ratio())) * (progressWidth - 2), 12, 8, 8); progressFill.graphics.endFill();
		progressText.text = state.progress.text() + " XP toward rank";
	}
	private function returnToLobby():Void {
		if (returning || isRemoved() || fadeOutStarted) return;
		returning = true;
		if (onReturn != null) onReturn();
		if (!isRemoved()) startFadeOut();
	}
	private function keyDown(e:KeyboardEvent):Void {
		if (confirmation != null || !isTopmostForTests() || fadeOutStarted) return;
		if (e.keyCode == 27) { e.preventDefault(); e.stopImmediatePropagation(); startFadeOut(); }
		if (e.keyCode != 9 || ownerStage == null) return;
		var candidates = view.controls.concat(rewards.content.controls).concat(details.visible ? details.content.controls : []).filter(function(c) return c.enabled);
		var index = -1;
		for (i in 0...candidates.length) if (ownerStage.focus == candidates[i]) index = i;
		if (candidates.length > 0) {
			index = index == -1 ? (e.shiftKey ? candidates.length - 1 : 0) : (index + (e.shiftKey ? candidates.length - 1 : 1)) % candidates.length;
			var target = candidates[index]; NativeControl.showFocusIndicator = true; target.focus();
			for (pane in [rewards, details]) if (pane.visible && pane.content.contains(target)) {
				var bottom = target.y + target.height + pane.content.y;
				if (bottom > pane.scrollRect.height) pane.setOffset(pane.content.y - (bottom - pane.scrollRect.height));
				if (target.y + pane.content.y < 0) pane.setOffset(-target.y);
			}
		}
		e.preventDefault(); e.stopImmediatePropagation();
	}
	override public function startFadeOut():Void { dismissConfirmation(); rating.remove(); view.mouseChildren = false; super.startFadeOut(); }
	override public function remove():Void {
		if (isRemoved()) return;
		dismissConfirmation(); rating.remove();
		if (ownerStage != null) ownerStage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown, true);
		removeEventListener(Event.ENTER_FRAME, animateProgress);
		rewards.remove(); details.remove(); view.remove();
		var close = onClose; onClose = null; onReturn = null;
		super.remove(); if (close != null) close(this);
	}
}
