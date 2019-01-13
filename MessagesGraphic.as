// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//MessagesGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
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

    public dynamic class MessagesGraphic extends MovieClip 
    {

        public var var_108:Button;
        public var var_295:MovieClip;
        public var var_93:Button;

        public function MessagesGraphic()
        {
            this.method_677();
            this.method_595();
        }

        internal function method_677():*
        {
            try {
                this.var_93["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.var_93.emphasized = false;
            this.var_93.enabled = true;
            this.var_93.label = "Send Message";
            this.var_93.labelPlacement = "right";
            this.var_93.selected = false;
            this.var_93.toggle = false;
            this.var_93.visible = true;
            try {
                this.var_93["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_595():*
        {
            try {
                this.var_108["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.var_108.emphasized = false;
            this.var_108.enabled = true;
            this.var_108.label = "Delete All";
            this.var_108.labelPlacement = "right";
            this.var_108.selected = false;
            this.var_108.toggle = false;
            this.var_108.visible = true;
            try {
                this.var_108["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package 

