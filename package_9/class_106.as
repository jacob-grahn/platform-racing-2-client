// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_106

package package_9
{
    import flash.events.Event;
    import flash.display.DisplayObject;

    public class class_106 extends Effect 
    {

        private var velX:Number;
        private var velY:Number;
        private var var_372:Number;
        private var gravity:Number;
        private var friction:Number;
        private var name_3:Number;

        public function class_106(_arg_1:DisplayObject, _arg_2:Number=1, _arg_3:Number=0.95, _arg_4:Number=0.01, _arg_5:Number=10, _arg_6:Number=10, _arg_7:Number=10, _arg_8:Number=0, _arg_9:Number=0)
        {
            addChild(_arg_1);
            x = _arg_8;
            y = _arg_9;
            this.gravity = _arg_2;
            this.friction = _arg_3;
            this.name_3 = _arg_4;
            rotation = (Math.random() * 360);
            this.velX = ((Math.random() * (_arg_5 * 2)) - _arg_5);
            this.velY = ((Math.random() * (_arg_6 * 2)) - _arg_6);
            this.var_372 = ((Math.random() * (_arg_7 * 2)) - _arg_7);
            addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
        }

        private function go(_arg_1:Event)
        {
            this.velX = (this.velX * this.friction);
            this.velY = (this.velY * this.friction);
            this.var_372 = (this.var_372 * this.friction);
            this.velY = (this.velY + this.gravity);
            x = (x + this.velX);
            y = (y + this.velY);
            rotation = (rotation + this.var_372);
            alpha = (alpha - this.name_3);
            if (alpha <= 0) {
                this.remove();
            }
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            super.remove();
        }


    }
}//package package_9

