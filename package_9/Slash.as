// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.Slash = package_9.class_134

package package_9
{
    import package_6.Course;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;
    import data.class_28;
    import flash.geom.Point;
    import blocks.Block;

    public class Slash extends Effect 
    {

        private var m:SlashAnimation = new SlashAnimation();
        private var course:Course = Course.course;
        private var var_5:LocalCharacter = Course.course.var_9;
        private var var_154:int = 29;
        private var var_609:int;

        public function Slash(_arg_1:int, _arg_2:int, _arg_3:String, _arg_4:int)
        {
            this.var_609 = _arg_4;
            super(_arg_1, _arg_2);
            addChild(this.m);
            method_2(6);
            if (_arg_3 == "left") {
                this.var_154 = -29;
                scaleX = -1;
            }
            this.method_66(x, y - 14);
            this.method_66(x, y + 14);
            this.method_66(x + this.var_154, y - 14);
            this.method_66(x + this.var_154, y + 14);
            this.method_66(x + (this.var_154 * 2), y - 14);
            this.method_66(x + (this.var_154 * 2), y + 14);
            SoundEffects.playGameSound(new SwishSound(), _arg_1, _arg_2);
        }

        private function method_66(_arg_1:int, _arg_2:int)
        {
            var _local_3:Point = class_28.method_9(_arg_1, _arg_2, this.course.blockBackground.rotation);
            var _local_4:Block = this.course.blockBackground.getBlockFromPos(_local_3.x, _local_3.y);
            if (_local_4 != null && _local_4.isActive()) {
                _local_4.onDamage(this.var_154);
            }
            if (this.var_5 != null && this.var_5.tempID != this.var_609 && this.var_5.y > _arg_2 - 14 && this.var_5.y < _arg_2 + 74) {
                if (this.var_5.x > _arg_1 - 14 && this.var_5.x < _arg_1 + 14) {
                    this.var_5.hit(this.var_154, -9);
                }
            }
        }

        override public function remove()
        {
            removeChild(this.m);
            this.course = null;
            this.var_5 = null;
            this.m = null;
            super.remove();
        }


    }
}//package package_9

