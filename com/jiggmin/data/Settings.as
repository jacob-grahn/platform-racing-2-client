// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//data.Settings

package com.jiggmin.data
{
    import flash.display.MovieClip;
    import flash.errors.Error;
    import flash.net.SharedObject;

    public class Settings 
    {

        public static const PRESETS:String = "presets";
        public static const DISABLED_SONGS:String = "disabledSongs";
        public static const MUSIC_VOLUME:String = "musicLevel";
        public static const SOUND_VOLUME:String = "soundLevel";
        public static const DRAW_ART:String = "drawArt";
        public static const ART_LOSSLESS_QUALITY:String = 'losslessQuality';
        public static const FILTER_SWEARS:String = "filterSwears";
        public static const ALTERNATE_CONTROLS:String = "altCtrl";
        public static const LE_TEST_STATS:String = 'leTestStats';
        public static const LE_TEST_HAT:String = 'leTestHat';

        public static const DEFAULT_ALT_CONTROLS:Object = {"up":87,"right":68,"down":83,"left":65,"item":73};
        public static const DEFAULT_LE_TEST_STATS:Object = {"speed":50,"acceleration":50,"jumping":50};

        private static const SETTINGS:Array = [PRESETS, DISABLED_SONGS, MUSIC_VOLUME, SOUND_VOLUME, DRAW_ART, ART_LOSSLESS_QUALITY, FILTER_SWEARS, ALTERNATE_CONTROLS, LE_TEST_STATS, LE_TEST_HAT];

        private static var presets:Object = null;
        public static var disabledSongs:Array = [];
        public static var musicLevel:int = 100;
        public static var soundLevel:int = 100;
        private static var drawArt:Boolean = true;
        private static var losslessQuality:Boolean = false;
        private static var filterSwears:Boolean = true;
        private static var altCtrl:Object = {"up":87,"right":68,"down":83,"left":65,"item":73};
        private static var leTestStats:Object = {"speed":50,"acceleration":50,"jumping":50};
        private static var leTestHat:int = 2;

        private static var userName:String;
        private static var dataArr:Object;

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

        public static function clear()
        {
            userName = null;
            dataArr = null;
        }

        private static function handleControls(obj:Object)
        {
            if (!canSaveCookie()) {
                return; // don't set if not logged in or the user is blocking cookies
            }
            var cookie:SharedObject = SharedObject.getLocal(userName);
            cookie.data.altCtrl = cookie.data.altCtrl == null ? DEFAULT_ALT_CONTROLS : cookie.data.altCtrl;
            for (var prop:String in obj) {
                cookie.data.altCtrl[prop] = altCtrl[prop] = dataArr.altCtrl[prop] = obj[prop];
            }
            cookie.flush();
        }

        private static function handleStats(obj:Object)
        {
            if (!canSaveCookie()) {
                return; // don't set if not logged in or the user is blocking cookies
            }
            var cookie:SharedObject = SharedObject.getLocal(userName);
            cookie.data.leTestStats = cookie.data.leTestStats == null ? DEFAULT_LE_TEST_STATS : cookie.data.leTestStats;
            for (var prop:String in obj) {
                cookie.data.leTestStats[prop] = leTestStats[prop] = dataArr.leTestStats[prop] = obj[prop];
            }
            cookie.flush();
        }

        public static function isNameSet() : Boolean
        {
            return userName != null;
        }

        private static function canSaveCookie() : Boolean
        {
            try {
                var cookie:SharedObject = SharedObject.getLocal(userName);
                cookie.flush();
            } catch (e:Error) {
                return false;
            }
            return isNameSet();
        }

        public static function setValue(setting:String, val:*)
        {
            if (setting == ALTERNATE_CONTROLS) {
                handleControls(val);
            } else if (setting == LE_TEST_STATS) {
                handleStats(val);
            } else if (dataArr[setting] != val || Settings[setting] != val) {
                Settings[setting] = dataArr[setting] = val;
                if (canSaveCookie()) { // only set if logged in and able to save cookies
                    var cookie:SharedObject = SharedObject.getLocal(userName);
                    cookie.data[setting] = val;
                    cookie.flush();
                }
            }
        }

        // deleted _loc3 (unneeded)
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
}//package com.jiggmin.data

