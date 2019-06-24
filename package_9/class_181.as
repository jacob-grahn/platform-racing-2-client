// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_181

package package_9
{
    import flash.events.Event;

    public class class_181 extends Effect 
    {

        private var m:Arrow2Graphic = new Arrow2Graphic();
        private var velY:int = 0;

        public function class_181(_arg_1:Number, _arg_2:Number)
        {
            x = _arg_1;
            y = _arg_2;
            scaleX = (scaleY = 0.25);
            addChild(this.m);
            method_2(15);
            addEventListener(Event.ENTER_FRAME, this.method_152);
        }

        private function method_152(_arg_1:Event)
        {
            this.velY = (this.velY - 0.1);
            y = (y - this.velY);
            alpha = (alpha - 0.06);
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_152);
            this.m = null;
            super.remove();
        }


    }
}//package package_9

