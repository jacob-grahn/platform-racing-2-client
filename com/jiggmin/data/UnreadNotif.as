// data.UnreadNotif = data.class_32

package com.jiggmin.data
{
    import flash.display.DisplayObjectContainer;

    public class UnreadNotif  
    {

        private static var lastReadTime:Number = 0; // var_192
        private static var unreadMessages:Array = new Array(); // var_212
        private static var m:UnreadNotifGraphic = new UnreadNotifGraphic(); // m
        private static var pmTab:DisplayObjectContainer; // d


        // method_745 = setLastRead
        public static function setLastRead(time:Number)
        {
            lastReadTime = time;
        }

        // method_272 = notifyUser
        public static function notifyUser(time:Number)
        {
            if (time > lastReadTime) {
                unreadMessages.push(time);
            }
            addNotif();
        }

        // _loc1 = timeSent
        // method_692 = updateLastRead
        public static function updateLastRead()
        {
            for each (var timeSent:Number in unreadMessages) {
                if (timeSent > lastReadTime) {
                    lastReadTime = timeSent;
                }
            }
            unreadMessages = new Array();
            removeNotif();
        }

        // method_524 = addNotifContainer
        public static function addNotifContainer(d:DisplayObjectContainer)
        {
            UnreadNotif.pmTab = d;
            if (numUnread > 0) {
                addNotif();
            }
        }

        // method_127 = addNotif
        private static function addNotif()
        {
            if (pmTab != null) {
                m.x = 26;
                m.y = 0;
                pmTab.addChild(m);
            }
        }

        // method_147 = removeNotif
        private static function removeNotif()
        {
            if (m.parent != null) {
                m.parent.removeChild(m);
            }
        }

        public static function get numUnread():int
        {
            return unreadMessages.length;
        }


        public static function reset()
        {
            lastReadTime = 0;
            unreadMessages = [];
            removeNotif();
            pmTab = null;
        }


    }
}
