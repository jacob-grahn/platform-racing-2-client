// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//PR2_Graphics_1_Apr_2014_fla.frozenSolidAnim_65

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;
    import flash.events.Event;

    public dynamic class frozenSolidAnim_65 extends MovieClip 
    {

        public var body:MovieClip;
        public var foot1:MovieClip;
        public var foot2:MovieClip;
        public var head:MovieClip;
        public var weapon:MovieClip;

        public function frozenSolidAnim_65()
        {
            addFrameScript(47, this.onAnimComplete);
        }

        internal function onAnimComplete():*
        {
            stop();
            dispatchEvent(new Event(Event.COMPLETE));
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

