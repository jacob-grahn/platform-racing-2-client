// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.ItemBlock = blocks.class_40

package blocks
{
    import package_6.Course;
    import sounds.SoundEffects;
    import package_8.Racer;

    public class ItemBlock extends class_39 
    {

        public function ItemBlock(_arg_1:int=110)
        {
            super(_arg_1);
        }

        override protected function useSupply(_arg_1:Racer)
        {
            var _local_2:Number;
            var _local_3:int;
            super.useSupply(_arg_1);
            if (Course.course.var_86.length > 0) {
                _local_2 = Math.floor((Math.random() * Course.course.var_86.length));
                _local_3 = Course.course.var_86[_local_2];
                _arg_1.setItem(_local_3);
            }
            SoundEffects.playSound(new StarSound(), 0.6);
        }


    }
}//package blocks

