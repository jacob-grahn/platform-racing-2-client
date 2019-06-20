// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.class_45

package blocks
{
    import package_6.Course;
    import package_8.LocalCharacter;

    public class class_45 extends Block 
    {

        protected var dir:String;

        public function class_45(_arg_1:int)
        {
            super(_arg_1);
        }

        override public function onBump(_arg_1:LocalCharacter)
        {
            super.onBump(_arg_1);
            if (!var_37) {
                _arg_1.setMode("freeze");
                _arg_1.velX = (_arg_1.velY = 0);
                Course.course.method_654(this.dir);
            }
        }


    }
}//package blocks

