// blocks.BrickBlock = blocks.class_55

package blocks
{
    import com.jiggmin.data.Objects;
    import package_8.LocalPlayer;
    import package_9.BlockPiece;
    import flash.geom.Point;

    public class BrickBlock extends Block 
    {

        public function BrickBlock()
        {
            super(Objects.BrickBlockCode);
            var_34 = false;
        }

        override public function onBump(player:LocalPlayer)
        {
            super.onBump(player);
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

        // _loc3 = piece
        // _loc5 = posX
        // _loc6 = posY
        // _loc7 = i
        override protected function activate(_arg_1:String="")
        {
            var _local_4:Point = method_18();
            var i:int;
            while (i < 6) {
                var piece:BrickPieceGraphic = new BrickPieceGraphic();
                var posX:Number = (Math.random() * 30) + _local_4.x;
                var posY:Number = (Math.random() * 30) + _local_4.y;
                var _local_2:BlockPiece = new BlockPiece(piece, 0.75, 0.95, 0.05, 10, 10, 25, posX, posY);
                i++;
            }
            remove();
        }


    }
}//package blocks

