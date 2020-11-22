// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_18.class_211 = package_18.Presets

package package_18
{
    import data.Settings;
    import package_8.Character;
    import ui.StatsSelect;

    public class Presets 
    {
        private static const NUM_PRESETS:int = 5;

        private static var presets:Vector.<Preset>;


        // _loc2 = presets
        // _loc3 = presetData
        // _loc4 = preset
        public static function load()
        {
            presets = new Vector.<Preset>();
            var _local_1:Array = [{"num":1}, {"num":2}, {"num":3}, {'num':4}, {'num':5}];
            var presetsArray:Array = (Settings.getValue(Settings.PRESETS, _local_1) as Array);
            for each (var presetData:Object in presetsArray) {
                var preset:Preset = new Preset(presetData);
                presets[preset.num - 1] = preset;
            }
        }

        // _loc1 = presetsArray
        // _loc2 = preset
        // _loc3 = presetData
        // method_533 = savePresets
        public static function savePresets()
        {
            var presetsArray:Array = new Array();
            for each (var preset:Preset in presets) {
                var presetData:Object = preset.getPresetData();
                presetsArray[presetData.num - 1] = presetData;
            }
            Settings.setValue(Settings.PRESETS, presetsArray);
        }

        // method_766 = getPresets
        public static function getPresets():Vector.<Preset>
        {
            if (presets.length < Presets.NUM_PRESETS) {
                while (presets.length < Presets.NUM_PRESETS) {
                    var newPreset:Preset = new Preset({"num": (presets.length + 1)});
                    presets.push(newPreset);
                }
            }
            return presets;
        }

        // method_513 = getPreset
        public static function getPreset(i:int):Preset
        {
            return presets[i - 1];
        }

        public static function apply(_arg_1:Preset, c:Character, ss:StatsSelect, disp:CharacterDisplay)
        {
            if (ss != null) {
                ss.setStats({
                    "speed":1,
                    "acceleration":1,
                    "jumping":1
                });
                ss.setStats(_arg_1);
            }
            if (disp != null) {
                disp.hatSelect.setValue(_arg_1.hat);
                disp.headSelect.setValue(_arg_1.head);
                disp.bodySelect.setValue(_arg_1.body);
                disp.feetSelect.setValue(_arg_1.feet);
                disp.hatSelect.setColors(_arg_1.hatColor, _arg_1.hatColor2);
                disp.headSelect.setColors(_arg_1.headColor, _arg_1.headColor2);
                disp.bodySelect.setColors(_arg_1.bodyColor, _arg_1.bodyColor2);
                disp.feetSelect.setColors(_arg_1.feetColor, _arg_1.feetColor2);
            }
            if (c != null) {
                c.setHatId(_arg_1.hat);
                c.setHeadId(_arg_1.head);
                c.setBodyId(_arg_1.body);
                c.setFeetId(_arg_1.feet);
                c.setColors(_arg_1.hatColor, _arg_1.hatColor2, _arg_1.headColor, _arg_1.headColor2, _arg_1.bodyColor, _arg_1.bodyColor2, _arg_1.feetColor, _arg_1.feetColor2);
            }
        }


    }
}//package package_18

