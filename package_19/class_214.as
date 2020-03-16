// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_214

package package_19
{
    import flash.display.MovieClip;
    import flash.display.DisplayObject;
    import flash.geom.ColorTransform;
    import flash.events.MouseEvent;

    public class class_214 extends HoverDelayPopup 
    {

        private var bg:MovieClip = new SquareBG(); // var_274
        private var m:DisplayObject;

        public function class_214(_arg_1:DisplayObject, _arg_2:String="", _arg_3:String="")
        {
            super(_arg_2, _arg_3);
            this.m = _arg_1;
            this.bg.width = this.bg.height = 28;
            this.bg.x = this.bg.y = 1;
            addChild(this.bg);
            addChild(_arg_1);
        }

        override protected function overHandler(_arg_1:MouseEvent)
        {
            this.m.transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 128, 128, 128, 0);
            super.overHandler(_arg_1);
        }

        override protected function outHandler(_arg_1:MouseEvent)
        {
            this.m.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
            super.outHandler(_arg_1);
        }

        override public function remove()
        {
            super.remove();
        }


    }
}//package package_19

