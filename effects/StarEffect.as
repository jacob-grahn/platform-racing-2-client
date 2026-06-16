package effects
{
    public class StarEffect extends Effect
    {

        private var m:PointyStar = new PointyStar();

        public function StarEffect(startX:Number, startY:Number)
        {
            x = startX;
            y = startY;
            addChild(this.m);
            scheduleRemove(15);
        }

        override public function remove()
        {
            this.m = null;
            super.remove();
        }


    }
}//package effects
