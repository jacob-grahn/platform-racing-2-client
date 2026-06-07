// Decompiled by AS3 Sorcerer 5.98

//data.SecureData

package com.jiggmin.data
{
    public class SecureData 
    {

        private static var h:SecureStore = new SecureStore();


        public static function setNumber(_arg_1:String, _arg_2:Number)
        {
            h.setNumber(_arg_1, _arg_2);
        }

        public static function getNumber(_arg_1:String):Number
        {
            return (h.getNumber(_arg_1));
        }

        public static function setBool(_arg_1:String, _arg_2:Boolean)
        {
            h.setBool(_arg_1, _arg_2);
        }

        public static function getBool(_arg_1:String):Boolean
        {
            return (h.getBool(_arg_1));
        }

        public static function initEncryptor(_arg_1:String, _arg_2:String)
        {
            h.initEncryptor(_arg_1, _arg_2);
        }

        public static function getString(_arg_1:String):String
        {
            return (h.getString(_arg_1));
        }


    }
}

