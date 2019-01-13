// package_22.CourseMenu = package_22.class_312

package package_22
{
    import package_4.class_264;
    import flash.events.MouseEvent;
    import data.CommandHandler;
    import flash.utils.setTimeout;
    import flash.utils.clearInterval;
    import flash.utils.clearTimeout;
    import flash.utils.setInterval;

    public class CourseMenu extends class_264 
    {

        private var m:CourseMenuGraphic = new CourseMenuGraphic();
        private var slot:Slot; // var_384
        private var secondInterval:uint; // var_361
        private var waitTimeout:uint;
        private var confirmed:Boolean = false; // var_515
        private var timer:int;

        public function CourseMenu(s:Slot)
        {
            this.slot = s;
            this.m.play_bt.validateNow();
            this.m.cancel_bt.validateNow();
            this.m.play_bt.addEventListener(MouseEvent.CLICK, this.clickPlay, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.closeMenu, false, 0, true);
            addChild(this.m);
            CommandHandler.commandHandler.defineCommand("forceTime", this.forceTime);
            CommandHandler.commandHandler.defineCommand("closeCourseMenu", this.remoteRemove);
            this.waitTimeout = setTimeout(this.closeMenu, 30000);
            super(this.slot); // if this doesn't work, use s
        }

        // method_675 = forceTime
        public function forceTime(a:Array)
        {
            var _local_2:int = int(a[0]);
            clearInterval(this.secondInterval);
            clearTimeout(this.waitTimeout);
            if (_local_2 < 0) {
                this.m.textBox.text = "--";
                this.waitTimeout = setTimeout(this.closeMenu, 30000);
            } else {
                this.timer = (15 - _local_2) + 1;
                this.secondInterval = setInterval(this.decrementTimer, 1000);
                this.decrementTimer();
            }
        }

        // method_285 = decrementTimer
        private function decrementTimer()
        {
            this.timer--;
            if (this.timer < 0) {
                this.timer = 0;
                clearInterval(this.secondInterval);
                Main.socket.write("force_start`");
            }
            this.m.textBox.text = this.timer.toString();
        }

        // method_303 = clickPlay
        private function clickPlay(e:MouseEvent)
        {
            this.confirmed = true;
            clearTimeout(this.waitTimeout);
            this.slot.sendConfirmSlot();
        }

        // depreciated; use closeMenu
        /*private function clickCancel(e:MouseEvent)
        {
            this.method_157();
        }*/

        public function remoteRemove(a:Array)
        {
            this.remove();
        }

        // method_157 = closeMenu
        private function closeMenu(e:* = null)
        {
            this.confirmed = false;
            this.remove();
        }

        override public function remove()
        {
            CommandHandler.commandHandler.defineCommand("forceTime", null);
            CommandHandler.commandHandler.defineCommand("closeCourseMenu", null);
            this.m.play_bt.removeEventListener(MouseEvent.CLICK, this.clickPlay);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.closeMenu);
            clearInterval(this.secondInterval);
            clearTimeout(this.waitTimeout);
            this.slot.sendClearSlot();
            this.slot = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
