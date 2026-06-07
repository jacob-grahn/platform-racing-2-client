package blocks.options
{
    import blocks.Block;
    import flash.display.MovieClip;
    import dialogs.AutoDismissPopup;

    public class BlockOptions extends AutoDismissPopup
    {
        private static var instance:BlockOptions;

        protected var block:Block;
        protected var m:MovieClip;

        public function BlockOptions(block:Block)
        {
            if (instance != null) {
                instance.remove();
            }
            instance = this;
            this.block = block;
            addChild(this.m);
            super(block);
        }

        override public function remove()
        {
            instance = null;
            super.remove();
        }

    }
}
