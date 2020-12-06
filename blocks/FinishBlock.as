// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.FinishBlock = blocks.class_61

package blocks
{
    import com.jiggmin.data.Objects;
    import package_6.Course;
    import package_8.LocalCharacter;

    public class FinishBlock extends class_39 
    {

        public static var var_228:int = 1;

        private var id:int; // var_413

        public function FinishBlock()
        {
            this.id = var_228++;
            super(Objects.FinishBlockCode);
        }

        // method_140 = getId
        public function getId():int
        {
            return this.id;
        }

        override protected function useSupply(_arg_1:LocalCharacter)
        {
            var _local_2:int = getPosX() + 15;
            var _local_3:int = getPosY() + 15;
            Course.course.finish(this.id, _local_2, _local_3);
        }


    }
}
