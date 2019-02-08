// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.HappyBlock = blocks.class_58

package blocks
{
    import data.Objects;
    import sounds.SoundEffects;
    import package_8.Racer;

    public class HappyBlock extends class_39 
    {

        public function HappyBlock()
        {
            super(Objects.HappyBlockCode);
        }

        override protected function useSupply(_arg_1:Racer)
        {
            super.useSupply(_arg_1);
            _arg_1.method_392(5);
            SoundEffects.playSound(new BumpHappySound(), 0.75 * (Main.soundLevel / 100));
        }


    }
}//package blocks

