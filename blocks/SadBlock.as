// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.SadBlock = blocks.class_53

package blocks
{
    import data.Objects;
    import sounds.SoundEffects;
    import package_8.Racer;

    public class SadBlock extends class_39 
    {

        public function SadBlock()
        {
            super(Objects.SadBlockCode);
        }

        override protected function useSupply(_arg_1:Racer)
        {
            super.useSupply(_arg_1);
            _arg_1.method_392(-5);
            SoundEffects.playSound(new BumpSadSound(), 0.75);
        }


    }
}//package blocks

