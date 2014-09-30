xquery version "1.0-ml";

import module namespace vh   = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace json = "http://marklogic.com/json" at "/roxy/lib/json.xqy";

declare option xdmp:mapping "false";

declare variable $result := vh:get("result");

json:serialize(
      $result
)
