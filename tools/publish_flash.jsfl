var ROOT_URI = "file:///Users/jacobgrahn/Documents/platform-racing-2-client";
var SOURCE_FLA_URI = ROOT_URI + "/flash/platform-racing-2.fla";
var STATUS_URI = ROOT_URI + "/test/output/flash-publish-status.txt";

function writeStatus(message) {
	FLfile.createFolder(ROOT_URI + "/test/output");
	FLfile.write(STATUS_URI, message);
	fl.trace("[PR2 Publish] " + message);
}

function run() {
	writeStatus("opening " + SOURCE_FLA_URI);
	var doc = fl.openDocument(SOURCE_FLA_URI);
	if (!doc) {
		throw new Error("Could not open source FLA: " + SOURCE_FLA_URI);
	}
	fl.setActiveWindow(doc);
	writeStatus("publishing");
	doc.publish();
	writeStatus("published");
}

try {
	run();
} catch (error) {
	var message = error && error.message ? error.message : String(error);
	writeStatus("ERROR: " + message);
	throw error;
} finally {
	try {
		fl.closeDocument(fl.getDocumentDOM(), false);
	} catch (closeError) {
	}
	try {
		fl.quit(false);
	} catch (quitError) {
	}
}
