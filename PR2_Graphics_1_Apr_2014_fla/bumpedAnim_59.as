// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//PR2_Graphics_1_Apr_2014_fla.bumpedAnim_59

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;

    public dynamic class bumpedAnim_59 extends MovieClip 
    {

        public var body:MovieClip;
        public var foot1:MovieClip;
        public var foot2:MovieClip;
        public var head:MovieClip;
        public var weapon:MovieClip;
        public var var_652:*;

        public function bumpedAnim_59()
        {
            addFrameScript(55, this.onAnimComplete);
        }

        internal function onAnimComplete():*
        {
            this.var_652 = true;
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

