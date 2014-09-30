xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/ping";

import module namespace ch    = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req   = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace error = "http://marklogic.com/roxy/error-lib" at "../views/helpers/error-lib.xqy";

declare namespace json   = "http://marklogic.com/json";

declare option xdmp:mapping "false";

declare variable $RES-TYPE as xs:string := "Ping";
declare variable $RES-PREFIX as xs:string := "PING";

declare function c:main() as item()*
{
  let $result   := 
             <json:object type="object">
                <json:responseCode>200</json:responseCode>
                <json:message>Ping successful</json:message>
             </json:object>


  return
  (
    ch:add-value("res-code", xs:int($result/json:responseCode) ),
    ch:add-value("res-message", xs:string($result/json:message) ),
    ch:add-value("result",  $result),
    ch:add-value(
            "res-header", 
            element header {
              element Date {fn:current-dateTime()},
              element Content-Type {req:get("req-header")/content-type/fn:string()}
            }
          )
  )
};

