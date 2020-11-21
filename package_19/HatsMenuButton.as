package package_19
{
    import flash.events.MouseEvent;

    public class HatsMenuButton extends class_215 
    {

        public function HatsMenuButton(_arg_1:Number=0)
        {
            var button:HatsButtonGraphic = new HatsButtonGraphic();
            addChild(button);
        }

        override protected function onClick(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            new HatsMenu(this);
        }


    }
}
