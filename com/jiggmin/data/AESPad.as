// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.AESPad = data.class_111

package com.jiggmin.data
{
    import com.hurlant.crypto.symmetric.IPad;
    import flash.utils.ByteArray;

    public class AESPad implements IPad 
    {

        private var blockSize:uint;
        private var char0:String = String.fromCharCode(0);

        public function AESPad(i:uint=0)
        {
            this.blockSize = i;
        }

        public function pad(byteArr:ByteArray):void
        {
            while ((byteArr.length % this.blockSize) != 0) {
                byteArr.writeUTFBytes(this.char0);
            }
        }

        // _loc2 = s
        public function unpad(byteArr:ByteArray):void
        {
            byteArr.position = 0;
            var s:String = byteArr.readUTFBytes(byteArr.bytesAvailable);
            s.split(this.char0).join("");
            byteArr.writeUTFBytes(s);
        }

        public function setBlockSize(i:uint):void
        {
            this.blockSize = i;
        }


    }
}//package com.jiggmin.data

