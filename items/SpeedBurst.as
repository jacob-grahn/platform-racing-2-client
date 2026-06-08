// items.SpeedBurst

package items
{
    import character.LocalCharacter;
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
                this.localChar.accel = this.localChar.accel * 2;
                this.localChar.maxVelX = this.localChar.maxVelX * 2;
                this.localChar.beginSparkles(this.duration);
            }
        }

        public function isUsed()
        {
            return this.used;
        }

        private function slowDown()
        {
            this.localChar.setItem(0);
        }

        override public function remove()
        {
            this.localChar.endSparkles(this.used);
            this.localChar.resetStats();
            clearTimeout(this.expireListener);
            super.remove();
        }


    }
}
