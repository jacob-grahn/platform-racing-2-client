// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//EggGraphic

package 
{
    import flash.display.MovieClip;

    public dynamic class EggGraphic extends MovieClip 
    {

        public var var_152:MovieClip;
        public var egg:MovieClip;
        public var var_165:MovieClip;

        public function EggGraphic()
        {
            addFrameScript(24, this.frame25, 46, this.frame47);
        }

        internal function frame25():*
        {
            gotoAndPlay("walk");
        }

        internal function frame47():*
        {
            stop();
        }


    }
}//package 

