// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_4.class_264

package package_4
{
    import flash.utils.setTimeout;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.utils.clearTimeout;

    public class class_264 extends InfoPopup 
    {

        private var initTimeout:uint = setTimeout(init, 25);

        public function class_264(d:DisplayObject)
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
