package pr2.gameplay;

import openfl.display.InteractiveObject;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.ui.Keyboard;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.LobbySocket;
import pr2.page.GamePage;
import pr2.page.LobbyPage;
import pr2.page.PageHolder;
import pr2.util.DisplayUtil;

class QuitButtonTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testMouseQuitsImmediately();
		if (pr2.DeterministicTestMode.finishSmokeSuite("QuitButtonTest")) return;
		testSpaceConfirmsWhileRacing();
		testSpaceQuitsWhenDone();
		testGlowControls();
		testGamePageQuitFlow();
		testGamePageAwardAndExpCommands();
		testGamePagePrizeCommands();
		testGamePageLuxCommand();
		testGamePageCowboyMode();
		testGamePageHappyHour();
		testGamePageHatCountdown();
		testReturnToLobbyRequiresConnectedSocket();
		closeAll();
		trace('QuitButtonTest passed $assertions assertions');
	}

	private static function testMouseQuitsImmediately():Void {
		var calls = 0;
		var quit = new QuitButton(function():Void calls++, function():Bool return false);
		button(quit).dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
		assertEquals(1, calls, "mouse release quits without confirmation");
		assertEquals(0, Popup.getOpen().length, "mouse release opens no confirmation");
		quit.remove();
	}

	private static function testSpaceConfirmsWhileRacing():Void {
		var calls = 0;
		var quit = new QuitButton(function():Void calls++, function():Bool return false);
		button(quit).dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, Keyboard.SPACE));
		assertEquals(0, calls, "space does not quit before confirmation");
		assertEquals(1, Popup.getOpen().length, "space opens a confirmation while racing");

		var popup = Std.downcast(Popup.getOpen()[0], ConfirmPopup);
		var ok = Std.downcast(DisplayUtil.findByName(popup, "ok_bt"), InteractiveObject);
		ok.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, calls, "confirmation invokes quit");
		popup.remove();
		quit.remove();
	}

	private static function testSpaceQuitsWhenDone():Void {
		var calls = 0;
		var quit = new QuitButton(function():Void calls++, function():Bool return true);
		button(quit).dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, Keyboard.SPACE));
		assertEquals(1, calls, "space quits immediately after the player is done");
		assertEquals(0, Popup.getOpen().length, "done player gets no confirmation");
		quit.remove();
	}

	private static function testGlowControls():Void {
		var quit = new QuitButton(function():Void {}, function():Bool return false);
		assertEquals(false, quit.glowActive, "glow starts off");
		quit.startGlow();
		assertEquals(true, quit.glowActive, "startGlow enters the on animation");
		quit.stopGlow();
		assertEquals(false, quit.glowActive, "stopGlow returns to the off state");
		quit.remove();
	}

	private static function testGamePageQuitFlow():Void {
		LobbySocket.resetSent();
		var holder = new PageHolder();
		var game = new GamePage(12345, 7);
		holder.changePage(game);
		var buttonPosition = button(game).localToGlobal(new Point());
		assertEquals(428, buttonPosition.x, "quit button x matches Flash stage position");
		assertEquals(369, buttonPosition.y, "quit button y matches Flash stage position");

		button(game).dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
		assertEquals("quit_race`", LobbySocket.lastSent(), "game page emits the Flash quit command");
		assertEquals(1, Popup.getOpen().length, "quitting opens the finish popup");

		var finish = Std.downcast(Popup.getOpen()[0], FinishedPage);
		var returnButton = Std.downcast(DisplayUtil.findByName(finish, "return_bt"), InteractiveObject);
		LobbySocket.simulateOpenForTests();
		returnButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, LobbySocket.sentCommands.indexOf("set_game_room`none") >= 0, "return clears the game room");
		assertEquals(true, Std.isOfType(holder.getCurrentPage(), LobbyPage), "return restores the lobby page");

		holder.getCurrentPage().remove();
		closeAll();
	}

	private static function testGamePagePrizeCommands():Void {
		var game = new GamePage(12345, 7);

		game.setPrize({
			type: "hat",
			id: 5,
			name: "Propeller Hat",
			desc: "Spins when you jump",
			universal: true
		});
		var announced = PrizePopup.instance;
		assertEquals("hat", announced.targetName, "setPrize opens a hat prize popup");
		assertEquals("Anyone who finishes this race wins a:", announced.bodyText, "setPrize uses unfinished universal wording");
		assertEquals("Propeller Hat", game.prize.name, "setPrize stores current prize");

		game.winPrize({
			type: "feet",
			id: 2,
			name: "Boots",
			desc: "",
			universal: false
		});
		assertEquals(false, Popup.getOpen().indexOf(announced) >= 0, "winPrize replaces the previous prize popup");
		assertEquals("foot", PrizePopup.instance.targetName, "winPrize opens the won prize popup");
		assertEquals("You won a pair of:", PrizePopup.instance.bodyText, "winPrize uses finished wording");

		game.cancelPrize("Bob");
		assertEquals(null, game.prize, "cancelPrize clears current prize");
		assertEquals("exp", PrizePopup.instance.targetName, "cancelPrize opens the cancel popup");
		assertEquals("Bob cancelled the prize for finishing this race.", PrizePopup.instance.detailText, "cancelPrize forwards the cancelling user");

		game.setPrize({
			type: "hat",
			id: 4,
			name: "Propeller Hat",
			desc: "",
			universal: false
		});
		var preRace = PrizePopup.instance;
		game.beginRace();
		assertEquals(true, preRace.fadeOutStarted, "beginRace fades out the active prize popup");

		var artifact = new PlaceArtifact({levelId: 12345, x: 10, y: 20, rot: 0});
		game.remove();
		assertEquals(true, PrizePopup.instance.fadeOutStarted, "GamePage removal fades out the active prize popup");
		assertEquals(true, artifact.fadeOutStarted, "GamePage removal fades out the active artifact placement popup");
		closeAll();
	}

	private static function testGamePageAwardAndExpCommands():Void {
		LobbySocket.resetSent();
		var game = new GamePage(12345, 7);

		game.award(["First Place", "+50"]);
		assertEquals(0, Popup.getOpen().length, "award before finish is queued");
		game.setExpGain(10, 60, 100);

		assertEquals("", LobbySocket.lastSent(), "setExpGain does not emit a quit command");
		assertEquals(true, game.playerDone, "setExpGain marks the player done");
		assertEquals(1, Popup.getOpen().length, "setExpGain opens the finish popup");
		var finish = Std.downcast(Popup.getOpen()[0], FinishedPage);
		assertEquals("First Place", LobbyArt.text(finish, "bonus1").text, "queued award fills the finish popup");
		assertEquals("+50", LobbyArt.text(finish, "exp1").text, "queued award exp fills the finish popup");
		assertEquals("+ 50", LobbyArt.text(finish, "expTotal").text, "setExpGain fills the exp total");

		game.award(["Speed Bonus", "+20"]);
		assertEquals("Speed Bonus", LobbyArt.text(finish, "bonus2").text, "award after finish updates the open popup");
		assertEquals(finish, game.finishedPage, "game page tracks the open finish popup");
		finish.remove();
		assertEquals(null, game.finishedPage, "finished popup removal clears the game page reference");

		game.remove();
		closeAll();
	}

	private static function testGamePageLuxCommand():Void {
		var popup = new LuxPopup(37, false);
		assertEquals("+37 Lux", popup.text, "LuxPopup writes the Flash gain label");
		assertEquals(pr2.net.ServerConfig.getHost() + "/img/luna.jpg", popup.imageUrl, "LuxPopup uses the Flash luna portrait URL");
		var close = Std.downcast(DisplayUtil.findByName(popup, "close_bt"), InteractiveObject);
		close.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, popup.fadeOutStarted, "LuxPopup close button fades it out");
		popup.remove();

		var game = new GamePage(12345, 7);
		game.setLuxGain(25);
		var opened = Popup.getOpen()[Popup.getOpen().length - 1];
		var lux = Std.downcast(opened, LuxPopup);
		assertEquals("+25 Lux", lux.text, "setLuxGain opens a LuxPopup");
		game.remove();
		assertEquals(false, Popup.getOpen().indexOf(lux) >= 0, "GamePage removal clears LuxPopup");
		closeAll();
	}

	private static function testGamePageHatCountdown():Void {
		LobbySocket.resetSent();
		var game = new GamePage(12345, 7);
		game.startHatCountdown();
		assertEquals(true, game.hatCountdownTimer != null, "startHatCountdown arms the timer");

		game.onHatCountdownTick();
		assertEquals("check_hat_countdown`", LobbySocket.lastSent(), "hat countdown emits the Flash command");

		var firstTimer = game.hatCountdownTimer;
		game.startHatCountdown();
		assertEquals(true, game.hatCountdownTimer != null, "restart keeps a timer armed");
		assertEquals(true, game.hatCountdownTimer != firstTimer, "restart replaces the old timer");

		game.cancelHatCountdown();
		assertEquals(null, game.hatCountdownTimer, "cancelHatCountdown clears the timer");

		game.startHatCountdown();
		game.remove();
		assertEquals(null, game.hatCountdownTimer, "page removal clears the timer");
		closeAll();
	}

	private static function testReturnToLobbyRequiresConnectedSocket():Void {
		LobbySocket.resetSent();
		var holder = new PageHolder();
		var game = new GamePage(12345, 7);
		holder.changePage(game);
		game.setExpGain(10, 60, 100);
		var finish = Std.downcast(Popup.getOpen()[0], FinishedPage);
		var returnButton = Std.downcast(DisplayUtil.findByName(finish, "return_bt"), InteractiveObject);
		returnButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(false, LobbySocket.sentCommands.indexOf("set_game_room`none") >= 0,
			"disconnected return does not clear the game room");
		assertEquals(game, holder.getCurrentPage(), "disconnected return leaves the game page active");

		LobbySocket.simulateOpenForTests();
		returnButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, LobbySocket.sentCommands.indexOf("set_game_room`none") >= 0,
			"connected return clears the game room");
		assertEquals(true, Std.isOfType(holder.getCurrentPage(), LobbyPage), "connected return restores the lobby page");

		holder.getCurrentPage().remove();
		closeAll();
	}

	private static function testGamePageCowboyMode():Void {
		var game = new GamePage(12345, 7);
		game.cowboyMode();
		assertEquals(1, game.cowboyModes.length, "cowboyMode adds the authored animation");
		var mode = game.cowboyModes[0];
		assertEquals(true, mode.parent == game, "cowboyMode attaches to the game page");

		for (_ in 0...120) {
			mode.advance();
		}
		assertEquals(82, mode.currentFrame, "cowboyMode stops on Flash frame 82");

		game.remove();
		assertEquals(0, game.cowboyModes.length, "game removal clears cowboy animations");
		assertEquals(true, mode.parent == null, "game removal detaches cowboy animation");
		closeAll();
	}

	private static function testGamePageHappyHour():Void {
		var game = new GamePage(12345, 7);
		game.happyHour();
		assertEquals(1, game.happyHours.length, "happyHour adds the authored animation");
		var happy = game.happyHours[0];
		assertEquals(true, happy.parent == game, "happyHour attaches to the game page");

		for (_ in 0...120) {
			happy.advance();
		}
		assertEquals(0, game.happyHours.length, "happyHour removes itself on Flash frame 100");
		assertEquals(true, happy.parent == null, "happyHour detaches after finishing");

		game.happyHour();
		happy = game.happyHours[0];
		game.remove();
		assertEquals(0, game.happyHours.length, "game removal clears happyHour animations");
		assertEquals(true, happy.parent == null, "game removal detaches happyHour animation");
		closeAll();
	}

	private static function button(owner:openfl.display.DisplayObjectContainer):InteractiveObject {
		return Std.downcast(DisplayUtil.findByName(owner, "quit_bt"), InteractiveObject);
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
