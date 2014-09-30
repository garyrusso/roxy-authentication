(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)
xquery version "1.0-ml";

module namespace router = "http://marklogic.com/roxy/router";

import module namespace ch     = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace config = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";
import module namespace def    = "http://marklogic.com/roxy/defaults" at "/roxy/config/defaults.xqy";
import module namespace req    = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace rh     = "http://marklogic.com/roxy/routing-helper" at "/roxy/lib/routing-helper.xqy";
import module namespace u      = "http://marklogic.com/roxy/util" at "/roxy/lib/util.xqy";
import module namespace auth   = "http://marklogic.com/roxy/models/authentication" at "/app/models/authentication.xqy";

declare option xdmp:mapping "false";

declare variable $controller as xs:QName := req:get("controller", "type=xs:QName");
declare variable $controller-path as xs:string := fn:concat("/app/controllers/", $controller, ".xqy");
declare variable $func as xs:string := req:get("func", "main", "type=xs:string");

declare variable $login-controller-path as xs:string := "/app/controllers/login.xqy";

declare variable $default-format :=
(
	$config:ROXY-OPTIONS/*:default-format,
	$def:ROXY-OPTIONS/*:default-format
)[1];
declare variable $format as xs:string := req:get("format", $default-format, "type=xs:string");
declare variable $default-view as xs:string := fn:concat($controller, "/", $func);

(: assume no default layout for xml, json, text :)
declare variable $default-layout as xs:string? :=
(
	$config:ROXY-OPTIONS/*:layouts/*:layout[@format = $format],
	$def:ROXY-OPTIONS/*:layouts/*:layout[@format = $format]
)[1];

declare function router:route()
{
  (: add HTTP header information to the request parameter object :)
	let $_ := (
	      map:put(
	        $req:request, 
	        "req-header",
          element header {
            for $header in xdmp:get-request-header-names()
             return
              element {fn:lower-case($header)} {
                xdmp:get-request-header($header)
              }
          }
	      ),
	      if (fn:exists(xdmp:get-request-body())) then
	        map:put(
          $req:request, 
          "req-body",
          if (xdmp:get-request-body()/node() instance of element()) then
            xdmp:get-request-body()/node()
          else if (xdmp:get-request-body()/node() instance of text()) then
            xdmp:quote(xdmp:get-request-body()/node())
          else ()
          ) 
	      else (),
	      router:set-format()
	      )

	(: Checks authentication before executing the request :) 	
	let $valid-request := if(fn:not($config:SESSION-AUTHENTICATE)) then fn:true() 
	                      else if(xs:string($controller) = ("ping")) then fn:true()
	                      else if(xs:string($controller) = ("login")) then fn:true()
	                      else if(xs:string($controller) = ("logout")) then fn:true()
	                      else if(xs:string($controller) = ("verify")) then fn:true()
	                              else (
	                                  let $token := xdmp:get-request-header("X-Auth-Token")
	                                  return if($token) then (
	                                    let $valid-session := auth:findSessionByToken($token)
	                                    return if($valid-session) then ( 
	                                        fn:true(),
	                                        auth:cacheSession($valid-session)
	                                    ) else fn:false()
	                                  )
	                                  else fn:false()
	                              )

  (: run the controller. errors bubble up to the error module :)
	 let $data := if($valid-request) then (
            xdmp:apply(
                    xdmp:function(
                        fn:QName(fn:concat("http://marklogic.com/roxy/controller/", $controller), $func),
                        $controller-path)) )	                            	 
        	 else (
        	   xdmp:apply(
                        xdmp:function(
                            fn:QName(fn:concat("http://marklogic.com/roxy/controller/login"), "login-error"),
                            $login-controller-path))         	    
        	    )


	(: Roxy options :)
	let $options :=
	  for $key in map:keys($ch:map)
	  where fn:starts-with($key, "ch:config-")
	  return
	    map:get($ch:map, $key)

	(: remove options from the data :)
	let $_ :=
	  for $key in map:keys($ch:map)
	    where fn:starts-with($key, "ch:config-")
	    return
	    map:delete($ch:map, $key)

	let $format as xs:string := ($options[self::ch:config-format][ch:formats/ch:format = $format]/ch:format, $format)[1]
	let $_ := (
	      for $header in map:get($ch:map, "res-header")/* return xdmp:add-response-header(fn:local-name($header), $header/fn:string()),
	      xdmp:set-response-code((map:get($ch:map, "res-code"), 200)[1],(map:get($ch:map, "res-message"), "OK")[1]) 
	      )

	(: controller override of the view :)
	let $view := ($options[self::ch:config-view][ch:formats/ch:format = $format]/ch:view, $default-view)[1][. ne ""]


	(: controller override of the layout :)
	let $layout :=
	  if (fn:exists($options[self::ch:config-layout][ch:formats/ch:format = $format])) then
	    $options[self::ch:config-layout][ch:formats/ch:format = $format]/ch:layout[. ne ""]
	  else
	    $default-layout


	(: if the view return something other than the map or () then bypass the view and layout :)
	let $bypass as xs:boolean := fn:exists($data) and fn:not($data instance of map:map)


	return
	  if (fn:not($bypass) and (fn:exists($view) or fn:exists($layout))) then
	    let $view-result :=
	      if (fn:exists($ch:map) and fn:exists($view)) then
	        rh:render-view($view, $format, $ch:map)
	      else
	        ()
	    return
	      if (fn:not($bypass) and fn:exists($layout)) then
	        let $_ :=
	          if (fn:exists($view-result) and
	          		fn:not($view-result instance of map:map) and
	          		fn:not(fn:deep-equal(document {$ch:map}, document {$view-result}))) then
	            map:put($ch:map, "view", $view-result)
	          else
	            map:put($ch:map, "view",
	              for $key in map:keys($ch:map)
	              return
	                map:get($ch:map, $key))
	        return
	          rh:render-layout($layout, $format, $ch:map)
	      else
	        $view-result
	  else if (fn:not($bypass)) then
	    for $key in map:keys($ch:map)
	    return
	      map:get($ch:map, $key)
	  else
	    $data
};

declare function router:set-format()
{
  if (map:get($req:request,"format") = ($ch:ALL-FORMATS, "atom","docx")) then ()
  else if (map:get($req:request,"req-header")/content-type = "application/xml") then
    map:put($req:request,"format","xml")
  else if (map:get($req:request,"req-header")/content-type = "application/json") then
    map:put($req:request,"format","json")
  else if (map:get($req:request,"req-header")/content-type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document") then
    map:put($req:request,"format","docx")
  else
    map:put($req:request,"format","xml") 
};