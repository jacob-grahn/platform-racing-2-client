// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_18.class_211 = package_18.Presets

package package_18
{
    import com.jiggmin.data.Settings;
    import package_8.Character;
    import ui.StatsSelect;

    public class Presets 
    {
        public static const NUM_PRESETS:int = 10;

        private static var presets:Vector.<Preset>;


        // _loc2 = presets
        // _loc3 = presetData
        // _loc4 = preset
        public static function load()
        {
            presets = new Vector.<Preset>();
            var _local_1:Array = [{"num":1}, {"num":2}, {"num":3}, {'num':4}, {'num':5}, {'num':6}, {'num':7}, {'num':8}, {'num':9}, {'num':10}];
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

        public static function apply(preset:Preset, c:Character, ss:StatsSelect, disp:PlayerDisplay)
        {
            var hatColor2:int = preset.hatColor2;
            var headColor2:int = preset.headColor2;
            var bodyColor2:int = preset.bodyColor2;
            var feetColor2:int = preset.feetColor2;
            if (ss != null) {
                ss.setStats({
                    "speed":1,
                    "acceleration":1,
                    "jumping":1
                });
                ss.setStats(preset);
            }
            if (disp != null) {
                disp.hatSelect.setValue(preset.hat);
                disp.headSelect.setValue(preset.head);
                disp.bodySelect.setValue(preset.body);
                disp.feetSelect.setValue(preset.feet);
                disp.hatSelect.setColors(preset.hatColor, preset.hatColor2);
                disp.headSelect.setColors(preset.headColor, preset.headColor2);
                disp.bodySelect.setColors(preset.bodyColor, preset.bodyColor2);
                disp.feetSelect.setColors(preset.feetColor, preset.feetColor2);
                hatColor2 = disp.hatSelect.getColor2();
                headColor2 = disp.headSelect.getColor2();
                bodyColor2 = disp.bodySelect.getColor2();
                feetColor2 = disp.feetSelect.getColor2();
            }
            if (c != null) {
                c.setHatId(preset.hat);
                c.setHeadId(preset.head);
                c.setBodyId(preset.body);
                c.setFeetId(preset.feet);
                c.setColors(preset.hatColor, hatColor2, preset.headColor, headColor2, preset.bodyColor, bodyColor2, preset.feetColor, feetColor2);
            }
        }


    }
}//package package_18

