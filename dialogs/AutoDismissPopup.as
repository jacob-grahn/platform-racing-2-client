//dialogs.AutoDismissPopup

package dialogs
{
    import flash.utils.setTimeout;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.utils.clearTimeout;

    public class AutoDismissPopup extends InfoPopup 
    {

        private var initTimeout:uint = setTimeout(init, 25);

        public function AutoDismissPopup(d:DisplayObject)
        {
            super(d);
        }

        private function init()
        {
            Main.stage.addEventListener(MouseEvent.MOUSE_DOWN, this.downHandler);
        }

        protected function downHandler(e:MouseEvent)
        {
            if (!this.hitTestPoint(e.stageX, e.stageY, true)) {
                this.remove();
            }
        }

        override public function remove()
        {
            clearTimeout(this.initTimeout);
            Main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.downHandler);
            super.remove();
        }


    }
}
