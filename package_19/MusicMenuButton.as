//package_19.MusicMenuButton = package_19.class_218

package package_19
{
    import flash.events.MouseEvent;

    public class MusicMenuButton extends class_215 
    {

        private var song:String = 'random';

        public function MusicMenuButton()
        {
            addChild(new MusicNoteGraphic());
        }

        public function setSong(s:String)
        {
            this.song = s === '' ? 'random' : s;
        }

        override protected function onClick(e:MouseEvent)
        {
            new MusicMenu(this, this.song);
        }


    }
}
