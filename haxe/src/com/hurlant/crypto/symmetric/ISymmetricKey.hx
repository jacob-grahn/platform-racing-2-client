package com.hurlant.crypto.symmetric;

import pr2.crypto.ByteArrayCompat;

interface ISymmetricKey {
	function getBlockSize():Int;
	function encrypt(block:ByteArrayCompat, index:Int = 0):Void;
	function decrypt(block:ByteArrayCompat, index:Int = 0):Void;
	function dispose():Void;
	function toString():String;
}
