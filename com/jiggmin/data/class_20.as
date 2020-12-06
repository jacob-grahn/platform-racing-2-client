// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.class_20

package com.jiggmin.data
{
    import com.hurlant.util.Base64;

    public class class_20 
    {

        private var items:Object = new Object();


        public function setNumber(_arg_1:String, _arg_2:Number)
        {
            var _local_3:Number = Math.ceil(Math.random() * 999999) - 500000;
            var _local_4:Number = _arg_2 + _local_3;
            this.method_350(_arg_1, _local_4, _local_3);
        }

        public function getNumber(_arg_1:String):Number
        {
            var _local_2:Object = this.method_162(_arg_1);
            var _local_3:Number = 0;
            if (_local_2 != null) {
                _local_3 = _local_2.hidden - _local_2.key;
            }
            return (_local_3);
        }

        // _loc3 = int
        // method_15 = setBool
        public function setBool(s:String, bool:Boolean)
        {
            var num:int = 0;
            if (bool) {
                num = 1;
            }
            this.setNumber(s, num);
        }

        // _loc2 = num
        // _loc3 = bool
        public function getBool(s:String):Boolean
        {
            var num:int = this.getNumber(s);
            var bool:Boolean = false;
            if (num === 1) {
                bool = true;
            }
            return bool;
        }

        // _loc3 = encryptor
        // method_98 = initEncryptor
        public function initEncryptor(_arg_1:String, salt:String)
        {
            var encryptor:Encryptor = new Encryptor();
            encryptor.setKey(Base64.encode(Data.method_439(16)));
            encryptor.setIV(Base64.encode(Data.method_439(16)));
            this.method_350(_arg_1, encryptor.encrypt(salt), encryptor);
        }

        // _loc3 = encryptor
        public function getString(_arg_1:String):String
        {
            var _local_2:Object = this.method_162(_arg_1);
            if (_local_2 == null) {
                return null;
            }
            var encryptor:Encryptor = Encryptor(_local_2.key);
            var _local_4:String = encryptor.decrypt(_local_2.hidden);
            return _local_4;
        }

        private function method_350(_arg_1:String, _arg_2:*, _arg_3:*)
        {
            var _local_4:Object;
            _local_4 = this.method_162(_arg_1);
            if (_local_4 != null) {
                _local_4.hidden = _arg_2;
                _local_4.key = _arg_3;
            } else {
                _local_4 = new Object();
                _local_4.hidden = _arg_2;
                _local_4.key = _arg_3;
                this.items[_arg_1] = _local_4;
            }
        }

        private function method_162(_arg_1:String):Object
        {
            return this.items[_arg_1];
        }

        public function remove()
        {
            this.items = null;
        }


    }
}//package com.jiggmin.data

