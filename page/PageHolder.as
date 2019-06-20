// page.PageHolder = page.class_16

package page
{
    public class PageHolder extends Removable 
    {

        private var currentPage:Page;

        public function PageHolder(p:Page = null)
        {
            if (p != null) {
                this.changePage(p);
            }
        }

        public function changePage(p:Page)
        {
            if (this.currentPage != null) {
                this.currentPage.remove();
                if (this.currentPage.parent != null) {
                    this.currentPage.parent.removeChild(this.currentPage);
                }
            }
            if (p != null) {
                p.initialize();
                addChild(p);
                this.currentPage = p;
            }
        }

        override public function remove()
        {
            if (this.currentPage != null) {
                this.currentPage.remove();
            }
            super.remove();
        }

        // method_656 = getCurrentPage
        public function getCurrentPage():Page
        {
            return this.currentPage;
        }


    }
}
