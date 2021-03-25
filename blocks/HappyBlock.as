// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.HappyBlock = blocks.class_58

package blocks
{
    import blocks.options.StatBlockOptions;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;

    public class HappyBlock extends class_39 
    {

        private var changeAmt:int = 5;

        public function HappyBlock()
        {
            optionsMenu = StatBlockOptions;
            super(Objects.BLOCK_HAPPY);
        }

        public function getChangeAmt()
        {
            return this.changeAmt;
        }

        public function applyOptions(optStr:String)
        {
            options = this.changeAmt = Data.numLimit(int(optStr), 5, 100);
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            player.statsChange(this.changeAmt);
            SoundEffects.playSound(new BumpHappySound(), 0.75 * (Settings.soundLevel / 100));
        }


    }
}//package blocks
