package pr2.lobby.level;

import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

typedef RaceSlot = { var name:String; var rank:Int; var me:Bool; var ready:Bool; }

/** Live roster and socket actions shared by classic tiles and mobile race entry. */
class LevelRoom {
	public final levelId:Int;
	public final version:Int;
	public var slots(default, null):Array<RaceSlot> = [];
	public var localSlot(default, null):Int = -1;
	public var pendingSlot(default, null):Int = -1;
	public var onChange:Void->Void;
	public var onFill:Array<String>->Void;
	public var onConfirm:Array<String>->Void;
	public var onClear:Array<String>->Void;
	private var alive:Bool = true;
	private var rejectLocalFill:Bool = false;
	public function new(levelId:Int, version:Int) {
		this.levelId = levelId; this.version = version;
		for (_ in 0...4) slots.push(empty());
		var cm = CommandHandler.commandHandler;
		cm.defineCommand("fillSlot" + key(), fill);
		cm.defineCommand("confirmSlot" + key(), confirm);
		cm.defineCommand("clearSlot" + key(), clear);
	}
	private function key():String return levelId + "_" + version;
	private static function empty():RaceSlot return {name:"", rank:0, me:false, ready:false};
	private static function index(args:Array<String>):Int {
		var n = args.length == 0 ? null : Std.parseInt(args[0]);
		return n == null || n < 0 || n > 3 ? -1 : n;
	}
	private function fill(args:Array<String>):Void {
		var n = index(args); if (!alive || n < 0) return;
		var rank = args.length > 2 ? Std.parseInt(args[2]) : 0;
		var me = args.length > 3 && args[3] == "me";
		if (me && rejectLocalFill) { LobbySocket.write("clear_slot`"); return; }
		if (localSlot == n && !me) localSlot = -1;
		if (me) {
			if (localSlot >= 0 && localSlot != n) slots[localSlot] = empty();
			localSlot = n; pendingSlot = -1; LevelLaunch.select(levelId, version);
		}
		if (pendingSlot == n) pendingSlot = -1;
		slots[n] = {name:args.length > 1 ? args[1] : "", rank:rank == null ? 0 : rank, me:me, ready:false};
		if (onFill != null) onFill(args); changed();
	}
	private function confirm(args:Array<String>):Void {
		var n = index(args); if (!alive || n < 0) return;
		slots[n].ready = true; if (onConfirm != null) onConfirm(args); changed();
	}
	private function clear(args:Array<String>):Void {
		var n = index(args); if (!alive || n < 0) return;
		slots[n] = empty();
		// The server clears the roster as a race starts. Flash Slot.clearSlot
		// changes the artwork only; keep the launch identity until startGame or
		// an explicit leave/teardown, otherwise the following start is rejected.
		if (localSlot == n) localSlot = -1;
		if (pendingSlot == n) pendingSlot = -1;
		if (onClear != null) onClear(args); changed();
	}
	public function join(slot:Int):Void {
		if (!alive || slot < 0 || slot > 3) return;
		rejectLocalFill = false;
		pendingSlot = slot;
		LobbySocket.write("fill_slot`" + key() + "`" + slot + "`" + LevelListingState.currentPageNum); changed();
	}
	public function play():Void { if (alive) LobbySocket.write("confirm_slot`"); }
	public function leave():Void {
		if (!alive) return;
		rejectLocalFill = true;
		LobbySocket.write("clear_slot`");
		LevelLaunch.clear(levelId, version);
		if (localSlot >= 0) slots[localSlot] = empty();
		localSlot = pendingSlot = -1; changed();
	}
	public function count():Int { var n = 0; for (slot in slots) if (slot.name != "") n++; return n; }
	private function changed():Void { if (onChange != null) onChange(); }
	public function remove():Void {
		if (!alive) return;
		if (localSlot >= 0 || pendingSlot >= 0) leave();
		LevelLaunch.clear(levelId, version);
		alive = false;
		var cm = CommandHandler.commandHandler;
		cm.defineCommand("fillSlot" + key(), null); cm.defineCommand("confirmSlot" + key(), null); cm.defineCommand("clearSlot" + key(), null);
		onChange = null; onFill = onConfirm = onClear = null;
	}
}
