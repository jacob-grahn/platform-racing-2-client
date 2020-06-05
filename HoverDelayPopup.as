// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//HoverDelayPopup = class_213

package 
{
    import flash.display.Sprite;
    import package_4.HoverPopup;
    import flash.events.MouseEvent;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;

    public class HoverDelayPopup extends Sprite 
    {

        private var title:String;
        private var content:String;
        private var time:int = 500;
        //protected var var_559:Boolean = true; // unused
        private var delayTimer:uint; // var_292
        private var hover:HoverPopup; // var_8

        public function HoverDelayPopup(title:String="", message:String="", delay:int=500)
        {
            this.title = title;
            this.content = message;
            this.time = delay;
            addEventListener(MouseEvent.MOUSE_OVER, this.overHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.outHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_DOWN, this.downHandler, false, 0, true);
        }

        protected function overHandler(e:MouseEvent)
        {
            clearTimeout(this.delayTimer);
            this.delayTimer = setTimeout(this.showPopup, this.time);
            this.hidePopupIfShown();
        }

        protected function outHandler(e:MouseEvent)
        {
            clearTimeout(this.delayTimer);
            this.hidePopupIfShown();
        }

        protected function downHandler(e:MouseEvent)
        {
            clearTimeout(this.delayTimer);
            this.hidePopupIfShown();
        }

        // method_655 = showPopup
        private function showPopup()
        {
            this.hidePopupIfShown();
            // if (this.var_559 == true) {
            this.hover = new HoverPopup(this.title, this.content, this);
            // }
        }

        // method_69 = hidePopupIfShown
        private function hidePopupIfShown()
        {
            if (this.hover != null) {
                this.hover.remove();
            }
        }

        // unused
        /*public function method_835(_arg_1:Boolean)
        {
            this.var_559 = _arg_1;
        }*/

        public function remove()
        {
            clearTimeout(this.delayTimer);
            removeEventListener(MouseEvent.MOUSE_OVER, this.overHandler);
            removeEventListener(MouseEvent.MOUSE_OUT, this.outHandler);
            removeEventListener(MouseEvent.MOUSE_DOWN, this.downHandler);
            this.hidePopupIfShown();
            if (this.parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package 

