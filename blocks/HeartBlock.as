// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.HeartBlock = blocks.class_57

package blocks
{
    import data.Objects;
    import package_8.Racer;

    public class HeartBlock extends class_39 
    {

        public function HeartBlock()
        {
            super(Objects.HeartBlockCode);
        }

        override protected function useSupply(_arg_1:Racer)
        {
            super.useSupply(_arg_1);
            _arg_1.gainHeart();
        }


    }
}//package blocks

