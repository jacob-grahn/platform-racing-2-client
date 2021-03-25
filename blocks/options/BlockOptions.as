package blocks.options
{
    import blocks.Block;
    import flash.display.MovieClip;
    import package_4.class_264;

    public class BlockOptions extends class_264
    {
        protected var block:Block;
        protected var m:MovieClip;

        public function BlockOptions(block:Block)
        {
            this.block = block;
            addChild(this.m);
            super(block);
        }

    }
}
