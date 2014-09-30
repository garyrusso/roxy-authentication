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

module namespace uv = "http://www.marklogic.com/roxy/user-view";

import module namespace form = "http://marklogic.com/roxy/form-lib" at "/app/views/helpers/form-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare function uv:build-user($username, $message, $login-link, $register-link, $logout-link)
{
  let $loggedInUser := xdmp:get-session-field("logged-in-user")
  
  return
    if ($loggedInUser ne "") then
      uv:welcome($loggedInUser, $username, $logout-link)
    else
      uv:build-login($message, $login-link, $register-link)
};

declare function uv:welcome($loggedin, $username, $logout-link)
{
  <div class="user">
    <div class="welcome">Welcome,<a href="{fn:concat("user?edit=", $username)}">{$loggedin}</a>&nbsp;</div>
    <a href="{$logout-link}" class="logout">logout</a>
  </div>
};

declare function uv:build-login($message, $login-link, $register-link)
{
  <div class="user">
    <form action="{$login-link}" method="POST">
      <label>{$message}</label>
      {
        form:text-input("Username:", "username", "username"),
        form:password-input("Password:", "password", "password")
      }
      <input type="submit" value="Login"/>
    </form>
    <a href="{$register-link}">register</a>
  </div>
};

declare function uv:build-register($register-link, $user, $edit)
{
  let $button := if ($edit) then "update" else "register"

  return
    <div class="registeruser">
      <form action="{$register-link}" method="POST">
        {
          form:text-input-readonly("Username:", "username", "registeruser", if ($user) then $user/*:username else ""),
          form:line-break(),
          form:text-input("First Name:", "firstname", "registeruser", if ($user) then $user/*:firstname else ""),
          form:line-break(),
          form:text-input("Last Name:", "lastname", "registeruser", if ($user) then $user/*:lastname else ""),
          form:line-break(),
          form:password-input("Password:", "password", "registeruser", ""),
          form:hidden-input("created", if ($user) then $user/*:created else "")
        }
        <br/>
        <input type="submit" value="{$button}"/>
      </form>
    </div>
};

declare function uv:build-userlist($userlist)
{
  <div class="userlist">
  <table border="1" cellpadding="2" cellspacing="2" width="400">
  {
    for $user at $i in $userlist
      return
        <tr>
          <td align="center" width="20">{$i}</td>
          <td align="left" width="70">{$user/*:username}</td>
          <td align="left" width="140">{fn:concat($user/*:firstname, " ", $user/*:lastname/text())}</td>
          <td align="center" width="40"><a href="?edit={$user/*:username}">edit</a></td>
          <td align="center" width="40"><a onclick="return confirm('About to delete {$user/*:username}: Are you sure?');" href="?delete={$user/*:username}">delete</a></td>
        </tr>
  }
  </table>
  </div>
};
