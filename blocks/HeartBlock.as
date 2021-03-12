// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.HeartBlock = blocks.class_57

package blocks
{
    import com.jiggmin.data.Objects;
    import package_8.LocalCharacter;

    public class HeartBlock extends class_39 
    {

        public function HeartBlock()
        {
            super(Objects.BLOCK_HEART);
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            player.gainHeart();
        }


    }
}//package blocks

