package com.hurlant.crypto.symmetric;

import pr2.crypto.ByteArrayCompat;

interface IPad {
	function pad(a:ByteArrayCompat):Void;
	function unpad(a:ByteArrayCompat):Void;
	function setBlockSize(bs:Int):Void;
}
