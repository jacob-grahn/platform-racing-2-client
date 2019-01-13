// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//TestCourseGraphic

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

    public dynamic class TestCourseGraphic extends MovieClip 
    {

        public var var_81:Button;
        public var var_92:Button;

        public function TestCourseGraphic()
        {
            this.method_520();
            this.method_749();
        }

        internal function method_520():*
        {
            try {
                this.var_81["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.var_81.emphasized = false;
            this.var_81.enabled = true;
            this.var_81.label = "Back";
            this.var_81.labelPlacement = "right";
            this.var_81.selected = false;
            this.var_81.toggle = false;
            this.var_81.visible = true;
            try {
                this.var_81["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_749():*
        {
            try {
                this.var_92["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.var_92.emphasized = false;
            this.var_92.enabled = true;
            this.var_92.label = "Restart";
            this.var_92.labelPlacement = "right";
            this.var_92.selected = false;
            this.var_92.toggle = false;
            this.var_92.visible = true;
            try {
                this.var_92["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package 

