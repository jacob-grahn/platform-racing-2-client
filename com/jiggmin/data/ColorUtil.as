//data.ColorUtil

package com.jiggmin.data
{
    public class ColorUtil 
    {


        // _loc4 = red
        // _loc5 = green
        // _loc6 = blue
        public static function hsbToRGB(hue:Number, saturation:Number, brightness:Number):Object
        {
            var red:Number;
            var green:Number;
            var blue:Number;
            hue = hue % 360;
            if (brightness == 0) {
                return {
                    red: 0,
                    green: 0,
                    blue: 0
                };
            }
            saturation /= 100;
            brightness /= 100;
            hue /= 60;

            var _local_7:Number = Math.floor(hue);
            var _local_8:Number = hue - _local_7;
            var _local_9:Number = brightness * (1 - saturation);
            var _local_10:Number = brightness * (1 - (saturation * _local_8));
            var _local_11:Number = brightness * (1 - (saturation * (1 - _local_8)));

            switch (_local_7) {
                case 0:
                    red = brightness;
                    green = _local_11;
                    blue = _local_9;
                    break;
                case 1:
                    red = _local_10;
                    green = brightness;
                    blue = _local_9;
                    break;
                case 2:
                    red = _local_9;
                    green = brightness;
                    blue = _local_11;
                    break;
                case 3:
                    red = _local_9;
                    green = _local_10;
                    blue = brightness;
                    break;
                case 4:
                    red = _local_11;
                    green = _local_9;
                    blue = brightness;
                    break;
                case 5:
                    red = brightness;
                    green = _local_9;
                    blue = _local_10;
                    break;
            }

            return ({
                "red": Math.round(red * 0xFF),
                "green": Math.round(green * 0xFF),
                "blue": Math.round(blue * 0xFF)
            });
        }

        public static function rgbToHSB(_arg_1:Number, _arg_2:Number, _arg_3:Number):Object
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

        public static function rgbToHex24(r:int, g:int, b:int):uint
        {
            return r << 16 | g << 8 | b;
        }

        public static function hex24ToRGB(hex:Number):Object
        {
            return {
                red: hex >> 16 & 0xFF,
                green: hex >> 8 & 0xFF,
                blue: hex & 0xFF
            };
        }

        public static function argbToHex32(r:int, g:int, b:int, a:int):uint
        {
            return a << 24 | r << 16 | g << 8 | b;
        }

        public static function hex32ToARGB(hex:Number):Object
        {
            return {
                alpha: hex >> 24 & 0xFF,
                red: hex >> 16 & 0xFF,
                green: hex >> 8 & 0xFF,
                blue: hex & 0xFF
            };
        }

        // _loc2 = rgb
        public static function hex24ToHSB(_arg_1:Number):Object
        {
            var rgb:Object = hex24ToRGB(_arg_1);
            return rgbToHSB(rgb.red, rgb.green, rgb.blue);
        }

        public static function hsbToHex24(_arg_1:Number, _arg_2:Number, _arg_3:Number):Number
        {
            var _local_4:Object = ColorUtil.hsbToRGB(_arg_1, _arg_2, _arg_3);
            return ColorUtil.rgbToHex24(_local_4.red, _local_4.green, _local_4.blue);
        }

        // _loc2 = hex
        public static function decimalToHex(num:Number):String
        {
            var hex:String = num.toString(16).toUpperCase();
            while (hex.length < 6) {
                hex = "0" + hex;
            }
            return '0x' + hex;
        }

    }
}//package com.jiggmin.data

