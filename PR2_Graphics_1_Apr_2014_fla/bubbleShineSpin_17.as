// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//PR2_Graphics_1_Apr_2014_fla.bubbleShineSpin_17

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;

    public dynamic class bubbleShineSpin_17 extends MovieClip 
    {

        public var bubble1:MovieClip;
        public var bubble2:MovieClip;
        public var bubble3:MovieClip;

        public function bubbleShineSpin_17()
        {
            addFrameScript(20, this.loopToStart);
        }

        internal function loopToStart():*
        {
            gotoAndPlay(1);
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

