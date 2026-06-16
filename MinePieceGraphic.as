// MinePieceGraphic = class_107

package 
{
    import flash.display.MovieClip;

    public dynamic class MinePieceGraphic extends MovieClip 
    {

        public function MinePieceGraphic()
        {
            addFrameScript(0, this.frame1);
        }

        internal function frame1():*
        {
            gotoAndStop(Math.floor((Math.random() * totalFrames)));
        }


    }
}//package 

