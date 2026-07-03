package com.hurlant.crypto.prng;

import pr2.crypto.ByteArrayCompat;

interface IPRNG {
	function getPoolSize():Int;
	function init(key:ByteArrayCompat):Void;
	function next():Int;
	function dispose():Void;
	function toString():String;
}
