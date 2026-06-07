

package editor_tools
{
    import flash.display.MovieClip;
    import flash.display.DisplayObject;
    import flash.geom.ColorTransform;
    import flash.events.MouseEvent;

    public class SidebarEntry extends HoverDelayPopup 
    {

        private var bg:MovieClip = new SquareBG(); // var_274
        private var m:DisplayObject;

        public function SidebarEntry(icon:DisplayObject, title:String="", desc:String="")
        {
            super(title, desc);
            this.m = icon;
            this.bg.width = this.bg.height = 28;
            this.bg.x = this.bg.y = 1;
            addChild(this.bg);
            addChild(icon);
        }

        override protected function overHandler(e:MouseEvent)
        {
            this.m.transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 128, 128, 128, 0);
            super.overHandler(e);
        }

        override protected function outHandler(e:MouseEvent)
        {
            this.m.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
            super.outHandler(e);
        }

        override public function remove()
        {
            super.remove();
        }


    }
}

