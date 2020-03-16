//package_19.MusicMenuButton = package_19.class_218

package package_19
{
    import flash.events.MouseEvent;

    public class MusicMenuButton extends class_215 
    {

        private var song:String = "random";

        public function MusicMenuButton(_arg_1:Number=0)
        {
            addChild(new MusicNoteGraphic());
        }

        public function setSong(_arg_1:String)
        {
            this.song = _arg_1;
        }

        override protected function onClick(_arg_1:MouseEvent)
        {
            new MusicMenu(this, this.song);
        }


    }
}
