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
        protected var var_559:Boolean = true;
        private var var_292:uint;
        private var hover:HoverPopup; // var_8

        public function HoverDelayPopup(_arg_1:String="", _arg_2:String="", _arg_3:int=500)
        {
            this.title = _arg_1;
            this.content = _arg_2;
            this.time = _arg_3;
            addEventListener(MouseEvent.MOUSE_OVER, this.overHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.outHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_DOWN, this.downHandler, false, 0, true);
        }

        protected function overHandler(_arg_1:MouseEvent)
        {
            clearTimeout(this.var_292);
            this.var_292 = setTimeout(this.method_655, this.time);
            this.method_69();
        }

        protected function outHandler(_arg_1:MouseEvent)
        {
            clearTimeout(this.var_292);
            this.method_69();
        }

        protected function downHandler(_arg_1:MouseEvent)
        {
            clearTimeout(this.var_292);
            this.method_69();
        }

        private function method_655()
        {
            this.method_69();
            if (this.var_559 == true) {
                this.hover = new HoverPopup(this.title, this.content, this);
            }
        }

        private function method_69()
        {
            if (this.hover != null) {
                this.hover.remove();
            }
        }

        public function method_835(_arg_1:Boolean)
        {
            this.var_559 = _arg_1;
        }

        public function remove()
        {
            clearTimeout(this.var_292);
            removeEventListener(MouseEvent.MOUSE_OVER, this.overHandler);
            removeEventListener(MouseEvent.MOUSE_OUT, this.outHandler);
            removeEventListener(MouseEvent.MOUSE_DOWN, this.downHandler);
            this.method_69();
            if (this.parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package 

