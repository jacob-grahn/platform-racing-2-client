// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.UnreadNotif = data.class_32

package data
{
    import flash.display.DisplayObjectContainer;

    public class UnreadNotif  
    {

        private static var var_192:Number = 0;
        private static var var_212:Array = new Array();
        private static var m:UnreadNotifGraphic = new UnreadNotifGraphic(); // m = var_186
        private static var d:DisplayObjectContainer;


        // method_745 = setLastRead
        public static function setLastRead(time:Number)
        {
            var_192 = time;
        }

        // method_272 = setLastRecv
        public static function setLastRecv(time:Number)
        {
            if (time > var_192) {
                var_212.push(time);
            }
            method_127();
        }

        public static function method_692()
        {
            for each (var _local_1:Number in var_212) {
                if (_local_1 > var_192) {
                    var_192 = _local_1;
                }
            }
            var_212 = new Array();
            remove();
        }

        public static function method_524(_arg_1:DisplayObjectContainer)
        {
            UnreadNotif.d = _arg_1;
            if (method_597 > 0) {
                method_127();
            }
        }

        public static function method_127()
        {
            if (d != null) {
                m.x = 26;
                m.y = 0;
                d.addChild(m);
            }
        }

        // method_147 = remove
        public static function remove()
        {
            if (m.parent != null) {
                m.parent.removeChild(m);
            }
        }

        public static function get method_597():int
        {
            return var_212.length;
        }


    }
}//package data

