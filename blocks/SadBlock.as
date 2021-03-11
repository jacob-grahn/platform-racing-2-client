// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.SadBlock = blocks.class_53

package blocks
{
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import sounds.SoundEffects;
    import package_8.LocalPlayer;

    public class SadBlock extends class_39 
    {

        public function SadBlock()
        {
            super(Objects.SadBlockCode);
        }

        override protected function useSupply(player:LocalPlayer)
        {
            super.useSupply(player);
            player.statsChange(-5);
            SoundEffects.playSound(new BumpSadSound(), 0.75 * (Settings.soundLevel / 100));
        }


    }
}//package blocks

