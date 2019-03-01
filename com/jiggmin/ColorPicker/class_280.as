// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// com.jiggmin.ColorPicker.class_280 = package_16.class_280

package com.jiggmin.ColorPicker
{
    import data.class_122;

    public class class_280
    {


        public static function method_605():Array
        {
            var _local_5:int;
            var _local_11:int;
            var _local_12:int;
            var _local_1:Array = method_258(22, 12);
            var _local_2:int;
            var _local_3:int;
            var _local_4:int;
            var _local_6:int;
            var _local_7:int;
            var _local_8:int;
            var _local_9:int;
            while (_local_2 <= 0xFF) {
                _local_4 = 0;
                _local_9 = 0;
                while (_local_4 <= 0xFF) {
                    _local_3 = 0;
                    _local_8 = 0;
                    while (_local_3 <= 0xFF) {
                        _local_5 = class_122.method_265(_local_2, _local_3, _local_4);
                        _local_11 = (_local_6 * 6) + _local_8 + 4;
                        _local_12 = (_local_7 * 6) + _local_9;
                        _local_1[_local_11][_local_12] = _local_5;
                        _local_8++;
                        _local_3 = _local_3 + 51;
                    }
                    _local_9++;
                    _local_4 = _local_4 + 51;
                }
                _local_2 = (_local_2 + 51);
                if (++_local_6 > 2) {
                    _local_6 = 0;
                    _local_7++;
                }
                _local_8 = _local_9 = 0;
            }
            var _local_10:int;
            while (_local_10 < 12) {
                _local_1[0][_local_10] = ColorPicker.var_265[_local_10];
                _local_10++;
            }
            _local_1[2][0] = 0;
            _local_1[2][1] = 0x333333;
            _local_1[2][2] = 0x666666;
            _local_1[2][3] = 0x999999;
            _local_1[2][4] = 0xCCCCCC;
            _local_1[2][5] = 0xFFFFFF;
            _local_1[2][6] = 0xFF0000;
            _local_1[2][7] = 0xFF00;
            _local_1[2][8] = 0xFF;
            _local_1[2][9] = 0xFFFF00;
            _local_1[2][10] = 0xFFFF;
            _local_1[2][11] = 0xFF00FF;
            return _local_1;
        }

        public static function method_258(_arg_1:int, _arg_2:int):Array
        {
            var _local_5:Array;
            var _local_6:int;
            var _local_3:Array = new Array();
            var _local_4:int;
            while (_local_4 < _arg_1) {
                _local_5 = new Array();
                _local_6 = 0;
                while (_local_6 < _arg_2) {
                    _local_5[_local_6] = 0;
                    _local_6++;
                }
                _local_3[_local_4] = _local_5;
                _local_4++;
            }
            return _local_3;
        }


    }
}
