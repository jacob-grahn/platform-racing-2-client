// data.GpNotification = data.class_17

package com.jiggmin.data
{
    import flash.display.DisplayObjectContainer;

    public class GpNotification 
    {

        private static var holder:DisplayObjectContainer;


        public static function init(d:DisplayObjectContainer)
        {
            holder = d;
            CommandHandler.commandHandler.defineCommand("gpGain", gpGain);
        }

        public static function gpGain(arr:Array)
        {
            var gp:int = int(arr[0]);
            var gpNotif:GpNotificationGraphic = new GpNotificationGraphic();
            gpNotif.anim.textBox.text = "+" + gp + " GP";
            gpNotif.x = 25;
            gpNotif.y = 25;
            holder.addChild(gpNotif);
        }


    }
}
