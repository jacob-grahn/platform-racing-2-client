// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//data.Settings

package data
{
    import flash.net.SharedObject;

    public class Settings 
    {

        private static var userName:String;
        private static var var_179:Object = new Object();
        public static const filterSwears:String = "useSwearFilter";


        public static function init(s:String = "")
        {
            Settings.userName = "pr2_" + s.replace(/\W+/g, "");
            Settings.var_179 = new Object();
            var _local_2:SharedObject = SharedObject.getLocal(Settings.userName);
            for (var _local_3:String in _local_2.data) {
                Settings.var_179[_local_3] = _local_2.data[_local_3];
            }
        }

        public static function method_390(_arg_1:String, _arg_2:*)
        {
            if (var_179[_arg_1] != _arg_2) {
                var_179[_arg_1] = _arg_2;
                var _local_3:SharedObject = SharedObject.getLocal(Settings.userName);
                _local_3.data[_arg_1] = _arg_2;
                _local_3.flush();
            }
        }

        public static function method_135(_arg_1:String, _arg_2:*=null):*
        {
            var _local_3:* = var_179[_arg_1];
            if (_local_3 == null) {
                var_179[_arg_1] = _arg_2;
                _local_3 = _arg_2;
            }
            return (_local_3);
        }


    }
}//package data

