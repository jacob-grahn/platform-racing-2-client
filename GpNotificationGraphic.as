// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//GpNotificationGraphic

package 
{
    import flash.display.MovieClip;

    public dynamic class GpNotificationGraphic extends MovieClip 
    {

        public var anim:MovieClip;

        public function GpNotificationGraphic()
        {
            addFrameScript(71, this.method_604);
        }

        internal function method_604():*
        {
            stop();
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package 

