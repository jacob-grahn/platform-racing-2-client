// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.IceBlock = blocks.class_44

package blocks
{
    import com.jiggmin.data.Objects;
    import character.LocalCharacter;

    public class IceBlock extends Block 
    {

        public function IceBlock()
        {
            super(Objects.BLOCK_ICE);
        }

        override public function onStand(player:LocalCharacter)
        {
            super.onStand(player);
            player.accelFactor = 0.05;
        }


    }
}//package blocks

