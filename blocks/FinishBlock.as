// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.FinishBlock = blocks.class_61

package blocks
{
    import com.jiggmin.data.Objects;
    import gameplay.Course;
    import character.LocalCharacter;

    public class FinishBlock extends SupplyBlock 
    {

        public static var count:int = 1;

        private var id:int;

        public function FinishBlock()
        {
            this.id = count++;
            super(Objects.BLOCK_FINISH);
        }

        public function getId():int
        {
            return this.id;
        }

        override protected function useSupply(player:LocalCharacter)
        {
            var _local_2:int = getPosX() + 15;
            var _local_3:int = getPosY() + 15;
            Course.course.finish(this.id, _local_2, _local_3);
        }


    }
}
