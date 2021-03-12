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

        public function SpeedBurst(p:LocalCharacter)
        {
            super(p);
        }

        override public function useItem()
        {
            if (!this.used) {
                this.used = true;
                this.expireListener = setTimeout(this.slowDown, this.duration);
                player.accel = player.accel * 2;
                player.maxVelX = player.maxVelX * 2;
                player.beginSparkles(this.duration);
            }
        }

        public function isUsed()
        {
            return this.used;
        }

        // method_699 = slowDown
        private function slowDown()
        {
            player.setItem(0);
        }

        override public function remove()
        {
            player.endSparkles(this.used);
            player.resetStats();
            clearTimeout(this.expireListener);
            super.remove();
        }


    }
}
