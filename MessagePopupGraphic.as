// MessagePopupGraphic = class_73

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.TextArea;

    public dynamic class MessagePopupGraphic extends MovieClip 
    {

        public var ok_bt:Button; // ok_bt = var_3
        public var textBox:TextArea;

        public function MessagePopupGraphic()
        {
            this.ok_bt.label = "OK";
            this.textBox.editable = false;
        }


    }
}
