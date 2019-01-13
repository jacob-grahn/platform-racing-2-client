// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//class_74

package 
{
    import flash.display.DisplayObject;

    public class class_74 
    {

        public static const const_93:Number = (180 / Math.PI);//57.2957795130823
        public static const const_78:Number = (Math.PI / 180);//0.0174532925199433


        public static function method_232(_arg_1:Number, _arg_2:Number):Number
        {
            return (Math.sqrt(((_arg_1 * _arg_1) + (_arg_2 * _arg_2))));
        }

        public static function method_848(_arg_1:Number, _arg_2:Number):Number
        {
            var _local_3:Number = (_arg_1 - _arg_2);
            if (_local_3 > 180) {
                _local_3 = (-360 + _local_3);
            }
            if (_local_3 < -180) {
                _local_3 = (360 + _local_3);
            }
            return (_local_3);
        }

        // method_8 = numLimit
        public static function numLimit(num:Number, min:Number, max:Number):Number
        {
            if (num < min) {
                num = min;
            }
            if (num > max) {
                num = max;
            }
            return num;
        }

        public static function method_348(_arg_1:*):String
        {
            var _local_2:* = (_arg_1 + "");
            if (_local_2.length < 4) {
                return (_local_2);
            }
            return ((method_348(_local_2.slice(0, -3)) + ",") + _local_2.slice(-3));
        }

        public static function method_314(_arg_1:DisplayObject, _arg_2:Number, _arg_3:Number)
        {
            var _local_6:Number;
            var _local_4:Number = (_arg_2 / _arg_1.width);
            var _local_5:Number = (_arg_3 / _arg_1.height);
            if (_local_4 < _local_5) {
                _local_6 = _local_4;
            } else {
                _local_6 = _local_5;
            }
            if (_local_6 < 1) {
                _arg_1.width = (_arg_1.width * _local_6);
                _arg_1.height = (_arg_1.height * _local_6);
            }
        }


    }
}//package 

