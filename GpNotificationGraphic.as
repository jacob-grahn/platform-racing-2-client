// GpNotificationGraphic

package 
{
    import flash.display.MovieClip;

    public dynamic class GpNotificationGraphic extends MovieClip 
    {

        public var anim:MovieClip;

        public function GpNotificationGraphic()
        {
            addFrameScript(70, this.frame71);
        }

        private function frame71()
        {
            stop();
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
