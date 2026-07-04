package pr2.util;

class AsyncRemovalGuardTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testWrapNoopsAfterRemove();
		testWatchRemovesTrackedResources();
		trace('AsyncRemovalGuardTest passed $assertions assertions');
	}

	private static function testWrapNoopsAfterRemove():Void {
		var guard = new AsyncRemovalGuard();
		var calls = 0;
		var wrapped = guard.wrap(function(value:String):Void {
			if (value == "loaded") {
				calls++;
			}
		});
		wrapped("loaded");
		guard.remove();
		wrapped("loaded");
		assertEquals(1, calls, "wrapped callback stops after removal");
		assertEquals(false, guard.isActive(), "guard reports inactive after removal");
	}

	private static function testWatchRemovesTrackedResources():Void {
		var guard = new AsyncRemovalGuard();
		var first = new FakeAsyncResource();
		guard.watch(first);
		guard.remove();
		assertEquals(1, first.removes, "tracked resource removed with guard");

		var second = new FakeAsyncResource();
		guard.watch(second);
		assertEquals(1, second.removes, "resource added after removal is removed immediately");
		guard.remove();
		assertEquals(1, first.removes, "guard removal is idempotent");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class FakeAsyncResource {
	public var removes:Int = 0;

	public function new() {}

	public function remove():Void {
		removes++;
	}
}
