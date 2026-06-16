// EggGraphic

package
{
    import flash.display.MovieClip;

    public dynamic class EggGraphic extends MovieClip 
    {

        public var var_152:MovieClip;
        public var egg:MovieClip;
        public var var_165:MovieClip;

        public function EggGraphic()
        {
            addFrameScript(24, this.frame25, 45, this.frame46);
        }

        private function frame25()
        {
            gotoAndPlay("walk");
        }

        private function frame46()
        {
            stop();
        }


    }
}
