var page = new WebPage(),
    address, output, class_id, extrao;
    
if (phantom.args.length < 2 || phantom.args.length > 4) {
    console.log('Usage: screenshot.js http://site.it/page /path/to/out.png [id] [extraOffsetJson]');
    phantom.exit();
}

address = phantom.args[0];
output = phantom.args[1];
class_id = false;
extrao = JSON.parse("{}");

if(typeof phantom.args[2] != "undefined")
	class_id = phantom.args[2];

if(typeof phantom.args[3] != "undefined")
	extrao = JSON.parse(phantom.args[3]);

console.log(JSON.stringify(extrao));

dim = new Array('top','left','width','height');

for (i in dim)
	if (typeof extrao[dim[i]] == "undefined" )
		extrao[dim[i]] = 0;

console.log(JSON.stringify(extrao));

page.viewportSize = { width: 1024, height: 768 };

console.log("Downloading..");

page.settings.loadImages = false;

page.open(address,function (status){
	console.log("Status: "+status);
	if(status !== "success")
		phantom.exit();
	console.log("Screenshooting -> "+output+" (png)");
	window.setTimeout(function(){
		var render = true;
		if (class_id){
			console.log("ID -> "+class_id);
			var rect = page.evaluate(function(class_id,extrao){
				var tmp = document.getElementById(class_id);
				var tor = {
					top: tmp.offsetTop+extrao.top,
					left: tmp.offsetLeft+extrao.left,
					width: tmp.offsetWidth+extrao.width,
					height: tmp.offsetHeight+extrao.height
				};
				return tor;
			},class_id,extrao);
			console.log(JSON.stringify(rect));
			if(rect == null)
				render = false;
			page.clipRect = rect;
		}
		console.log("Writing: "+output);
		if (render)
			page.render(output);
		else
			console.log("--Error--");
		console.log("Done.");
		phantom.exit();
	},200);
});
