// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// GetLevelsPopupGraphic = class_230

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import flash.text.TextField;

    public dynamic class GetLevelsPopupGraphic extends MovieClip 
    {

        public var cancel_bt:Button; // var_1
        public var delete_bt:Button; // deleteButton
        public var load_bt:Button; // loadButton
        public var loadingGraphic:LoadingGraphic;
        public var levelsHolder:MovieClip; // var_263
        public var titleBox:TextField;

        public function GetLevelsPopupGraphic()
        {
            this.cancel_bt.label = "Cancel";
            this.delete_bt.label = "Delete";
            this.load_bt.label = "Load";
        }

    }
}
