// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.SadBlock = blocks.class_53

package blocks
{
    import blocks.options.StatBlockOptions;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;

    public class SadBlock extends class_39 
    {
        private var changeAmt:int = -5;

        public function SadBlock()
        {
            optionsMenu = StatBlockOptions;
            super(Objects.BLOCK_SAD);
        }

        public function getChangeAmt()
        {
            return this.changeAmt;
        }

        public function applyOptions(optStr:String)
        {
            this.changeAmt = Data.numLimit(int(optStr), -100, -5);
            options = this.changeAmt < -5 ? this.changeAmt : '';
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            player.statsChange(this.changeAmt);
            SoundEffects.playSound(new BumpSadSound(), 0.75 * (Settings.soundLevel / 100));
        }


    }
}//package blocks

