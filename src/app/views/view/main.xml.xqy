xquery version "1.0-ml";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";

declare option xdmp:mapping "false";

declare variable $uri := vh:get("uri");

let $url := xdmp:url-decode($uri)

let $doc :=
  if ($uri eq "") then
    <document>uri parameter is missing.</document>
  else
  (
    if (fn:doc($url)) then fn:doc($url) else <document>uri is not valid.</document>
  )

return
  (xdmp:set-response-content-type("text/xml; charset=utf-8"), $doc)

