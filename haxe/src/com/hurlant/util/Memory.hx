package com.hurlant.util;

class Memory {
	public static var used(get, never):Int;

	public static function gc():Void {
		#if cpp
		cpp.vm.Gc.run(true);
		#end
	}

	private static function get_used():Int {
		#if cpp
		return Std.int(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE) & 0x7FFFFFFF);
		#else
		return 0;
		#end
	}
}
