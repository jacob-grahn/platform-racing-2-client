// com.jiggmin.ColorPicker.ColorChoices = package_16.class_280

package com.jiggmin.ColorPicker
{
    import com.jiggmin.data.ColorUtil;

    public class ColorChoices
    {


        public static function populate():Array
        {
            var colors:Array = makeColorArray(22, 12);

            var _local_6:int, _local_7:int;
            var red:int = 0;
            while (red <= 0xFF) {
                var blue:int = 0;
                for (var numB:int = 0; blue <= 0xFF; numB++) {
                    var green:int = 0;
                    for (var numG:int = 0; green <= 0xFF; numG++) {
                        var color:int = ColorUtil.rgbToHex24(red, green, blue);
                        var _local_11:int = (_local_6 * 6) + numG + 4;
                        var _local_12:int = (_local_7 * 6) + numB;
                        colors[_local_11][_local_12] = color;
                        green += 51;
                    }
                    blue += 51;
                }
                red += 51;
                if (++_local_6 > 2) {
                    _local_6 = 0;
                    _local_7++;
                }
                numG = numB = 0;
            }

            // get and populate recent colors
            for (var i:int = 0; i < 12; i++) {
                colors[0][i] = ColorPicker.recentColors[i];
            }

            // populate generic suggested colors
            colors[2][0] = 0;
            colors[2][1] = 0x333333;
            colors[2][2] = 0x666666;
            colors[2][3] = 0x999999;
            colors[2][4] = 0xCCCCCC;
            colors[2][5] = 0xFFFFFF;
            colors[2][6] = 0xFF0000;
            colors[2][7] = 0xFF00;
            colors[2][8] = 0xFF;
            colors[2][9] = 0xFFFF00;
            colors[2][10] = 0xFFFF;
            colors[2][11] = 0xFF00FF;
            return colors;
        }

        // changed public to private
        private static function makeColorArray(cols:int, rows:int):Array
        {
            var _local_3:Array = [];
            for (var i:int = 0; i < cols; i++) {
                var _local_5:Array = [];
                for (var j:int = 0; j < rows; j++) {
                    _local_5[j] = 0;
                }
                _local_3[i] = _local_5;
            }
            return _local_3;
        }


    }
}
