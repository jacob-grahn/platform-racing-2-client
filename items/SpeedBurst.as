// items.SpeedBurst

package items
{
    import package_8.LocalCharacter;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;

    public class SpeedBurst extends Item 
    {

        private var expireListener:uint; // var_511
        private var used:Boolean = false; // var_522
        public var duration:Number = 5000; // var_335

        public function SpeedBurst(lc:LocalCharacter)
        {
            super(lc);
        }

        override public function useItem()
        {
            if (!this.used) {
                this.used = true;
                this.expireListener = setTimeout(this.slowDown, this.duration);
                character.accel = character.accel * 2;
                character.maxVelX = character.maxVelX * 2;
                character.beginSparkles(this.duration);
            }
        }

        public function isUsed()
        {
            return this.used;
        }

        // method_699 = slowDown
        private function slowDown()
        {
            character.setItem(0);
        }

        override public function remove()
        {
            character.endSparkles(this.used);
            character.resetStats();
            clearTimeout(this.expireListener);
            super.remove();
        }


    }
}
