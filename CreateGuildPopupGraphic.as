// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//CreateGuildPopupGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import flash.display.SimpleButton;
    import fl.controls.TextInput;
    import fl.controls.TextArea;
    import flash.text.TextField;

    public dynamic class CreateGuildPopupGraphic extends MovieClip
    {

        public var titleBox:TextField;
        public var nameBox:TextInput;
        public var deleteEmblem_bt:SimpleButton;
        public var changeEmblem_bt:SimpleButton; // var_512
        public var proseBox:TextArea; // var_324
        public var confirm_bt:Button; // var_3
        public var cancel_bt:Button; // var_1
        public var transfer_bg:ShadowBG;
        public var transfer_bt:SimpleButton;

        public function CreateGuildPopupGraphic()
        {
            this.nameBox.maxChars = 20;
            this.proseBox.maxChars = 100;
            this.cancel_bt.label = "Cancel";
            this.confirm_bt.label = "Confirm";
            this.transfer_bg.visible = false;
            this.transfer_bt.visible = false;
        }

    }
}
