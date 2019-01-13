//package_19.class_218

package package_19
{
    import flash.events.MouseEvent;

    public class class_218 extends class_215 
    {

        private var song:String = "random";

        public function class_218(_arg_1:Number=0)
        {
            addChild(new MusicNoteGraphic());
        }

        public function setSong(_arg_1:String)
        {
            this.song = _arg_1;
        }

        override protected function onClick(_arg_1:MouseEvent)
        {
            new class_267(this, this.song);
        }


    }
}
