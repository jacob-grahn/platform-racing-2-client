// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.WaterBlock = blocks.class_43

package blocks
{
    import data.Objects;
    import flash.geom.Point;
    import package_6.Course;
    import package_8.Racer;
    import flash.events.Event;

    public class WaterBlock extends Block 
    {

        private var var_484:Boolean = false;

        public function WaterBlock()
        {
            super(Objects.WaterBlockCode);
            var_34 = false;
            var_71 = false;
        }

        override public function onTouch(_arg_1:Racer)
        {
            var _local_2:Point;
            var _local_3:Point;
            super.onTouch(_arg_1);
            if (!var_37) {
                if ((((!(_arg_1.var_42)) && (!(_arg_1.mode == "freeze"))) && (!(_arg_1.mode == "hurt")))) {
                    _arg_1.setMode("water");
                    _arg_1.var_240 = 2;
                } else {
                    _arg_1.var_24 = (_arg_1.var_24 * 0.9);
                    _arg_1.var_147 = 0.1;
                }
                if (_arg_1.parent == Course.course.frontBackground) {
                    Course.course.backBackground.addChild(_arg_1);
                }
                _local_2 = method_18();
                _local_3 = getSeg();
                _arg_1.var_407 = _local_3.x;
                _arg_1.var_366 = _local_3.y;
                _arg_1.var_205 = (_local_2.x + 15);
                _arg_1.var_224 = (_local_2.y + 15);
                this.method_339();
            }
        }

        public function method_584()
        {
            this.method_339();
        }

        private function method_339()
        {
            alpha = (alpha - 0.1);
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
            alpha = (alpha + 0.03);
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

