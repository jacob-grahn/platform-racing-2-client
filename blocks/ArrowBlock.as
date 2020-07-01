// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.ArrowBlock = blocks.class_37

package blocks
{
    import package_8.LocalCharacter;

    public class ArrowBlock extends Block 
    {

        private var arrowMC:ArrowBlockGraphic = new ArrowBlockGraphic(); // var_41
        /*private var pushVelUp:Number = -1.2; // var_651
        private var pushVelLeft:Number = -3; // var_661
        private var pushVelRight:Number = 3; // var_628
        private var pushVelDown:Number = 5; // var_638*/
        private var rot:Number;

        public function ArrowBlock(_arg_1:int, _arg_2:Number)
        {
            this.rot = _arg_2;
            super(_arg_1);
            var_490 = false;
            this.arrowMC.rotation = _arg_2;
            this.arrowMC.x = this.arrowMC.y = 15;
            addChild(this.arrowMC);
        }

        override public function getCode():int
        {
            return this.blockCode;
        }

        override public function onStand(_arg_1:LocalCharacter)
        {
            super.onStand(_arg_1);
            var _local_2:Number = this.method_125();
            if (_local_2 == 0) {
                if (!_arg_1.crouching) {
                    _arg_1.velY = (_arg_1.velY + -10);
                }
            } else {
                this.push(_arg_1, _local_2);
            }
            this.method_87();
        }

        override public function onBump(_arg_1:LocalCharacter)
        {
            super.onBump(_arg_1);
            var _local_2:Number = this.method_125();
            if (_local_2 == 0) {
                if (((_arg_1.down == false) && (_arg_1.crouching == false))) {
                    _arg_1.velY = -14;
                } else {
                    _arg_1.velY = 0;
                }
            } else {
                this.push(_arg_1, _local_2);
            }
            this.method_87();
        }

        override public function onLeftHit(_arg_1:LocalCharacter)
        {
            super.onLeftHit(_arg_1);
            var _local_2:Number = this.method_125();
            this.push(_arg_1, _local_2);
            this.method_87();
        }

        override public function onRightHit(_arg_1:LocalCharacter)
        {
            super.onRightHit(_arg_1);
            var _local_2:Number = this.method_125();
            this.push(_arg_1, _local_2);
            this.method_87();
        }

        public function method_87()
        {
            if (this.arrowMC.currentFrame < 5) {
                this.arrowMC.gotoAndPlay((this.arrowMC.currentFrame + 1));
            }
            if (this.arrowMC.currentFrame > 5) {
                this.arrowMC.gotoAndPlay((this.arrowMC.currentFrame - 1));
            }
        }

        private function method_125():Number
        {
            var _local_1:Number = (map.rotation + this.rot);
            rotation = _local_1;
            _local_1 = rotation;
            rotation = 0;
            return (_local_1);
        }

        private function push(c:LocalCharacter, deg:Number)
        {
            if (deg == 0) { // up arrow
                if (c.crouching == false) {
                    c.velY = c.velY + -1.2;
                }
            }
            if (deg == 180 || deg == -180) { // down arrow
                c.velY = c.velY + 5;
            }
            if (deg == -90) { // left arrow
                c.velX = c.velX + -3;
            }
            if (deg == 90) { // right arrow
                c.velX = c.velX + 3;
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

