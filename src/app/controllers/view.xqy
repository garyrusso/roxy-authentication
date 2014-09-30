xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/view";

import module namespace ch = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";

declare option xdmp:mapping "false";

declare function c:main() as item()*
{
  let $uri as xs:string := req:get("uri", "", "type=xs:string")
  return
  (
    ch:add-value("uri", $uri)
  )
};
