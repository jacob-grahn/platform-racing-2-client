// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// SaveLevelPopupGraphic = class_234

package
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.CheckBox;
    import fl.controls.TextArea;
    import fl.controls.TextInput;

    public dynamic class SaveLevelPopupGraphic extends MovieClip
    {

        public var titleBox:TextInput;
        public var noteBox:TextArea; // var_585
        public var publish_chk:CheckBox; // var_166
        public var cancel_bt:Button; // var_1
        public var save_bt:Button; // saveButton

        public function SaveLevelPopupGraphic()
        {
            this.publish_chk.label = "";
            this.save_bt.label = "Save";
            this.cancel_bt.label = "Cancel";
        }

    }
}
