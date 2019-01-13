// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//class_213

package 
{
    import flash.display.Sprite;
    import package_4.class_204;
    import flash.events.MouseEvent;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;

    public class class_213 extends Sprite 
    {

        private var title:String;
        private var content:String;
        protected var var_559:Boolean = true;
        private var var_292:uint;
        private var var_8:class_204;

        public function class_213(_arg_1:String="", _arg_2:String="")
        {
            this.title = _arg_1;
            this.content = _arg_2;
            addEventListener(MouseEvent.MOUSE_OVER, this.overHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.outHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_DOWN, this.downHandler, false, 0, true);
        }

        protected function overHandler(_arg_1:MouseEvent)
        {
            clearTimeout(this.var_292);
            this.var_292 = setTimeout(this.method_655, 500);
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
                this.var_8 = new class_204(this.title, this.content, this);
            }
        }

        private function method_69()
        {
            if (this.var_8 != null) {
                this.var_8.remove();
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

