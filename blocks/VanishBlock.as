// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.VanishBlock = blocks.class_62

package blocks
{
    import com.jiggmin.data.Objects;
    import package_8.LocalCharacter;
    import flash.geom.Point;
    import flash.events.Event;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;

    public class VanishBlock extends Block 
    {

        private var var_602:uint;

        public function VanishBlock()
        {
            super(Objects.VanishBlockCode);
            var_34 = false;
        }

        override public function onStand(_arg_1:LocalCharacter)
        {
            super.onStand(_arg_1);
            this.activate();
        }

        override public function onBump(_arg_1:LocalCharacter)
        {
            super.onBump(_arg_1);
            this.activate();
        }

        override public function onLeftHit(_arg_1:LocalCharacter)
        {
            super.onLeftHit(_arg_1);
            this.activate();
        }

        override public function onRightHit(_arg_1:LocalCharacter)
        {
            super.onRightHit(_arg_1);
            this.activate();
        }

        override public function onDamage(_arg_1:Number)
        {
            super.onDamage(_arg_1);
            this.activate();
        }

        private function method_594()
        {
            var _local_1:Point = getSeg();
            if (!map.characterOccupiesSpace(_local_1.x, _local_1.y)) {
                alpha = 0.2;
                this.clear();
                addEventListener(Event.ENTER_FRAME, this.method_117, false, 0, true);
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
                this.var_602 = setTimeout(this.method_594, 2000);
            }
        }

        private function method_117(_arg_1:Event)
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
            removeEventListener(Event.ENTER_FRAME, this.method_117);
            clearTimeout(this.var_602);
        }

        override public function remove()
        {
            this.clear();
            super.remove();
        }


    }
}//package blocks

