xquery version "1.0-ml";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";
import module namespace uv = "http://www.marklogic.com/roxy/user-view" at "/app/views/helpers/user-lib.xqy";

declare option xdmp:mapping "false";

declare variable $q as xs:string? := vh:get("q");
declare variable $page as xs:int  := vh:get("page");
declare variable $message         := vh:get("message");
declare variable $userlist        := vh:get("userlist");
declare variable $edit            := vh:get("edit");
declare variable $user            := vh:get("user");

'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Register User</title>
    <link href="/css/themes/ui-lightness/jquery-ui.css" type="text/css" rel="stylesheet"/>
    <link href="/css/two-column.less" type="text/css" rel="stylesheet/less"/>
    <link href="/css/app.less" type="text/css" rel="stylesheet/less"/>
    <script src="/js/lib/less-1.3.0.min.js" type='text/javascript'></script>
    <script src="/js/lib/jquery-1.7.1.min.js" type='text/javascript'></script>
    <script src="/js/lib/jquery-ui-1.8.18.min.js" type='text/javascript'></script>
    <script src="/js/two-column.js" type='text/javascript'></script>
    <script src="/js/app.js" type='text/javascript'></script>
    { vh:get("additional-js") }
  </head>
  <body>
    <div class="home" id="home">
      <a class="text" href="/" title="Home">My Application</a>
    </div>
    <div class="home">
      <table border="0"><tr><td width="270">{$message}</td><td><a href="?reset">reset</a></td></tr></table>
      <br/>
      <table border="0">
        <tr>
          <td width="350" valign="top">{uv:build-register("/user", $user, $edit) }</td>
          <td width="350" valign="top">{ uv:build-userlist($userlist) }</td>
        </tr>
      </table>
    </div>
  </body>
</html>
