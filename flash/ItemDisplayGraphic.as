// ItemDisplayGraphic = class_144

package 
{
    import flash.display.MovieClip;

    public dynamic class ItemDisplayGraphic extends MovieClip 
    {

        public var a1:Circle;
        public var a2:Circle;
        public var a3:Circle;
        public var holder1:MovieClip;
        public var holder2:MovieClip;

        public function ItemDisplayGraphic()
        {
            addFrameScript(0, this.frame1);
        }

        private function frame1()
        {
            stop();
        }


    }
}
