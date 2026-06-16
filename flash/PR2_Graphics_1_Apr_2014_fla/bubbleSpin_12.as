//PR2_Graphics_1_Apr_2014_fla.bubbleSpin_12

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;

    public dynamic class bubbleSpin_12 extends MovieClip 
    {

        public var bubble1:MovieClip;
        public var bubble2:MovieClip;
        public var bubble3:MovieClip;

        public function bubbleSpin_12()
        {
            addFrameScript(20, this.loopToStart);
        }

        internal function loopToStart():*
        {
            gotoAndPlay(1);
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

