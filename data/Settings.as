// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//data.Settings

package data
{
    import flash.display.MovieClip;
    import flash.errors.Error;
    import flash.net.SharedObject;

    public class Settings 
    {

        public static const MUSIC_VOLUME:String = "musicLevel";
        public static const SOUND_VOLUME:String = "soundLevel";
        public static const DRAW_ART:String = "drawArt";
        public static const FILTER_SWEARS:String = "filterSwears";
        public static const ALTERNATE_CONTROLS:String = "altCtrl";
        public static const DEFAULT_ALT_CONTROLS:Object = {"up":87,"right":68,"down":83,"left":65,"item":73};

        private static const SETTINGS:Array = [MUSIC_VOLUME, SOUND_VOLUME, DRAW_ART, FILTER_SWEARS, ALTERNATE_CONTROLS];

        public static var musicLevel:int = 100;
        public static var soundLevel:int = 100;
        private static var drawArt:Boolean = true;
        private static var filterSwears:Boolean = true;
        private static var altCtrl:Object = {"up":87,"right":68,"down":83,"left":65,"item":73};

        private static var userName:String;
        private static var dataArr:Object = new Object(); // var_179

        // _loc2 = cookie
        // _loc3 = setting
        public static function init(s:String = "")
        {
            userName = "pr2_" + s.replace(/\W+/g, "");
            dataArr = new Object();
            var cookie:SharedObject = SharedObject.getLocal(userName);
            for (var setting:String in cookie.data) {
                Settings[setting] = dataArr[setting] = cookie.data[setting]; // get settings from cookie
            }
            for (var i:String in SETTINGS) {
                if (dataArr[i] == null && Settings[i] != null) {
                    dataArr[i] = Settings[i]; // if the setting wasn't found in a cookie, set it from recent or default setting
                }
            }
        }

        private static function handleControls(obj:Object)
        {
            var cookie:SharedObject = SharedObject.getLocal(userName);
            if (cookie.data.altCtrl == null) {
                cookie.data.altCtrl = DEFAULT_ALT_CONTROLS;
            }
            for (var prop:String in obj) {
                cookie.data.altCtrl[prop] = altCtrl[prop] = dataArr.altCtrl[prop] = obj[prop];
            }
            cookie.flush();
        }

        // _loc3 = cookie
        // method_390 = setValue
        public static function setValue(setting:String, val:*)
        {
            if (setting == ALTERNATE_CONTROLS) {
                handleControls(val);
            } else if (dataArr[setting] != val || Settings[setting] != val) {
                Settings[setting] = dataArr[setting] = val;
                var cookie:SharedObject = SharedObject.getLocal(userName);
                cookie.data[setting] = val;
                cookie.flush();
            }
        }

        // deleted _loc3 (unneeded)
        // method_135 = getValue
        public static function getValue(setting:String, val:* = null)
        {
            if (dataArr[setting] == null || Settings[setting] == null) {
                if (dataArr[setting] == null && Settings[setting] != null) {
                    dataArr[setting] = Settings[setting];
                } else if (Settings[setting] == null && dataArr[setting] != null) {
                    Settings[setting] = dataArr[setting];
                }
            }
            if (dataArr[setting] == null) {
                Settings[setting] = dataArr[setting] = val; // if still null, set to passed value
            }
            return dataArr[setting];
        }


    }
}//package data

