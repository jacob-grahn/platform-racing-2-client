// PlayerPopupGraphic = class_192

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import flash.text.TextField;

    public dynamic class PlayerPopupGraphic extends MovieClip 
    {

        public var close_bt:Button; // var_2
        public var playerInfo:MovieClip; // var_8
        public var loadingGraphic:LoadingGraphic;
        public var nameBox:TextField;

        public function PlayerPopupGraphic()
        {
            this.close_bt.label = "Close";
        }

    }
}
