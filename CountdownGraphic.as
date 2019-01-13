// CountdownGraphic

package 
{
    import flash.display.MovieClip;
    import flash.events.Event;

    public dynamic class CountdownGraphic extends MovieClip 
    {

        public function CountdownGraphic()
        {
            addFrameScript(8, this.frame9, 23, this.frame24, 38, this.frame39, 53, this.frame54, 61, this.frame62);
        }

        private function frame9()
        {
            dispatchEvent(new Event("count"));
        }

        private function frame24()
        {
            dispatchEvent(new Event("count"));
        }

        private function frame39()
        {
            dispatchEvent(new Event("count"));
        }

        private function frame54()
        {
            dispatchEvent(new Event("finish"));
        }

        private function frame62()
        {
            stop();
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
