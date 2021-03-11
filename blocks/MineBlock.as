// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.MineBlock = blocks.class_56

package blocks
{
    import com.jiggmin.data.Objects;
    import flash.geom.Point;
    import package_8.LocalPlayer;
    import package_9.BlockPiece;
    import package_9.MineExplode;

    public class MineBlock extends Block 
    {

        public function MineBlock()
        {
            super(Objects.BLOCK_MINE);
            var_34 = false;
        }

        override public function onStand(player:LocalPlayer)
        {
            super.onStand(player);
            this.method_81(player);
        }

        override public function onBump(player:LocalPlayer)
        {
            super.onBump(player);
            this.method_81(player);
        }

        override public function onLeftHit(player:LocalPlayer)
        {
            super.onLeftHit(player);
            this.method_81(player);
        }

        override public function onRightHit(player:LocalPlayer)
        {
            super.onRightHit(player);
            this.method_81(player);
        }

        override public function onTouch(player:LocalPlayer)
        {
            super.onTouch(player);
            this.method_81(player);
        }

        override public function onDamage(n:Number)
        {
            super.onDamage(n);
            localActivate();
        }

        // _loc3 = piece
        override protected function activate(s:String="")
        {
            var _local_6:Point = method_18();
            var i:int;
            while (i < 10) {
                var piece:MinePieceGraphic = new MinePieceGraphic();
                var _local_4:Number = (Math.random() * 30) + _local_6.x;
                var _local_5:Number = (Math.random() * 30) + _local_6.y;
                var _local_2:BlockPiece = new BlockPiece(piece, 0.75, 0.95, 0.05, 30, 30, 50, _local_4, _local_5);
                i++;
            }
            new MineExplode(_local_6.x, _local_6.y);
            remove();
        }

        private function method_81(player:LocalPlayer)
        {
            if (!frozen) {
                var _local_2:Number = 50;
                var _local_3:Number = player.x - x + 15;
                var _local_4:Number = player.y - (player.var_325 / 2) - y + 15;
                var _local_5:Number = Math.atan2(_local_4, _local_3);
                var _local_6:Number = Math.cos(_local_5) * _local_2;
                var _local_7:Number = Math.sin(_local_5) * _local_2;
                player.hit(_local_6, _local_7);
                localActivate();
            }
        }


    }
}//package blocks

