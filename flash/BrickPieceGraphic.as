// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// BrickPieceGraphic = class_105

package 
{
    import flash.display.MovieClip;

    public dynamic class BrickPieceGraphic extends MovieClip 
    {

        public function BrickPieceGraphic()
        {
            addFrameScript(0, this.frame1);
        }

        internal function frame1():*
        {
            gotoAndStop(Math.floor((Math.random() * totalFrames)));
        }


    }
}//package 

