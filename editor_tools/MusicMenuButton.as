
package editor_tools
{
    import flash.events.MouseEvent;

    public class MusicMenuButton extends MenuButton 
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
