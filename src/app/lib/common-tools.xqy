xquery version "1.0-ml";

module namespace tools = 'http://marklogic.com/ps/custom/common-tools';

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace invoke = "http://marklogic.com/ps/invoke/functions" at "invoke-functions.xqy";

declare namespace xdmp="http://marklogic.com/xdmp";

declare variable $tools:UUID_VERSION as xs:unsignedLong := 3; 
declare variable $tools:UUID_RESERVED as xs:unsignedLong := 8;

declare option xdmp:update "false";

declare function tools:uniqueID()
as xs:string
{
  fn:string(xdmp:hash64(fn:concat(xdmp:random(100000),fn:string(fn:current-dateTime()),fn:string(xdmp:elapsed-time()))))
};

declare function tools:normalize-integer-to-hex($string as xs:integer, $length as xs:integer)
{
    let $v := xdmp:integer-to-hex($string)
    let $len := fn:string-length($v)
    return
      if ($len eq $length) then $v
      else fn:string-join((for $i in (1 to 3 - $length) return '0', $v),'')
};

declare function tools:namespace-insert($node as node(), $namespace) as node()?
{
  typeswitch($node)
    case $node as element() return
      element { fn:QName($namespace,fn:local-name($node)) } {
        $node/@*,
        for $x in $node/node()
        return tools:namespace-insert($x, $namespace)
      }
    case $node as document-node() return tools:namespace-insert($node/element(), $namespace)
    default return $node
};

declare function tools:node-clone($elements as node()) as element()
{
  for $element in $elements
  return
  typeswitch($element)
  case document-node() return tools:node-clone($element/node())
  case element() return
          element {fn:node-name($element)} {
            $element/@*,
            $element/*
          }
  default return $element
};

declare function tools:get-number-format($num as xs:integer, $type as xs:string) as xs:string
{
    let $roman := ("I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII", "XXIII", "XXIV", "XV", "XVI", "XVII", "XVIII")
    let $alpha := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return
        if ($type = "roman") then
            $roman[$num]
        else if ($type = "lroman") then
            fn:lower-case($roman[$num])
        else if ($type = "alpha") then
            fn:substring($alpha, $num, 1)
        else if ($type = "lalpha") then
            fn:lower-case(fn:substring($alpha, $num, 1))
        else if ($type = "number") then
            $num
        else
            ()
};

declare function tools:element-camel-case($local-name as xs:string?) as xs:string?
{
    if ($local-name) then
        fn:string-join(
            for $i in fn:tokenize($local-name, "-")
            return
                if (fn:string-length($local-name) gt 1) then
                    fn:concat(fn:upper-case(fn:substring($local-name, 1, 1)), fn:substring($local-name, 2, fn:string-length($local-name) - 1))
                else
                    fn:upper-case($local-name)
        , " ")
    else ()
};

declare function tools:randIntSeq(
     $in as xs:integer*, $out as xs:integer*)
{
   if (fn:count($in) eq 0) then $out
   else
     let $r := xdmp:random(fn:count($in))
     return tools:randIntSeq(
       fn:remove($in, $r),
       ($out, $in[$r])
     )
};

declare function tools:randIntSeq($max as xs:integer)
{
   tools:randIntSeq((1 to $max), ())
};

declare function tools:shuffle($seq as item()*)
{
   for $i in tools:randIntSeq(fn:count($seq))
   return $seq[$i]
};

declare function tools:get-date-string($dt as xs:dateTime)
{
  (: TODO: Need fn:date :)
  fn:concat(
    tools:pad-left(fn:day-from-dateTime($dt), '0', 2),
    tools:pad-left(fn:month-from-dateTime($dt), '0', 2),
    fn:year-from-dateTime($dt), "_",
    tools:pad-left(fn:hours-from-dateTime($dt), '0', 2), ":",
    tools:pad-left(fn:minutes-from-dateTime($dt), '0', 2), ":",
    tools:pad-left(fn:substring-before(fn:string(fn:seconds-from-dateTime($dt)), '.'), '0', 2)
  )
};

declare function tools:pad-left($s, $char, $length)
{
  let $s := fn:string($s)
  return
    if (fn:string-length($s) >= $length) then
      $s
    else
      fn:concat(fn:string-join((for $i in 1 to ($length - fn:string-length($s)) return $char), ''), $s)
};

declare function tools:trim($s) 
{
  functx:trim($s)
};

declare function tools:get-random-string($length as xs:long) {
  let $dict := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  let $random-sequence := (
    for $i in (1 to $length)
    return
      fn:substring($dict,xdmp:random(fn:string-length($dict)),1)
  )
  return
    fn:string-join($random-sequence, "")
};

(:~
 : Invokes all kind of node or document update functions in a separate transaction.
 : Needed if the outer query runs in timestamped mode and need to modify data. Some
 : query functions like fn:doc or xdmp:value are also available.
 :
 : @param $function The function name to invoke (document-insert, node-replace, etc.)
 : @param $params An array of parameter from the function.
 : @return same return sequence like the normal function call
 :)
declare function tools:invoke($function as xs:string, $params) {
  tools:invoke($function, $params, ())
};

(:~
 : Invokes all kind of node or document update functions in a separate transaction.
 : Needed if the outer query runs in timestamped mode and need to modify data. Some
 : query functions like fn:doc or xdmp:value are also available.
 :
 : @param $function The function name to invoke (document-insert, node-replace, etc.)
 : @param $params An array of parameter from the function.
 : @param $database The database against the function is executed, default local db
 : @return same return sequence like the normal function call
 :)
declare function tools:invoke($function as xs:string, $params, $database as xs:string?) {

  invoke:invoke(
    $function, 
    "http://marklogic.com/ps/update/functions", 
    "invoke-update-query-functions.xqy", 
    $params, 
    ($function != ("doc","document-get","value")),
    $database
  )
};

(:~
 : Spawns all kind of node or document update functions in a separate transaction.
 : Needed if the outer query runs in timestamped mode and need to modify data. Some
 : query functions like fn:doc or xdmp:value are also available.
 :
 : @param $function The function name to invoke (document-insert, node-replace, etc.)
 : @param $params An array of parameter from the function.
 : @return same return sequence like the normal function call
 :)
declare function tools:spawn($function as xs:string, $params) {
  tools:spawn($function, $params, ())
};

(:~
 : Spawns all kind of node or document update functions in a separate transaction.
 : Needed if the outer query runs in timestamped mode and need to modify data. Some
 : query functions like fn:doc or xdmp:value are also available.
 :
 : @param $function The function name to invoke (document-insert, node-replace, etc.)
 : @param $params An array of parameter from the function.
 : @param $database The database against the function is executed, default local db
 : @return same return sequence like the normal function call
 :)
declare function tools:spawn($function as xs:string, $params, $database as xs:string) {

  invoke:spawn(
    $function, 
    "http://marklogic.com/ps/update/functions", 
    "invoke-update-query-functions.xqy", 
    $params, 
    ($function != ("doc","document-get","value")),
    $database
  )
};

declare function tools:normalize-structure-passthru($x as element()) as node()* {
    for $z in $x/node() return tools:normalize-structure($z)  
};

declare function tools:normalize-structure($x as node()) as node()* 
{
  if (fn:empty($x)) then () else
  typeswitch ($x)
  
  case document-node() return tools:normalize-structure(($x/*[1]))
  case processing-instruction() return ()
  case comment() return ()
  case text() return if (fn:normalize-space($x) != '') then text{fn:normalize-space($x)} else ()
  case element(paragraph) return $x
  case element() return element {fn:QName(fn:namespace-uri($x), fn:local-name($x))} {$x/@*,tools:normalize-structure-passthru($x)}
  default return tools:normalize-structure-passthru($x)
};

declare function tools:who-am-i()
{
try {
let $foo := fn:error(xs:QName("WHO-AM-I"),"I AM") 
 return ()
} catch($ex) {
<callstack>
   <caller>{fn:data($ex/error:stack/error:frame[2]/*:uri)}</caller>
   <calling>{fn:data($ex/error:stack/error:frame[1]/*:uri)}</calling>
</callstack>

}};

declare function tools:function-available($func)
{
  xdmp:eval(fn:concat(
    'import module namespace ns="', fn:namespace-uri-from-QName(xdmp:function-name($func)), '" at "', xdmp:function-module($func), '";', 'fn:function-available("ns:', fn:local-name-from-QName(xdmp:function-name($func)), '")'))
};

declare function tools:random-hex($length as xs:integer) 
as xs:string {
  fn:string-join(
    for $n in 1 to $length
    return xdmp:integer-to-hex(xdmp:random(15)),
    ""
  )
};

declare function tools:generate-uuid-v4() 
as xs:string 
{
  fn:string-join(
    (
      tools:random-hex(8),
      tools:random-hex(4),
      tools:random-hex(4),
      tools:random-hex(4),
      tools:random-hex(12)
    ),
    "-"
  )
};

(: 
 : Calculate the UUID and set the UUID property on the file.
 :
 : The layout of a UUID is as follows. 0 1 2 3 0 1 2 3 4 5 6 7 8 9 a b c d e f 0 1 2 3 4 5 6 7 8 9 a b c d e f +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ | time_low | +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ | time_mid | time_hi |version| +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ |clk_seq_hi |res| clk_seq_low | node (0-1) | +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ | node (2-5) | +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 0 1 2 3 4 5 6 7 8 9 a b c d e f 0 1 2 3 4 5 6 7 8 9 a b c d e f
 : 
 : This implements version 3 of the UUID specification. 
 : The timestamp is a 60-bit value. 
 : The clock sequence is a 14 bit value. 
 : The node is a 48-bit name value. 
 :) 

declare function tools:generate-uuid-v3($uri as xs:string) 
    as xs:string 
{ 
  tools:generate-uuid-v3($uri, xdmp:host-name(xdmp:host())) 
};

declare function tools:generate-uuid-v3($uri as xs:string, $namespace as xs:string) 
    as xs:string 
{ 
  (: calculate md5 with a dateTime for our random values :) 
  let $hash := xdmp:md5(fn:concat($uri, xs:string(fn:current-dateTime()), $namespace)) 
  return 
    fn:concat(
      fn:substring( $hash, 1, 15 ), 
      (: set version bits :) xdmp:integer-to-hex($tools:UUID_VERSION), 
      (: set reserved bits :) fn:substring( $hash, 17, 1 ), 
      xdmp:integer-to-hex((xdmp:hex-to-integer(fn:substring($hash, 18, 1)) idiv 4) + $tools:UUID_RESERVED), 
      fn:substring( $hash, 19, 14 ) 
    )
}; 

(:
 : Parses URL parameters from a URL string. 
 :
 : Doesn't do much error checking. Assumes that '?' delimits 
 : the host and port from the URL params, '&' delimits
 : the params from one another, and '=' delimits the name
 : from the value.
:)
declare function tools:parse-url-params($url as xs:string) as map:map {
    (: Fix URLs that have XML character entity references :)
    let $url := fn:replace($url, '&amp;amp;', '&amp;')
    let $params := fn:tokenize(fn:tokenize($url, "\?")[2], '&amp;')
    let $param-map := map:map()
    let $_ :=   for $param in $params 
                let $param-name := fn:tokenize($param, '=')[1]
                let $param-val := fn:tokenize($param, '=')[2]
                return  if (map:contains($param-map, $param-name)) then 
                            map:put($param-map, $param-name, (map:get($param-map, $param-name), $param-val))
                        else map:put($param-map, $param-name, $param-val)
    return $param-map

};
