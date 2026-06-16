// HappyHour = class_92

package 
{
    import flash.display.MovieClip;

    public dynamic class HappyHour extends MovieClip 
    {

        public function HappyHour()
        {
            addFrameScript(99, this.frame100);
        }

        internal function frame100():*
        {
            stop();
            parent.removeChild(this);
        }


    }
}//package 

