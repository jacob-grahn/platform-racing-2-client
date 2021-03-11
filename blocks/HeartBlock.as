// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.HeartBlock = blocks.class_57

package blocks
{
    import com.jiggmin.data.Objects;
    import package_8.LocalPlayer;

    public class HeartBlock extends class_39 
    {

        public function HeartBlock()
        {
            super(Objects.HeartBlockCode);
        }

        override protected function useSupply(player:LocalPlayer)
        {
            super.useSupply(player);
            player.gainHeart();
        }


    }
}//package blocks

