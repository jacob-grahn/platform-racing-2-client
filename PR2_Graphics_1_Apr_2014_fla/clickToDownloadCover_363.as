// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//PR2_Graphics_1_Apr_2014_fla.clickToDownloadCover_363

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;
    import fl.controls.TextInput;
    import fl.controls.Button;
    import flash.text.TextField;
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    import flash.geom.*;
    import flash.net.*;
    import flash.text.*;
    import flash.media.*;
    import flash.ui.*;
    import flash.system.*;
    import flash.filters.*;
    import flash.errors.*;
    import flash.accessibility.*;
    import flash.globalization.*;
    import flash.net.drm.*;
    import flash.printing.*;
    import flash.sensors.*;
    import flash.xml.*;
    import flash.profiler.*;
    import flash.external.*;
    import flash.text.engine.*;
    import flash.desktop.*;
    import adobe.utils.*;
    import flash.text.ime.*;
    import flash.sampler.*;

    public dynamic class clickToDownloadCover_363 extends MovieClip 
    {

        public var passBox:TextInput;
        public var passButton:Button;
        public var textBox:TextField;

        public function clickToDownloadCover_363()
        {
            this.initComponentSettings();
        }

        internal function initComponentSettings():*
        {
            try {
                this.passButton["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.passButton.emphasized = false;
            this.passButton.enabled = true;
            this.passButton.label = "Enter";
            this.passButton.labelPlacement = "right";
            this.passButton.selected = false;
            this.passButton.toggle = false;
            this.passButton.visible = true;
            try {
                this.passButton["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

