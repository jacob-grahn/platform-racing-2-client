// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.MineBlock = blocks.class_56

package blocks
{
    import data.Objects;
    import package_8.LocalCharacter;
    import package_9.class_106;
    import flash.geom.Point;
    import package_9.MineExplode;

    public class MineBlock extends Block 
    {

        public function MineBlock()
        {
            super(Objects.MineBlockCode);
            var_34 = false;
        }

        override public function onStand(_arg_1:LocalCharacter)
        {
            super.onStand(_arg_1);
            this.method_81(_arg_1);
        }

        override public function onBump(_arg_1:LocalCharacter)
        {
            super.onBump(_arg_1);
            this.method_81(_arg_1);
        }

        override public function onLeftHit(_arg_1:LocalCharacter)
        {
            super.onLeftHit(_arg_1);
            this.method_81(_arg_1);
        }

        override public function onRightHit(_arg_1:LocalCharacter)
        {
            super.onRightHit(_arg_1);
            this.method_81(_arg_1);
        }

        override public function onTouch(_arg_1:LocalCharacter)
        {
            super.onTouch(_arg_1);
            this.method_81(_arg_1);
        }

        override public function onDamage(_arg_1:Number)
        {
            super.onDamage(_arg_1);
            localActivate();
        }

        override protected function activate(_arg_1:String="")
        {
            var _local_2:class_106;
            var _local_3:MinePieceGraphic;
            var _local_4:Number;
            var _local_5:Number;
            var _local_6:Point = method_18();
            var _local_7:int;
            while (_local_7 < 10) {
                _local_3 = new MinePieceGraphic();
                _local_4 = ((Math.random() * 30) + _local_6.x);
                _local_5 = ((Math.random() * 30) + _local_6.y);
                _local_2 = new class_106(_local_3, 0.75, 0.95, 0.05, 30, 30, 50, _local_4, _local_5);
                _local_7++;
            }
            new MineExplode(_local_6.x, _local_6.y);
            remove();
        }

        private function method_81(_arg_1:LocalCharacter)
        {
            var _local_2:Number;
            var _local_3:Number;
            var _local_4:Number;
            var _local_5:Number;
            var _local_6:Number;
            var _local_7:Number;
            if (!frozen) {
                _local_2 = 50;
                _local_3 = (_arg_1.x - (x + 15));
                _local_4 = ((_arg_1.y - (_arg_1.var_325 / 2)) - (y + 15));
                _local_5 = Math.atan2(_local_4, _local_3);
                _local_6 = (Math.cos(_local_5) * _local_2);
                _local_7 = (Math.sin(_local_5) * _local_2);
                _arg_1.hit(_local_6, _local_7);
                localActivate();
            }
        }


    }
}//package blocks

