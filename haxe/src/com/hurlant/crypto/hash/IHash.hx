package com.hurlant.crypto.hash;

import pr2.crypto.ByteArrayCompat;

interface IHash {
	function getInputSize():Int;
	function getHashSize():Int;
	function hash(src:ByteArrayCompat):ByteArrayCompat;
	function toString():String;
}
