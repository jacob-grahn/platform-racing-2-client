package com.hurlant.crypto.symmetric;

import pr2.crypto.ByteArrayCompat;

interface ICipher {
	function getBlockSize():Int;
	function encrypt(src:ByteArrayCompat):Void;
	function decrypt(src:ByteArrayCompat):Void;
	function dispose():Void;
	function toString():String;
}
