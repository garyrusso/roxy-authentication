xquery version "1.0-ml";

module namespace invoke = "http://marklogic.com/ps/invoke/functions";

import module namespace tools = 'http://marklogic.com/ps/custom/common-tools' at 'common-tools.xqy';


declare option xdmp:update "false";

declare function invoke:get-database-id($database as xs:string?)
{
  let $db-name := ($database,xdmp:database-name(xdmp:database()))[1]
  return
      let $check-db := try {xdmp:database($db-name)} catch ($e) {$e}  
      return
        if ($check-db instance of xs:unsignedLong) then $check-db
        else fn:error((),"INVOKE-INVALIDDB",$database)
};

declare function invoke:get-params($params as item()*)
{
  element params {
    if ($params[1] instance of node() and fn:base-uri($params[1]) != '') then (
      element text {xdmp:describe($params[1],(),())},
      for $item in $params[2 to fn:last()] return if ($item instance of xs:string) then element text {$item} else $item
    ) else
      for $item in $params return if ($item instance of xs:string) then element text {$item} else $item
  }
};

declare function invoke:execute($function-namespace as xs:string, $function-name as xs:string, $function-uri as xs:string, $params as element(params))
as item()*
{
let $function := xdmp:function(fn:QName($function-namespace, $function-name), $function-uri)
let $strapply := fn:concat(
      "xdmp:apply(",
      "$function,",
      fn:string-join(for $item at $pos in $params/node() return fn:concat("$params/node()[", $pos ,"]", if ($item instance of element(text)) then "/text()" else ()), ","),
      ")"
      )
where fn:exists($params/node())
return
  if (tools:function-available($function)) then
    xdmp:value($strapply)
  else
    fn:error((),fn:concat("Function doesn't exists: " , $function), ())
};

(:~
 : Invokes any kind of modules in a separate transaction. A separate transaction is
 : needed if the outer query runs in timestamped mode and need to modify data or query
 : for latest database changes. 
 :
 : @param $function The function name to invoke
 : @param $namespace The namespace of the function to invoke
 : @param $module-uri The uri where the module of the function is located
 : @param $params An array of parameter from the function.
 : @param $isUpdate Flag to run the invoke in query or update mode
 : @param $database The database against the function is executed, default local db
 : @return same return sequence of the function call
 :)
declare function invoke:invoke($function as xs:string, $namespace as xs:string, $module-uri as xs:string, $params as item()*, $isUpdate as xs:boolean, $database as xs:string?) {
  xdmp:invoke(
    if ($isUpdate) then "invoke-update.xqy" else "invoke-query.xqy", 
    (
      xs:QName("FUNCTION"), $function, 
      xs:QName("NAMESPACE"), $namespace, 
      xs:QName("MODULE-URI"), $module-uri, 
      xs:QName("PARAMS"), invoke:get-params($params) 
    ),
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation> 
      <prevent-deadlocks>true</prevent-deadlocks>
      <database>{invoke:get-database-id($database)}</database>
    </options>
  )
};

(:~
 : Spawns any kind of modules as a task to the task server. If a result of a query
 : is needed and can be executed independend this may be an option for execution.
 :
 : @param $function The function name to invoke
 : @param $namespace The namespace of the function to invoke
 : @param $module-uri The uri where the module of the function is located
 : @param $params An array of parameter from the function.
 : @param $isUpdate Flag to run the invoke in query or update mode
 : @param $database The database against the function is executed, default local db
 : @return empty sequence
 :)
declare function invoke:spawn($function as xs:string, $namespace as xs:string, $module-uri as xs:string, $params as item()*, $isUpdate as xs:boolean, $database as xs:string?) 
{
  xdmp:spawn(
    if ($isUpdate) then "invoke-update.xqy" else "invoke-query.xqy", 
    (
      xs:QName("FUNCTION"), $function, 
      xs:QName("NAMESPACE"), $namespace, 
      xs:QName("MODULE-URI"), $module-uri, 
      xs:QName("PARAMS"), invoke:get-params($params) 
    ),
    <options xmlns="xdmp:eval">
      <database>{invoke:get-database-id( $database)}</database>
    </options>
  )
};