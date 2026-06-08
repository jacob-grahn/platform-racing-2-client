// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.RotateBlock = blocks.class_45

package blocks
{
    import gameplay.Course;
    import package_8.LocalCharacter;

    public class RotateBlock extends Block 
    {

        protected var dir:String;

        public function RotateBlock(code:int)
        {
            super(code);
        }

        override public function onBump(player:LocalCharacter)
        {
            super.onBump(player);
            if (!frozen) {
                player.setMode("freeze");
                player.velX = player.velY = 0;
                Course.course.startRotate(this.dir);
            }
        }


    }
}
