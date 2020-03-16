// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_15.SaveLevelPopup = package_15.class_175

package package_15
{
    import flash.events.Event;
    import flash.events.MouseEvent;
    import levelEditor.LevelEditor;
    import package_4.MessagePopup;
    import package_4.Popup;

    public class SaveLevelPopup extends Popup 
    {

        private var editor:LevelEditor = LevelEditor.editor;
        private var m:SaveLevelPopupGraphic = new SaveLevelPopupGraphic();

        public function SaveLevelPopup()
        {
            this.m.titleBox.text = this.editor.title;
            this.m.noteBox.text = this.editor.note;
            this.m.noteCharsRemaining.text = "0 / 255";
            this.m.noteBox.addEventListener(Event.CHANGE, this.noteCountChars);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.save_bt.addEventListener(MouseEvent.CLICK, this.clickSave);
            if (this.editor.live == 1) {
                this.m.publish_chk.selected = true;
            }
            addChild(this.m);
        }

        private function noteCountChars(e:Event)
        {
            this.m.noteCharsRemaining.text = this.m.noteBox.length + " / 255";
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        private function clickSave(e:MouseEvent)
        {
            if (this.m.titleBox.text == "") {
                new MessagePopup("I'm not sure what would happen if you didn't enter a title, but it would probably destroy the world.");
            } else {
                this.editor.title = this.m.titleBox.text;
                this.editor.note = this.m.noteBox.text;
                if (this.m.publish_chk.selected == true) {
                    this.editor.live = 1;
                } else {
                    this.editor.live = 0;
                }
                new UploadingLevelPopup();
                startFadeOut();
            }
        }

        override public function remove()
        {
            this.m.noteBox.removeEventListener(Event.CHANGE, this.noteCountChars);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.save_bt.removeEventListener(MouseEvent.CLICK, this.clickSave);
            super.remove();
        }


    }
}
