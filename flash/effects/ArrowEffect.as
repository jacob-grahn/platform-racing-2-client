package effects
{
    import flash.events.Event;

    public class ArrowEffect extends Effect
    {

        private var m:Arrow2Graphic = new Arrow2Graphic();
        private var velY:int = 0;

        public function ArrowEffect(startX:Number, startY:Number)
        {
            x = startX;
            y = startY;
            scaleX = (scaleY = 0.25);
            addChild(this.m);
            scheduleRemove(15);
            addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
        }

        private function onEnterFrame(e:Event)
        {
            this.velY = (this.velY - 0.1);
            y = (y - this.velY);
            alpha = (alpha - 0.06);
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
            this.m = null;
            super.remove();
        }


    }
}//package effects
