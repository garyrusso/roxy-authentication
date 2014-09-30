xquery version "1.0-ml";

module namespace userlib = "http://marklogic.com/roxy/lib/profile/user";

import module namespace usr   = "http://marklogic.com/roxy/models/user" at "/app/models/user-model.xqy";

declare option xdmp:mapping "false";


declare function userlib:_save($user)
{
  let $uri := usr:getUserUri($user/username/fn:string())

  let $cmd :=
        fn:concat
        (
          'declare variable $uri external;
           declare variable $user external;
           xdmp:document-insert($uri, $user)'
        )
  return
    xdmp:eval
    (
      $cmd,
      (xs:QName("uri"), $uri, xs:QName("user"), $user)
    )
};


