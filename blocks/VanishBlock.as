//blocks.VanishBlock = blocks.class_62

package blocks
{
    import com.jiggmin.data.Objects;
    import character.LocalCharacter;
    import flash.geom.Point;
    import flash.events.Event;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;

    public class VanishBlock extends Block 
    {

        private var reappearTimeout:uint;

        public function VanishBlock()
        {
            super(Objects.BLOCK_VANISH);
            safeStand = false;
        }

        override public function onStand(player:LocalCharacter)
        {
            super.onStand(player);
            this.activate();
        }

        override public function onBump(player:LocalCharacter)
        {
            super.onBump(player);
            this.activate();
        }

        override public function onLeftHit(player:LocalCharacter)
        {
            super.onLeftHit(player);
            this.activate();
        }

        override public function onRightHit(player:LocalCharacter)
        {
            super.onRightHit(player);
            this.activate();
        }

        override public function onDamage(_arg_1:Number)
        {
            super.onDamage(_arg_1);
            this.activate();
        }

        private function tryReappear()
        {
            var _local_1:Point = getSeg();
            if (!map.characterOccupiesSpace(_local_1.x, _local_1.y)) {
                alpha = 0.2;
                this.clear();
                addEventListener(Event.ENTER_FRAME, this.fadeIn, false, 0, true);
                active = true;
            } else {
                active = false;
                this.activate();
            }
        }

        private function fadeOut(_arg_1:Event)
        {
            alpha = (alpha - 0.1);
            if (alpha <= 0) {
                alpha = 0;
                active = false;
                this.clear();
                this.reappearTimeout = setTimeout(this.tryReappear, 2000);
            }
        }

        private function fadeIn(_arg_1:Event)
        {
            alpha = (alpha + 0.1);
            if (alpha >= 1) {
                alpha = 1;
                this.clear();
            }
        }

        override protected function activate(_arg_1:String="")
        {
            if (!frozen) {
                this.clear();
                addEventListener(Event.ENTER_FRAME, this.fadeOut, false, 0, true);
            }
        }

        private function clear()
        {
            removeEventListener(Event.ENTER_FRAME, this.fadeOut);
            removeEventListener(Event.ENTER_FRAME, this.fadeIn);
            clearTimeout(this.reappearTimeout);
        }

        override public function remove()
        {
            this.clear();
            super.remove();
        }


    }
}//package blocks
