// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_15.SaveLevelPopup = package_15.class_175

package package_15
{
    import package_4.Popup;
    import levelEditor.LevelEditor;
    import flash.events.MouseEvent;
    import package_4.MessagePopup;

    public class SaveLevelPopup extends Popup 
    {

        private var editor:LevelEditor = LevelEditor.editor;
        private var m:SaveLevelPopupGraphic = new SaveLevelPopupGraphic();

        public function SaveLevelPopup()
        {
            this.m.titleBox.text = this.editor.title;
            this.m.noteBox.text = this.editor.note;
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.save_bt.addEventListener(MouseEvent.CLICK, this.clickSave);
            if (this.editor.live == 1) {
                this.m.publish_chk.selected = true;
            }
            addChild(this.m);
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
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.save_bt.removeEventListener(MouseEvent.CLICK, this.clickSave);
            super.remove();
        }


    }
}
