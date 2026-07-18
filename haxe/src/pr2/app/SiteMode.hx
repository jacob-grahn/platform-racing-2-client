package pr2.app;

import StringTools;

class SiteMode {
	public static inline var KONGREGATE:String = "kongregate";
	public static inline var INXILE:String = "inXile";

	public static function fromUrl(url:Null<String>):String {
		return fromDomain(domainFromUrl(url));
	}

	public static function fromDomain(domain:Null<String>):String {
		var site = domain == null || domain == "" ? "local" : domain.toLowerCase();
		if (site.indexOf("www.") == 0) {
			site = site.substr(4);
		}
		if (site.indexOf("sparkworkz.com") != -1 || site.indexOf("inxile-entertainment.com") != -1) {
			return INXILE;
		}
		return KONGREGATE;
	}

	public static function domainFromUrl(url:Null<String>):String {
		if (url == null || StringTools.trim(url) == "") {
			return "local";
		}
		var protocolEnd = url.indexOf(":");
		var protocol = protocolEnd < 0 ? "" : url.substr(0, protocolEnd).toLowerCase();
		if (protocol != "http" && protocol != "https") {
			return "local";
		}
		var hostStart = url.indexOf("//");
		if (hostStart < 0) {
			return "local";
		}
		hostStart += 2;
		var hostEnd = url.indexOf("/", hostStart);
		var host = hostEnd < 0 ? url.substr(hostStart) : url.substr(hostStart, hostEnd - hostStart);
		host = host.toLowerCase();
		if (host.indexOf("www.") == 0) {
			host = host.substr(4);
		}
		return host == "" ? "local" : host;
	}

	private function new() {}
}
