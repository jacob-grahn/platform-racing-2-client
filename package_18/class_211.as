// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_18.class_211

package package_18
{
    import data.Settings;
    import package_8.Character;
    import ui.StatsSelect;

    public class class_211 
    {

        private static var presets:Vector.<class_263>;


        public static function load()
        {
            var _local_3:Object;
            var _local_4:class_263;
            presets = new Vector.<class_263>();
            var _local_1:Array = [{"num":1}, {"num":2}, {"num":3}];
            var _local_2:Array = (Settings.method_135("presets", _local_1) as Array);
            for each (_local_3 in _local_2) {
                _local_4 = new class_263(_local_3);
                presets[(_local_4.num - 1)] = _local_4;
            }
        }

        public static function method_533()
        {
            var _local_2:class_263;
            var _local_3:Object;
            var _local_1:Array = new Array();
            for each (_local_2 in presets) {
                _local_3 = _local_2.method_558();
                _local_1[(_local_3.num - 1)] = _local_3;
            }
            Settings.method_390("presets", _local_1);
        }

        public static function method_766():Vector.<class_263>
        {
            return (presets);
        }

        public static function method_513(_arg_1:int):class_263
        {
            return (presets[(_arg_1 - 1)]);
        }

        public static function apply(_arg_1:class_263, c:Character, ss:StatsSelect, _arg_4:class_262)
        {
            if (ss != null) {
                ss.setStats({
                    "speed":1,
                    "acceleration":1,
                    "jumping":1
                });
                ss.setStats(_arg_1);
            }
            if (c != null) {
                c.method_395(_arg_1.hat);
                c.method_250(_arg_1.head);
                c.method_217(_arg_1.body);
                c.method_326(_arg_1.feet);
                c.setColors(_arg_1.hatColor, _arg_1.hatColor2, _arg_1.headColor, _arg_1.headColor2, _arg_1.bodyColor, _arg_1.bodyColor2, _arg_1.feetColor, _arg_1.feetColor2);
            }
            if (_arg_4 != null) {
                _arg_4.var_130.setValue(_arg_1.hat);
                _arg_4.var_119.setValue(_arg_1.head);
                _arg_4.var_113.setValue(_arg_1.body);
                _arg_4.var_129.setValue(_arg_1.feet);
                _arg_4.var_130.setColors(_arg_1.hatColor, _arg_1.hatColor2);
                _arg_4.var_119.setColors(_arg_1.headColor, _arg_1.headColor2);
                _arg_4.var_113.setColors(_arg_1.bodyColor, _arg_1.bodyColor2);
                _arg_4.var_129.setColors(_arg_1.feetColor, _arg_1.feetColor2);
            }
        }


    }
}//package package_18

