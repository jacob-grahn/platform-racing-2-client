// data.UnreadNotif = data.class_32

package com.jiggmin.data
{
    import flash.display.DisplayObjectContainer;

    public class UnreadNotif  
    {

        private static var lastReadTime:Number = 0;
        private static var unreadMessages:Array = new Array();
        private static var notificationIcon:UnreadNotifGraphic = new UnreadNotifGraphic();
        private static var pmTab:DisplayObjectContainer;


        public static function setLastRead(time:Number)
        {
            lastReadTime = time;
        }

        public static function notifyUser(time:Number)
        {
            if (time > lastReadTime) {
                unreadMessages.push(time);
            }
            addNotif();
        }

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

        public static function addNotifContainer(d:DisplayObjectContainer)
        {
            UnreadNotif.pmTab = d;
            if (numUnread > 0) {
                addNotif();
            }
        }

        private static function addNotif()
        {
            if (pmTab != null) {
                notificationIcon.x = 26;
                notificationIcon.y = 0;
                pmTab.addChild(notificationIcon);
            }
        }

        private static function removeNotif()
        {
            if (notificationIcon.parent != null) {
                notificationIcon.parent.removeChild(notificationIcon);
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
