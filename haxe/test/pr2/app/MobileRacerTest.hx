package pr2.app;

import pr2.lobby.account.AccountCustomizeData;
import pr2.lobby.account.AccountState;
import pr2.lobby.account.RacerModel;
import pr2.lobby.account.Settings;
import pr2.lobby.account.Presets;
import pr2.mobile.MobileRacerPage;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

@:access(pr2.mobile.MobileRacerPage)
class MobileRacerTest {
	static function payload():Array<String> return ["16777215", "16764057", "3381759", "3355443", "2", "1", "1", "1", "1,2,3", "1,2", "1,2", "1,2", "50", "50", "50", "5", "1", "3", "123", "456", "789", "321", "2", "*", "2", "", "0"];
	public static function main():Void {
		Settings.useMemoryStoreForTests(); Settings.init("MobileRacerTest"); Presets.resetForTests();
		var classic = new pr2.lobby.tabs.AccountTab(); classic.initialize(); classic.setCustomizeInfo(payload());
		@:privateAccess classic.saveCustomizeInfo();
		var classicCommand = LobbySocket.lastSent();
		@:privateAccess classic.useRankToken();
		check(LobbySocket.lastSent() == "get_customize_info`", "classic token controls use shared session");
		classic.remove();
		LobbySocket.resetSent();
		var page = cast(ScreenFactory.racer(), MobileRacerPage); page.initialize();
		check(LobbySocket.lastSent() == "get_customize_info`", "requests real customization data");
		CommandHandler.commandHandler.dispatch("setCustomizeInfo", payload());
		check(page.model.data != null && AccountState.currentHat == 2, "server data establishes shared hat access");
		var model = page.model;
		model.save(); check(LobbySocket.lastSent() == classicCommand, "classic and mobile serialize the same server customization");
		check(model.remaining() == 5, "rank budget");
		model.stat("speed", 100); check(model.outfit.speed == 55 && model.remaining() == 0, "stat cannot exceed total");
		model.stat("jumping", -10); model.stat("speed", 300);
		check(model.outfit.speed == 100 && model.outfit.jumping == 0, "stats clamp 0 to 100");
		model.select("hat", 999); check(model.outfit.hat == 2, "catalog cannot equip locked parts");
		model.step("hat", 1); check(model.outfit.hat == 3 && model.secondary("hat") == -1, "non-epic part masks secondary");
		model.step("hat", 1); check(model.outfit.hat == 1, "owned part stepper wraps");
		model.select("hat", 2); check(model.secondary("hat") == 123 && model.epic("head"), "epic color retained and wildcard honored");
		page.changed(); var count = LobbySocket.sentCommands.length; page.changed();
		check(LobbySocket.sentCommands.length == count, "save deduplicates unchanged state");
		check(LobbySocket.lastSent() == "set_customize_info`16777215`16764057`3381759`3355443`123`456`-1`-1`2`1`1`1`100`50`0", "exact server serialization and epic masking");
		page.editColor("head", true); page.draftColor = 0x123456; page.choose("Style");
		check(model.outfit.headColor2 == 456, "cancel color preserves state");
		page.editColor("head", true); page.applyColor(0x123456);
		check(model.outfit.headColor2 == 0x123456, "epic color applies");
		model.savePreset(10); Presets.resetForTests(); check(Presets.getPreset(10).headColor2 == 0x123456, "slot ten persists through shared store");
		model.outfit.headColor = 999; page.equip(10); check(page.confirmation != null && model.outfit.headColor == 999, "loadout asks before replacement");
		page.confirmation.onCancel(); check(model.outfit.headColor == 999, "cancel loadout changes nothing");
		page.equip(10); page.confirmation.onConfirm(); check(model.outfit.headColor == 16764057, "loadout applies colors and stats");
		model.session.token(true); model.session.token(true); count = LobbySocket.sentCommands.length; model.session.token(true);
		check(model.session.used == 3 && model.session.rank == 7 && LobbySocket.sentCommands.length == count, "tokens bounded by inventory");
		model.session.token(false); model.session.token(false); model.session.token(false); count = LobbySocket.sentCommands.length; model.session.token(false);
		check(model.session.used == 0 && model.session.rank == 4 && LobbySocket.sentCommands.length == count, "token removal bounded at zero");
		check(LobbySocket.lastSent() == "get_customize_info`", "token changes request authoritative stats");
		var happy = payload(); happy[26] = "1"; page.receive(happy);
		check(model.total == 300, "happy-hour budget");
		page.choose("Stats");
		var slider:pr2.mobile.MobileValueSlider = null;
		for (control in page.pane.content.controls) if (slider == null) slider = Std.downcast(control, pr2.mobile.MobileValueSlider);
		count = LobbySocket.sentCommands.length;
		slider.setValueFromUser(70); slider.setValueFromUser(80);
		check(@:privateAccess slider.graphics.__hitTest(20, 4, true, new openfl.geom.Matrix()), "slider redraw retains the whole touch target");
		check(model.outfit.speed == 80 && LobbySocket.sentCommands.length == count, "slider previews without sending every pointer event");
		slider.onRelease(); check(LobbySocket.sentCommands.length == count + 1, "slider release commits exactly once");
		page.editColor("head", false);
		page.draftHex = "12AB34"; page.draftColor = 0x12AB34;
		page.setLayout(635, 269);
		check(page.draftHex == "12AB34" && page.mode == "Color", "resize preserves color draft and destination");
		for (mode in ["Style", "Stats", "Loadouts", "Catalog", "Color"]) {
			page.choose(mode);
			for (control in page.pane.content.controls) {
				check(control.controlHeight >= 44, "touch target height in " + mode);
				check(control.x >= 0 && control.x + control.controlWidth <= page.pane.scrollRect.width + .1, "control fits compact width in " + mode);
			}
		}
		page.choose("Catalog");
		for (i in 0...page.pane.content.numChildren) {
			var text = Std.downcast(page.pane.content.getChildAt(i), openfl.text.TextField);
			if (text != null) check(text.text.indexOf("Vault of Magics") < 0, "mobile catalog omits retired Vault copy");
		}
		page.equip(1); var late = page.confirmation.onConfirm;
		page.remove(); page.remove(); count = LobbySocket.sentCommands.length; late();
		CommandHandler.commandHandler.dispatch("setCustomizeInfo", payload());
		check(LobbySocket.sentCommands.length == count && page.character == null, "teardown rejects pending confirmation and removes command ownership");
		Settings.clear(); pr2.lobby.LobbySession.clear();
		trace("MobileRacerTest passed"); Sys.exit(0);
	}
	static function check(value:Bool, message:String):Void { if (!value) throw message; }
}
