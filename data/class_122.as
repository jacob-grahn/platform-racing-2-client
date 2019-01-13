// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//data.class_122

package data
{
    public class class_122 
    {


        public static function method_587(_arg_1:Number, _arg_2:Number, _arg_3:Number):Object
        {
            var _local_4:Number;
            var _local_5:Number;
            var _local_6:Number;
            _arg_1 = (_arg_1 % 360);
            if (_arg_3 == 0) {
                return ({
                    "red":0,
                    "green":0,
                    "blue":0
                });
            }
            _arg_2 = (_arg_2 / 100);
            _arg_3 = (_arg_3 / 100);
            _arg_1 = (_arg_1 / 60);
            var _local_7:Number = Math.floor(_arg_1);
            var _local_8:Number = (_arg_1 - _local_7);
            var _local_9:Number = (_arg_3 * (1 - _arg_2));
            var _local_10:Number = (_arg_3 * (1 - (_arg_2 * _local_8)));
            var _local_11:Number = (_arg_3 * (1 - (_arg_2 * (1 - _local_8))));
            switch (_local_7) {
                case 0:
                    _local_4 = _arg_3;
                    _local_5 = _local_11;
                    _local_6 = _local_9;
                    break;
                case 1:
                    _local_4 = _local_10;
                    _local_5 = _arg_3;
                    _local_6 = _local_9;
                    break;
                case 2:
                    _local_4 = _local_9;
                    _local_5 = _arg_3;
                    _local_6 = _local_11;
                    break;
                case 3:
                    _local_4 = _local_9;
                    _local_5 = _local_10;
                    _local_6 = _arg_3;
                    break;
                case 4:
                    _local_4 = _local_11;
                    _local_5 = _local_9;
                    _local_6 = _arg_3;
                    break;
                case 5:
                    _local_4 = _arg_3;
                    _local_5 = _local_9;
                    _local_6 = _local_10;
                    break;
            }
            _local_4 = Math.round((_local_4 * 0xFF));
            _local_5 = Math.round((_local_5 * 0xFF));
            _local_6 = Math.round((_local_6 * 0xFF));
            return ({
                "red":_local_4,
                "green":_local_5,
                "blue":_local_6
            });
        }

        public static function method_739(_arg_1:Number, _arg_2:Number, _arg_3:Number):Object
        {
            var _local_8:Number;
            var _local_4:Number = Math.min(Math.min(_arg_1, _arg_2), _arg_3);
            var _local_5:Number = Math.max(Math.max(_arg_1, _arg_2), _arg_3);
            var _local_6:Number = (_local_5 - _local_4);
            var _local_7:Number = ((_local_5 == 0) ? 0 : (_local_6 / _local_5));
            if (_local_7 == 0) {
                _local_8 = 0;
            } else {
                if (_arg_1 == _local_5) {
                    _local_8 = ((60 * (_arg_2 - _arg_3)) / _local_6);
                } else {
                    if (_arg_2 == _local_5) {
                        _local_8 = (120 + ((60 * (_arg_3 - _arg_1)) / _local_6));
                    } else {
                        _local_8 = (240 + ((60 * (_arg_1 - _arg_2)) / _local_6));
                    }
                }
                if (_local_8 < 0) {
                    _local_8 = (_local_8 + 360);
                }
            }
            _local_7 = (_local_7 * 100);
            _local_5 = ((_local_5 / 0xFF) * 100);
            return ({
                "hue":_local_8,
                "saturation":_local_7,
                "brightness":_local_5
            });
        }

        public static function method_265(_arg_1:Number, _arg_2:Number, _arg_3:Number):Number
        {
            return (((_arg_1 << 16) | (_arg_2 << 8)) | _arg_3);
        }

        public static function hex24torgb(_arg_1:Number):Object
        {
            var _local_2:Number = ((_arg_1 >> 16) & 0xFF);
            var _local_3:Number = ((_arg_1 >> 8) & 0xFF);
            var _local_4:Number = (_arg_1 & 0xFF);
            return ({
                "red":_local_2,
                "green":_local_3,
                "blue":_local_4
            });
        }

        public static function method_840(_arg_1:Number, _arg_2:Number, _arg_3:Number, _arg_4:Number):Number
        {
            return ((((_arg_4 << 24) | (_arg_1 << 16)) | (_arg_2 << 8)) | _arg_3);
        }

        public static function hex32toargb(_arg_1:Number):Object
        {
            var _local_2:Number = ((_arg_1 >> 24) & 0xFF);
            var _local_3:Number = ((_arg_1 >> 16) & 0xFF);
            var _local_4:Number = ((_arg_1 >> 8) & 0xFF);
            var _local_5:Number = (_arg_1 & 0xFF);
            return ({
                "alpha":_local_2,
                "red":_local_3,
                "green":_local_4,
                "blue":_local_5
            });
        }

        public static function hex24tohsb(_arg_1:Number):Object
        {
            var _local_2:Object = class_122.hex24torgb(_arg_1);
            return (class_122.method_739(_local_2.red, _local_2.green, _local_2.blue));
        }

        public static function method_68(_arg_1:Number, _arg_2:Number, _arg_3:Number):Number
        {
            var _local_4:Object = class_122.method_587(_arg_1, _arg_2, _arg_3);
            return (class_122.method_265(_local_4.red, _local_4.green, _local_4.blue));
        }

        public static function method_712(_arg_1:Number):String
        {
            var _local_2:String = ("0x" + _arg_1.toString(16).toUpperCase());
            while (_local_2.length < 8) {
                _local_2 = (_local_2 + "0");
            }
            return (_local_2);
        }


    }
}//package data

