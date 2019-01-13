// SearchGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.ComboBox;
    import fl.controls.TextInput;
    import fl.controls.Button;
    import fl.data.SimpleCollectionItem;
    import fl.data.DataProvider;

    public dynamic class SearchGraphic extends MovieClip 
    {

        public var mode_cb:ComboBox; // var_44
        public var order_cb:ComboBox; // var_59
        public var dir_cb:ComboBox; // var_51
        public var searchBox:TextInput; // var_50
        public var search_bt:Button; // var_85

        public function SearchGraphic()
        {
            this.mode_cb.addItem({"label":"User Name","data":"user"});
            this.mode_cb.addItem({"label":"Course Title","data":"title"});
            this.order_cb.addItem({"label":"Date","data":"date"});
            this.order_cb.addItem({"label":"Alphabetical","data":"alphabetical"});
            this.order_cb.addItem({"label":"Rating","data":"rating"});
            this.order_cb.addItem({"label":"Popularity","data":"popularity"});
            this.dir_cb.addItem({"label":"Descending","data":"desc"});
            this.dir_cb.addItem({"label":"Ascending","data":"asc"});
            this.search_bt.label = "Search";
            this.searchBox.maxChars = 50;
        }


    }
}
