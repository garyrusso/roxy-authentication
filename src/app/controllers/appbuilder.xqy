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

module namespace c = "http://marklogic.com/roxy/controller/appbuilder";

import module namespace ch   = "http://marklogic.com/roxy/controller-helper"     at "/roxy/lib/controller-helper.xqy";
import module namespace req  = "http://marklogic.com/roxy/request"               at "/roxy/lib/request.xqy";
import module namespace s    = "http://marklogic.com/roxy/models/search"         at "/app/models/search-lib.xqy";
import module namespace cfg  = "http://marklogic.com/roxy/config"                at "/app/config/config.xqy";
import module namespace auth = "http://marklogic.com/roxy/models/authentication" at "/app/models/authentication.xqy";

declare option xdmp:mapping "false";

(:
 : Usage Notes:
 :
 : use the ch library to pass variables to the view
 :
 : use the request (req) library to get access to request parameters easily
 :
 :)
declare function c:main() as item()*
{
  let $q as xs:string := req:get("q", "", "type=xs:string")
  let $pg       := req:get("page", 1, "type=xs:int")
  let $ps       := req:get("ps", $cfg:DEFAULT-PAGE-LENGTH, "type=xs:int")
  let $username := req:get("username", "", "type=xs:string")
  let $password := req:get("password", "", "type=xs:string")
  let $login    := req:get("login", "", "type=xs:string")
  let $logout   := req:get("logout", "", "type=xs:string")
  let $loggedin :=
    if ($logout eq "1") then
      xdmp:set-session-field("logged-in-user", "")
    else
      xdmp:get-session-field("logged-in-user")

  let $message :=
      if ($loggedin ne "") then $loggedin
      else
      if ($login eq "1") then
      (
        if (($username eq "") or ($password eq "")) then
          "Invalid: please provide username and password."
        else
          auth:weblogin($username,$password)/fullName/text()
      )
      else ""

  return
  (
    ch:add-value("response", s:search($q, $pg, $ps)),
    ch:add-value("q", $q),
    ch:add-value("page", $pg),
    ch:add-value("username", $username),
    ch:add-value("message", $message),
    ch:add-value("loggedin", $loggedin)
  ),
  ch:use-view((), "xml"),
  ch:use-layout((), "xml")
};
