// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//JiggminIntroGraphic

package 
{
    import flash.display.MovieClip;
    import flash.events.Event;

    public dynamic class JiggminIntroGraphic extends MovieClip 
    {

        public var logo:MovieClip;

        public function JiggminIntroGraphic()
        {
            addFrameScript(230, this.frame231);
        }

        private function frame231()
        {
            stop();
            dispatchEvent(new Event(Event.COMPLETE));
        }


    }
}
