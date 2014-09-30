xquery version "1.0-ml";

module namespace error = "http://marklogic.com/roxy/error-lib";

(: the controller helper library provides methods to control which view and template get rendered :)
import module namespace ch = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";

(: The request library provides awesome helper methods to abstract get-request-field :)
import module namespace req = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";

(:
 :
 : Error handler function that takes a result XML structure as input and creates
 : error header information.
 : 
 : @param $result XML result that contains the error details
 :)
declare function error:error-handling( $result as element(result))
{
  error:error-handling( xs:unsignedInt(($result/code, 500)[1]), $result/error/fn:string())
};

(:
 :
 : Error handler function that creates error header information from given input
 : parameter.
 : 
 : @param $err-num HTTP error number
 : @param $err-num HTTP error message
 :)
declare function error:error-handling( $err-num as xs:unsignedInt, $err-msg as xs:string)
{
    ch:add-value("res-code", $err-num),
    ch:add-value("res-message", $err-msg),
    map:put($req:request,"format","xml"),
    ch:use-view("general/error", "xml")
};
