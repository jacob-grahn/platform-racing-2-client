// SendMessagePopupGraphic = class_244

package
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.TextInput;
    import fl.controls.TextArea;

    public dynamic class SendMessagePopupGraphic extends MovieClip 
    {

        public var nameBox:TextInput;
        public var textBox:TextArea;
        public var cancel_bt:Button; // var_1
        public var send_bt:Button; // var_23

        public function SendMessagePopupGraphic()
        {
            this.textBox.maxChars = 1000;
            this.cancel_bt.label = "Cancel";
            this.send_bt.label = "Send";
        }


    }
}
