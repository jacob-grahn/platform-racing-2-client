// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//class_105

package 
{
    import flash.display.MovieClip;

    public dynamic class class_105 extends MovieClip 
    {

        public function class_105()
        {
            addFrameScript(0, this.frame1);
        }

        internal function frame1():*
        {
            gotoAndStop(Math.floor((Math.random() * totalFrames)));
        }


    }
}//package 

