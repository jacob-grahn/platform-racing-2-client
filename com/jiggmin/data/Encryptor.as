// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.Encryptor = data.class_64

package com.jiggmin.data
{
    import com.hurlant.crypto.symmetric.AESKey;
    import com.hurlant.crypto.symmetric.CBCMode;
    import com.hurlant.crypto.symmetric.IVMode;
    import com.hurlant.util.Base64;
    import flash.utils.ByteArray;

    public class Encryptor 
    {

        private var mode:CBCMode;
        private var iv:String;


        // _loc2 = byteArr
        // _loc3 = pad
        // _loc4 = key
        public function setKey(s:String)
        {
            var byteArr:ByteArray = this.stringToByteArray(s);
            var pad:AESPad = new AESPad();
            var key:AESKey = new AESKey(byteArr);
            this.mode = new CBCMode(key, pad);
        }

        // _loc2 = byteArr
        public function setIV(s:String)
        {
            var byteArr:ByteArray = this.stringToByteArray(s);
            IVMode(this.mode).IV = byteArr;
            this.iv = s;
        }

        // _loc2 = byteArr
        public function encrypt(s:String):String
        {
            var byteArr:ByteArray = new ByteArray();
            byteArr.writeUTFBytes(s);
            this.mode.encrypt(byteArr);
            return this.byteArrayToString(byteArr);
        }

        // _loc2 = byteArr
        public function decrypt(s:String):String
        {
            var byteArr:ByteArray = this.stringToByteArray(s);
            this.mode.decrypt(byteArr);
            byteArr.position = 0;
            return byteArr.readUTFBytes(byteArr.bytesAvailable);
        }

        private function byteArrayToString(a:ByteArray):String
        {
            return Base64.encodeByteArray(a);
        }

        private function stringToByteArray(s:String):ByteArray
        {
            return Base64.decodeToByteArray(s);
        }

        public function remove()
        {
            this.mode = null;
        }


    }
}//package com.jiggmin.data

