package pr2.lobby.level;

import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

/** The original CourseMenu protocol/timers, with no popup or layout dependency. */
class RaceEntryFlow {
	public var countdown(default, null):String = "";
	public var confirmed(default, null):Bool = false;
	public var onChange:Void->Void;
	private var onConfirm:Void->Void;
	private var onClose:Void->Void;
	private var timer:Int = 0;
	private var interval:Null<haxe.Timer>;
	private var wait:Null<haxe.Timer>;
	private var alive:Bool = true;
	public function new(onConfirm:Void->Void, onClose:Void->Void, onChange:Void->Void) {
		this.onConfirm = onConfirm; this.onClose = onClose; this.onChange = onChange;
		CommandHandler.commandHandler.defineCommand("forceTime", forceTime);
		CommandHandler.commandHandler.defineCommand("closeCourseMenu", remoteClose);
		wait = haxe.Timer.delay(close, 30000);
	}
	public static inline function initialTimer(elapsed:Int):Int return 16 - elapsed;
	public function forceTime(args:Array<String>):Void {
		if (!alive) return;
		stopTimers();
		var value = args.length > 0 ? Std.parseInt(args[0]) : null;
		if (value == null) value = 0;
		if (value < 0) {
			countdown = "--"; changed(); wait = haxe.Timer.delay(close, 30000);
		} else {
			timer = initialTimer(value); interval = new haxe.Timer(1000); interval.run = tick; tick();
		}
	}
	public function tick():Void {
		if (!alive) return;
		timer--;
		if (timer < 0) {
			timer = 0;
			if (interval != null) interval.stop(); interval = null;
			LobbySocket.write("force_start`");
		}
		countdown = Std.string(timer); changed();
	}
	public function play():Void {
		if (!alive) return;
		confirmed = true;
		if (wait != null) wait.stop(); wait = null;
		onConfirm(); changed();
	}
	private function changed():Void { if (onChange != null) onChange(); }
	private function remoteClose(_:Array<String>):Void close();
	public function close():Void { if (alive && onClose != null) onClose(); }
	private function stopTimers():Void {
		if (interval != null) interval.stop(); interval = null;
		if (wait != null) wait.stop(); wait = null;
	}
	public function remove():Void {
		if (!alive) return; alive = false; stopTimers();
		CommandHandler.commandHandler.defineCommand("forceTime", null);
		CommandHandler.commandHandler.defineCommand("closeCourseMenu", null);
		onConfirm = onClose = onChange = null;
	}
}
