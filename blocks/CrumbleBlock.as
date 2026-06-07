// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.CrumbleBlock = blocks.class_63

package blocks
{
    import com.jiggmin.data.Objects;
    import package_8.Character;
    import package_8.LocalCharacter;
    import effects.BlockPiece;
    import flash.geom.Point;

    public class CrumbleBlock extends Block 
    {

        private var life:int = 10;

        public function CrumbleBlock()
        {
            super(Objects.BLOCK_CRUMBLE);
            safeStand = false;
        }

        override public function onStand(player:LocalCharacter)
        {
            var force:Number = this.cheeseHandler(player, Math.round(player.velY * 2), true);
            localActivate(force.toString());
            if (!isRemoved()) {
                super.onStand(player);
            }
        }

        override public function onBump(player:LocalCharacter)
        {
            var force:Number = this.cheeseHandler(player, Math.round(-player.velY));
            localActivate(force.toString());
            if (!isRemoved()) {
                super.onBump(player);
            }
        }

        override public function onLeftHit(player:LocalCharacter)
        {
            var force:Number = this.cheeseHandler(player, Math.round(player.velX * 1.75));
            if (force == 50) { // using cheese, kill crumbles at player's head level when running
                var seg:Point = getSeg();
                var blockAbovePlayer:Block = map.getBlockFromSeg(seg.x - 1, seg.y - 1);
                if (blockAbovePlayer == null && !player.crouching) {
                    var blockAboveThis:Block = map.getBlockFromSeg(seg.x, seg.y - 1);
                    if (blockAboveThis != null && blockAboveThis is CrumbleBlock) {
                        blockAboveThis.localActivate("50");
                    }
                }
            }
            localActivate(force.toString());
            if (!isRemoved()) {
                super.onLeftHit(player);
            }
        }

        override public function onRightHit(player:LocalCharacter)
        {
            var force:Number = this.cheeseHandler(player, Math.round(-player.velX * 1.75));
            if (force == 50) { // using cheese, kill crumbles at player's head level when running
                var seg:Point = getSeg();
                var blockAbovePlayer:Block = map.getBlockFromSeg(seg.x + 1, seg.y - 1);
                if (blockAbovePlayer == null && !player.crouching) {
                    var blockAboveThis:Block = map.getBlockFromSeg(seg.x, seg.y - 1);
                    if (blockAboveThis != null && blockAboveThis is CrumbleBlock) {
                        blockAboveThis.localActivate("50");
                    }
                }
            }
            localActivate(force.toString());
            if (!isRemoved()) {
                super.onRightHit(player);
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
            this.life -= _local_2;
            this.throwPieces(_local_2 * 2);
            if (this.life <= 0) {
                this.doCrumble();
            }
        }

        private function cheeseHandler(player:LocalCharacter, hitForce:Number, stand:Boolean = false)
        {
            if (hitForce > 1 && player.var_4.getBool(Character.CHEESE)) {
                return stand ? hitForce * 2 : 50;
            }
            return hitForce;
        }

        // method_707 = doCrumble
        private function doCrumble()
        {
            this.throwPieces(10);
            remove();
        }

        // _loc2 = piece
        // _loc7 = i
        // method_294 = throwPieces
        private function throwPieces(piecesToThrow:Number)
        {
            var _local_6:Point = method_18();
            piecesToThrow = piecesToThrow > 20 ? 20 : piecesToThrow;
            var i:int = 0;
            while (i < piecesToThrow) {
                var piece:CrumblePieceGraphic = new CrumblePieceGraphic();
                var _local_4:Number = (Math.random() * 30) + _local_6.x;
                var _local_5:Number = (Math.random() * 30) + _local_6.y;
                var _local_3:BlockPiece = new BlockPiece(piece, 0.75, 0.95, 0.05, 5, 5, 15, _local_4, _local_5);
                i++;
            }
        }


    }
}//package blocks

