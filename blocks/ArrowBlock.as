// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.ArrowBlock = blocks.class_37

package blocks
{
    import package_8.Racer;

    public class ArrowBlock extends Block 
    {

        private var var_41:ArrowBlockGraphic = new ArrowBlockGraphic();
        private var var_651:Number = -1.2;
        private var var_661:Number = -3;
        private var var_628:Number = 3;
        private var var_638:Number = 5;
        private var rot:Number;

        public function ArrowBlock(_arg_1:int, _arg_2:Number)
        {
            this.rot = _arg_2;
            super(_arg_1);
            var_490 = false;
            this.var_41.rotation = _arg_2;
            this.var_41.x = (this.var_41.y = 15);
            addChild(this.var_41);
        }

        override public function getCode():int
        {
            return (this.var_79);
        }

        override public function onStand(_arg_1:Racer)
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

        override public function onBump(_arg_1:Racer)
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

        override public function onLeftHit(_arg_1:Racer)
        {
            super.onLeftHit(_arg_1);
            var _local_2:Number = this.method_125();
            this.push(_arg_1, _local_2);
            this.method_87();
        }

        override public function onRightHit(_arg_1:Racer)
        {
            super.onRightHit(_arg_1);
            var _local_2:Number = this.method_125();
            this.push(_arg_1, _local_2);
            this.method_87();
        }

        public function method_87()
        {
            if (this.var_41.currentFrame < 5) {
                this.var_41.gotoAndPlay((this.var_41.currentFrame + 1));
            }
            if (this.var_41.currentFrame > 5) {
                this.var_41.gotoAndPlay((this.var_41.currentFrame - 1));
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

        private function push(_arg_1:Racer, _arg_2:Number)
        {
            if (_arg_2 == 0) {
                if (_arg_1.crouching == false) {
                    _arg_1.velY = (_arg_1.velY + this.var_651);
                }
            }
            if (((_arg_2 == 180) || (_arg_2 == -180))) {
                _arg_1.velY = (_arg_1.velY + this.var_638);
            }
            if (_arg_2 == -90) {
                _arg_1.velX = (_arg_1.velX + this.var_661);
            }
            if (_arg_2 == 90) {
                _arg_1.velX = (_arg_1.velX + this.var_628);
            }
        }

        override public function remove()
        {
            if (this.var_41.parent != null) {
                this.var_41.parent.removeChild(this.var_41);
                this.var_41 = null;
            }
            super.remove();
        }


    }
}//package blocks

