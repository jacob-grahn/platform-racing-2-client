// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//PR2_Graphics_1_Apr_2014_fla.jumpAnim_61

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;

    public dynamic class jumpAnim_61 extends MovieClip 
    {

        public var body:MovieClip;
        public var foot1:MovieClip;
        public var foot2:MovieClip;
        public var head:MovieClip;
        public var weapon:MovieClip;

        public function jumpAnim_61()
        {
            addFrameScript(49, this.stopOnLastFrame);
        }

        internal function stopOnLastFrame():*
        {
            stop();
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

