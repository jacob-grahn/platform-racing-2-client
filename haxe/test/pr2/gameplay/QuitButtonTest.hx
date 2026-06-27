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

class QuitButtonTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testMouseQuitsImmediately();
		testSpaceConfirmsWhileRacing();
		testSpaceQuitsWhenDone();
		testGlowControls();
		testGamePageQuitFlow();
		testGamePagePrizeCommands();
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
		var ok = Std.downcast(LobbyArt.findByName(popup, "ok_bt"), InteractiveObject);
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
		var glow = Std.downcast(LobbyArt.findByName(quit, "glow"), pr2.runtime.PR2MovieClip);
		var offFrame = glow.currentFrame;
		quit.startGlow();
		assertEquals(true, glow.currentFrame > offFrame, "startGlow enters the on animation");
		quit.stopGlow();
		assertEquals(offFrame, glow.currentFrame, "stopGlow returns to the off frame");
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
		var returnButton = Std.downcast(LobbyArt.findByName(finish, "return_bt"), InteractiveObject);
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

		game.remove();
		assertEquals(true, PrizePopup.instance.fadeOutStarted, "GamePage removal fades out the active prize popup");
		closeAll();
	}

	private static function button(owner:openfl.display.DisplayObjectContainer):InteractiveObject {
		return Std.downcast(LobbyArt.findByName(owner, "quit_bt"), InteractiveObject);
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
