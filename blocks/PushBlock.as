// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.PushBlock = blocks.class_50

package blocks
{
    import data.Objects;
    import package_8.LocalCharacter;
    import data.class_28;
    import flash.geom.Point;

    public class PushBlock extends Block 
    {

        public function PushBlock()
        {
            super(Objects.PushBlockCode);
            var_34 = false;
        }

        override public function onStand(_arg_1:LocalCharacter)
        {
            super.onStand(_arg_1);
            this.localActivate("down");
        }

        override public function onBump(_arg_1:LocalCharacter)
        {
            super.onBump(_arg_1);
            this.localActivate("up");
        }

        override public function onLeftHit(_arg_1:LocalCharacter)
        {
            super.onLeftHit(_arg_1);
            this.localActivate("right");
        }

        override public function onRightHit(_arg_1:LocalCharacter)
        {
            super.onRightHit(_arg_1);
            this.localActivate("left");
        }

        override protected function localActivate(_arg_1:String="")
        {
            if (!var_37) {
                super.localActivate(_arg_1);
            }
        }

        override protected function activate(_arg_1:String="")
        {
            if (_arg_1 == "down") {
                this.method_93(0, 1);
            } else if (_arg_1 == "up") {
                this.method_93(0, -1);
            } else if (_arg_1 == "right") {
                this.method_93(1, 0);
            } else if (_arg_1 == "left") {
                this.method_93(-1, 0);
            }
        }

        private function method_93(_arg_1:int, _arg_2:int)
        {
            var _local_3:Point = class_28.method_9(_arg_1, _arg_2, map.rotation);
            move(_local_3.x, _local_3.y, map);
        }


    }
}//package blocks

