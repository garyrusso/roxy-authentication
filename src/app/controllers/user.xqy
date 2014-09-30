xquery version "1.0-ml";

module namespace c = "http://marklogic.com/roxy/controller/user";

import module namespace ch    = "http://marklogic.com/roxy/controller-helper" at "/roxy/lib/controller-helper.xqy";
import module namespace req   = "http://marklogic.com/roxy/request" at "/roxy/lib/request.xqy";
import module namespace error = "http://marklogic.com/roxy/error-lib" at "../views/helpers/error-lib.xqy";
import module namespace usr   = "http://marklogic.com/roxy/models/user" at "/app/models/user-model.xqy";
import module namespace auth  = "http://marklogic.com/roxy/models/authentication" at "/app/models/authentication.xqy";

import module namespace json   = "http://marklogic.com/json" at "/roxy/lib/json.xqy";

import module namespace cfg    = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

declare option xdmp:mapping "false";
 

(:
 :
 : Default function that is returns an error message.
 : 
 :)
declare function c:main() as item()*
{
  let $q        := req:get("q", "", "type=xs:string")
  let $delete   := req:get("delete", "", "type=xs:string")
  let $edit     := req:get("edit", "", "type=xs:string")
  let $reset    := req:get("reset", "", "type=xs:string")
  let $pg       := req:get("pg", 1, "type=xs:int")
  let $ps       := req:get("ps", $cfg:DEFAULT-PAGE-LENGTH, "type=xs:int")
  let $loggedin := req:get("loggedin", "", "type=xs:string")

  let $user  := 
    if ($edit ne "") then
      usr:get($edit)
    else
      element user-profile
      {
        element firstname { fn:normalize-space(req:get("firstname", "", "type=xs:string")) }, 
        element lastname  { fn:normalize-space(req:get("lastname", "", "type=xs:string")) }, 
        element username  { fn:normalize-space(req:get("username", "", "type=xs:string")) }, 
        element password  { fn:normalize-space(req:get("password", "", "type=xs:string")) },
        element created   { fn:normalize-space(req:get("created", "", "type=xs:string")) }
      }

  let $message := 
    if ($edit ne "") then
    (
      if (($user/firstname eq "") or ($user/lastname eq "") or ($user/username eq "") or ($user/password eq "")) then
        "Please fill in all fields."
      else
        "Press update button to save."
    )
    else
    if ($delete ne "") then
      usr:delete($delete)
    else
    (
      if (($user/firstname eq "") or ($user/lastname eq "") or ($user/username eq "") or ($user/password eq "")) then
        "Please fill in all fields."
      else
        usr:save($user)
    )

  let $edituser := if (($reset ne "") or (fn:starts-with($message, "User Success"))) then () else $user
  let $userlist := usr:getUserList()

  return
  (
    ch:add-value("message", $message),
    ch:add-value("userlist", $userlist),
    ch:add-value("q", $q),
    ch:add-value("pg", $pg),
    ch:add-value("ps", $ps),
    ch:add-value("edit", $edit),
    ch:add-value("user", $edituser),
    ch:use-view((), "xml"),
	  ch:use-layout(())
  )
};

declare function c:update() as item()*
{
  ()
};

