// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//ModeMenuGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.ComboBox;
    import fl.data.SimpleCollectionItem;
    import fl.data.DataProvider;

    public dynamic class ModeMenuGraphic extends MovieClip 
    {

        public var var_131:ComboBox;

        public function ModeMenuGraphic()
        {
            this.method_546();
        }

        internal function method_546():*
        {
            var _local_2:SimpleCollectionItem;
            var _local_3:Array;
            var _local_4:Object;
            var _local_5:int;
            var _local_6:*;
            try {
                this.var_131["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            var _local_1:DataProvider = new DataProvider();
            _local_3 = [{
                "label":"Race",
                "data":"race"
            }, {
                "label":"Deathmatch",
                "data":"deathmatch"
            }, {
                "label":"Alien Eggs",
                "data":"egg"
            }, {
                "label":"Objective",
                "data":"objective"
            }];
            _local_5 = 0;
            while (_local_5 < _local_3.length) {
                _local_2 = new SimpleCollectionItem();
                _local_4 = _local_3[_local_5];
                for (_local_6 in _local_4) {
                    _local_2[_local_6] = _local_4[_local_6];
                }
                _local_1.addItem(_local_2);
                _local_5++;
            }
            this.var_131.dataProvider = _local_1;
            this.var_131.editable = false;
            this.var_131.enabled = true;
            this.var_131.prompt = "";
            this.var_131.restrict = "";
            this.var_131.rowCount = 5;
            this.var_131.visible = true;
            try {
                this.var_131["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package 

