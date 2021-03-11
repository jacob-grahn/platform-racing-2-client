// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.PushBlock = blocks.class_50

package blocks
{
    import com.jiggmin.data.Objects;
    import package_8.LocalPlayer;
    import com.jiggmin.data.Data;
    import flash.geom.Point;

    public class PushBlock extends Block 
    {

        public function PushBlock()
        {
            super(Objects.PushBlockCode);
            var_34 = false;
        }

        override public function onStand(player:LocalPlayer)
        {
            super.onStand(player);
            this.localActivate("down");
        }

        override public function onBump(player:LocalPlayer)
        {
            super.onBump(player);
            this.localActivate("up");
        }

        override public function onLeftHit(player:LocalPlayer)
        {
            super.onLeftHit(player);
            this.localActivate("right");
        }

        override public function onRightHit(player:LocalPlayer)
        {
            super.onRightHit(player);
            this.localActivate("left");
        }

        override protected function localActivate(_arg_1:String="")
        {
            if (!frozen) {
                super.localActivate(_arg_1);
            }
        }

        override protected function activate(_arg_1:String="")
        {
            if (_arg_1 == "down") {
                this.push(0, 1);
            } else if (_arg_1 == "up") {
                this.push(0, -1);
            } else if (_arg_1 == "right") {
                this.push(1, 0);
            } else if (_arg_1 == "left") {
                this.push(-1, 0);
            }
        }

        // _loc3 = newSeg
        // method_93 = push
        private function push(incSegX:int, incSegY:int)
        {
            var newSeg:Point = Data.method_9(incSegX, incSegY, map.rotation);
            move(newSeg.x, newSeg.y, map);
        }


    }
}//package blocks

