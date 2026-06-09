

package editor_tools
{
    import dialogs.AutoDismissPopup;
    import ui.GameSound;
    import flash.events.Event;
    import levelEditor.LevelEditor;

    public class MusicMenu extends AutoDismissPopup 
    {

        private var list:GameSound = new GameSound(true);
        private var target:MusicMenuButton;

        public function MusicMenu(button:MusicMenuButton, currentSong:String)
        {
            this.target = button;
            this.list.x = (-(this.list.width) / 2);
            this.list.y = -15;
            this.list.setSong(currentSong);
            addChild(new MusicMenuGraphic());
            addChild(this.list);
            super(button);
            this.list.addEventListener(Event.CHANGE, this.changeSong, false, 0, true);
        }

        private function changeSong(e:Event)
        {
            LevelEditor.editor.setSong(e.target.selectedItem.id);
        }

        override public function remove()
        {
            this.list.removeEventListener(Event.CHANGE, this.changeSong);
            this.list.remove();
            super.remove();
        }


    }
}

