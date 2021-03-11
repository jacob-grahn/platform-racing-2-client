// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.WaterBlock = blocks.class_43

package blocks
{
    import com.jiggmin.data.Objects;
    import flash.geom.Point;
    import package_6.Course;
    import package_8.LocalPlayer;
    import flash.events.Event;

    public class WaterBlock extends Block 
    {

        private var var_484:Boolean = false;

        public function WaterBlock()
        {
            super(Objects.BLOCK_WATER);
            var_34 = false;
            active = false;
        }

        override public function onTouch(player:LocalPlayer)
        {
            super.onTouch(player);
            if (!frozen) {
                if (!player.grounded && player.mode != "freeze" && player.mode != "hurt") {
                    player.setMode("water");
                    player.var_240 = 2;
                } else {
                    player.var_24 *= 0.9;
                    player.var_147 = 0.1;
                }
                if (player.parent == Course.course.frontBackground) {
                    Course.course.backBackground.addChild(player);
                }
                var _local_2:Point = method_18();
                var _local_3:Point = getSeg();
                player.var_407 = _local_3.x;
                player.var_366 = _local_3.y;
                player.var_205 = _local_2.x + 15;
                player.var_224 = _local_2.y + 15;
                this.method_339();
            }
        }

        public function method_584()
        {
            this.method_339();
        }

        private function method_339()
        {
            alpha -= 0.1;
            if (alpha < 0.5) {
                alpha = 0.5;
            }
            if (!this.var_484) {
                this.var_484 = true;
                addEventListener(Event.ENTER_FRAME, this.method_117, false, 0, true);
            }
        }

        private function method_117(_arg_1:Event)
        {
            alpha += 0.03;
            if (alpha >= 1) {
                alpha = 1;
                this.var_484 = false;
                removeEventListener(Event.ENTER_FRAME, this.method_117);
            }
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_117);
            super.remove();
        }


    }
}//package blocks

