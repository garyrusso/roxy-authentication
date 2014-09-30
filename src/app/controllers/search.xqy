xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/search";

import module namespace ch  = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace cfg = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace s   = "http://marklogic.com/roxy/models/search" at "/app/models/search-lib.xqy";

declare option xdmp:mapping "false";

declare function c:main() as item()*
{
  let $q     := req:get("q", "", "type=xs:string")
  let $pg    := req:get("pg", 1, "type=xs:int")
  let $ps    := req:get("ps", $cfg:DEFAULT-PAGE-LENGTH, "type=xs:int")

  return
  (
    ch:add-value("response", s:search($q, $pg, $ps)),
    ch:add-value("q", $q),
    ch:add-value("pg", $pg),
    ch:add-value("ps", $ps),
    ch:use-view((), "xml"),
	  ch:use-layout(())
  )
};
