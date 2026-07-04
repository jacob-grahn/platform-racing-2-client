package pr2.gameplay.items;

import com.jiggmin.data.SecureData;

class Item {
	public final code:Int;
	public final name:String;
	public final initialUses:Int;
	public final reloadFrames:Int;
	public final reloadTimeMs:Int;
	public var reloadFramesRemaining(default, null):Int = 0;
	private var available:Bool = false;

	public function new(code:Int, name:String, initialUses:Int = 1, reloadTimeMs:Int = 10, reloadFrames:Int = 0) {
		this.code = code;
		this.name = name;
		this.initialUses = initialUses;
		this.reloadTimeMs = reloadTimeMs;
		this.reloadFrames = reloadFrames;
		setUses(initialUses);
		SecureData.setNumber("reloadTime", reloadTimeMs);
	}

	public function setSpace(pressed:Bool, owner:ItemRuntimeOwner):Void {
		if (!pressed) {
			available = true;
			return;
		}
		if (SecureData.getNumber("uses") > 0 && reloadFramesRemaining <= 0 && available) {
			use(owner);
		}
	}

	public function tickReload():Void {
		if (reloadFramesRemaining > 0) {
			reloadFramesRemaining--;
		}
	}

	public function consumeUse():Bool {
		var remaining = Std.int(SecureData.getNumber("uses")) - 1;
		setUses(remaining);
		if (remaining <= 0) {
			reloadFramesRemaining = 0;
			available = false;
			return true;
		}
		reloadFramesRemaining = reloadFrames;
		return false;
	}

	public function uses():Int {
		return Std.int(SecureData.getNumber("uses"));
	}

	private function setUses(uses:Int):Void {
		SecureData.setNumber("uses", uses);
	}

	public function use(owner:ItemRuntimeOwner):Void {}
}
