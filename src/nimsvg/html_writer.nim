import strutils
import strformat

import utils


const htmlTemplate = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>NimSvg Animation</title>
  <style>
  .frame > svg {
    border: 1px solid #EFEFEF;
  }
  </style>
</head>

<body>
BODY

<script>
var numFrames = NUM_FRAMES;
var curr = numFrames - 1;
var prev = curr;

function render() {
  curr = (curr + 1) % numFrames;
  let divElPrev = document.getElementById("frame" + prev);
  let divElCurr = document.getElementById("frame" + curr);
  divElPrev.style.display = "none";
  divElCurr.style.display = null;
  prev = curr;

  window.requestAnimationFrame(render);
}

window.requestAnimationFrame(render);

</script>

</body>
</html>
"""

type
  HtmlWriter* = object
    svgs: seq[string]

proc addFrame*(self: var HtmlWriter, svgCode: string) =
  # strip doctype, only start at svg tag
  var svgCode = svgCode
  let startOffset = svgCode.find("<svg")
  if startOffset >= 0:
    svgCode = svgCode[startOffset .. ^1]

  self.svgs.add(svgCode)


proc writeHtml*(self: HtmlWriter, filename: string) =
  var body = ""
  for i, svg in self.svgs:
    body &= &"<div id=\"frame{i}\" class=\"frame\" style=\"display:none;\">\n"
    body &= "  " & svg
    body &= "</div>\n"
  withFile(f, filename):
    f.write(htmlTemplate.replace("BODY", body).replace("NUM_FRAMES", $len(self.svgs)))
