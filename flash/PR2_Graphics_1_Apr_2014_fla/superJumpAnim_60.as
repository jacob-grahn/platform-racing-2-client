// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//PR2_Graphics_1_Apr_2014_fla.superJumpAnim_60

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;

    public dynamic class superJumpAnim_60 extends MovieClip 
    {

        public var body:MovieClip;
        public var foot1:MovieClip;
        public var foot2:MovieClip;
        public var head:MovieClip;
        public var weapon:MovieClip;

        public function superJumpAnim_60()
        {
            addFrameScript(50, this.stopOnLastFrame);
        }

        internal function stopOnLastFrame():*
        {
            stop();
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

