//blocks.HeartBlock = blocks.class_57

package blocks
{
    import com.jiggmin.data.Objects;
    import character.LocalCharacter;

    public class HeartBlock extends SupplyBlock 
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

