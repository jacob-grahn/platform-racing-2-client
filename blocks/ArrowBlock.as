// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.ArrowBlock = blocks.class_37

package blocks
{
    import character.LocalCharacter;

    public class ArrowBlock extends Block 
    {

        private var arrowMC:ArrowBlockGraphic = new ArrowBlockGraphic(); // var_41
        /*private var pushVelUp:Number = -1.2; // var_651
        private var pushVelLeft:Number = -3; // var_661
        private var pushVelRight:Number = 3; // var_628
        private var pushVelDown:Number = 5; // var_638*/
        private var rot:Number;

        public function ArrowBlock(blockId:int, r:Number)
        {
            this.rot = r;
            super(blockId);
            var_490 = false;
            this.arrowMC.rotation = this.rot;
            this.arrowMC.x = this.arrowMC.y = 15;
            addChild(this.arrowMC);
        }

        override public function getCode():int
        {
            return this.blockCode;
        }

        override public function onStand(player:LocalCharacter)
        {
            super.onStand(player);
            var _local_2:Number = this.getEffectiveRotation();
            if (_local_2 == 0 && !player.crouching) {
                player.velY -= 10;
            } else {
                this.push(player, _local_2);
            }
            this.animateArrow();
        }

        override public function onBump(player:LocalCharacter)
        {
            super.onBump(player);
            var _local_2:Number = this.getEffectiveRotation();
            if (_local_2 == 0) {
                player.velY = player.down == false && player.crouching == false ? -14 : 0;
            } else {
                this.push(player, _local_2);
            }
            this.animateArrow();
        }

        override public function onLeftHit(player:LocalCharacter)
        {
            super.onLeftHit(player);
            var _local_2:Number = this.getEffectiveRotation();
            this.push(player, _local_2);
            this.animateArrow();
        }

        override public function onRightHit(player:LocalCharacter)
        {
            super.onRightHit(player);
            var _local_2:Number = this.getEffectiveRotation();
            this.push(player, _local_2);
            this.animateArrow();
        }

        public function animateArrow()
        {
            if (this.arrowMC.currentFrame < 5) {
                this.arrowMC.gotoAndPlay(this.arrowMC.currentFrame + 1);
            } else if (this.arrowMC.currentFrame > 5) {
                this.arrowMC.gotoAndPlay(this.arrowMC.currentFrame - 1);
            }
        }

        private function getEffectiveRotation():Number
        {
            var _local_1:Number = map.rotation + this.rot;
            rotation = _local_1;
            _local_1 = rotation;
            rotation = 0;
            return _local_1;
        }

        private function push(player:LocalCharacter, deg:Number)
        {
            if (deg == 0 && player.crouching == false) { // up arrow
                player.velY -= 1.2;
            }
            if (deg == 180 || deg == -180) { // down arrow
                player.velY += 5;
            }
            if (deg == -90) { // left arrow
                player.velX -= 3;
            }
            if (deg == 90) { // right arrow
                player.velX += 3;
            }
        }

        override public function remove()
        {
            if (this.arrowMC.parent != null) {
                this.arrowMC.parent.removeChild(this.arrowMC);
                this.arrowMC = null;
            }
            super.remove();
        }


    }
}//package blocks

