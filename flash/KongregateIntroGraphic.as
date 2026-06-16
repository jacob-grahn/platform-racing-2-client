//KongregateIntroGraphic

package 
{
    import flash.display.MovieClip;
    import flash.events.Event;

    public dynamic class KongregateIntroGraphic extends MovieClip 
    {

        public function KongregateIntroGraphic()
        {
            addFrameScript(152, this.frame153);
        }

        private function frame153():*
        {
            stop();
            dispatchEvent(new Event(Event.COMPLETE));
        }


    }
}//package 

