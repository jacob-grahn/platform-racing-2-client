// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.CrumbleBlock = blocks.class_63

package blocks
{
    import data.Objects;
    import package_8.Racer;
    import package_9.class_106;
    import flash.geom.Point;

    public class CrumbleBlock extends Block 
    {

        private var life:int = 10;

        public function CrumbleBlock()
        {
            super(Objects.CrumbleBlockCode);
            var_34 = false;
        }

        override public function onStand(_arg_1:Racer)
        {
            localActivate(Math.round((_arg_1.velY * 2)).toString());
            if (!method_20()) {
                super.onStand(_arg_1);
            }
        }

        override public function onBump(_arg_1:Racer)
        {
            localActivate(Math.round(-(_arg_1.velY)).toString());
            if (!method_20()) {
                super.onBump(_arg_1);
            }
        }

        override public function onLeftHit(_arg_1:Racer)
        {
            localActivate(Math.round((_arg_1.velX * 1.75)).toString());
            if (!method_20()) {
                super.onLeftHit(_arg_1);
            }
        }

        override public function onRightHit(_arg_1:Racer)
        {
            localActivate(Math.round((-(_arg_1.velX) * 1.75)).toString());
            if (!method_20()) {
                super.onRightHit(_arg_1);
            }
        }

        override public function onDamage(_arg_1:Number)
        {
            super.onDamage(_arg_1);
            localActivate("5");
        }

        override protected function activate(_arg_1:String="")
        {
            var _local_2 = Math.floor(Number(_arg_1) / 4);
            this.life = this.life - _local_2;
            this.throwPieces(_local_2 * 2);
            if (this.life <= 0) {
                this.doCrumble();
            }
        }

        // method_707 = doCrumble
        private function doCrumble()
        {
            this.throwPieces(10);
            remove();
        }

        // method_294 = throwPieces
        private function throwPieces(_arg_1:Number)
        {
            var _local_2:CrumblePieceGraphic;
            var _local_3:class_106;
            var _local_4:Number;
            var _local_5:Number;
            var _local_6:Point = method_18();
            var _local_7:int;
            while (_local_7 < _arg_1) {
                _local_2 = new CrumblePieceGraphic();
                _local_4 = ((Math.random() * 30) + _local_6.x);
                _local_5 = ((Math.random() * 30) + _local_6.y);
                _local_3 = new class_106(_local_2, 0.75, 0.95, 0.05, 5, 5, 15, _local_4, _local_5);
                _local_7++;
            }
        }


    }
}//package blocks

