// blocks.BrickBlock = blocks.class_55

package blocks
{
    import data.Objects;
    import package_8.LocalCharacter;
    import package_9.class_106;
    import flash.geom.Point;

    public class BrickBlock extends Block 
    {

        public function BrickBlock()
        {
            super(Objects.BrickBlockCode);
            var_34 = false;
        }

        override public function onBump(_arg_1:LocalCharacter)
        {
            super.onBump(_arg_1);
            if (!frozen) {
                localActivate();
            }
        }

        override public function onDamage(_arg_1:Number)
        {
            super.onDamage(_arg_1);
            if (!frozen) {
                localActivate();
            }
        }

        override protected function activate(_arg_1:String="")
        {
            var _local_2:class_106;
            var _local_3:BrickPieceGraphic;
            var _local_5:Number;
            var _local_6:Number;
            var _local_4:Point = method_18();
            var _local_7:int;
            while (_local_7 < 6) {
                _local_3 = new BrickPieceGraphic();
                _local_5 = ((Math.random() * 30) + _local_4.x);
                _local_6 = ((Math.random() * 30) + _local_4.y);
                _local_2 = new class_106(_local_3, 0.75, 0.95, 0.05, 10, 10, 25, _local_5, _local_6);
                _local_7++;
            }
            remove();
        }


    }
}//package blocks

