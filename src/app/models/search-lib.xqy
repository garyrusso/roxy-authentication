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

module namespace m = "http://marklogic.com/roxy/models/search";

import module namespace c = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

import module namespace debug = "http://marklogic.com/debug" at "/MarkLogic/appservices/utils/debug.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace impl = "http://marklogic.com/appservices/search-impl" at "/MarkLogic/appservices/search/search-impl.xqy";

declare option xdmp:mapping "false";

declare function m:search($query as xs:string, $pg as xs:int, $ps)
{
  let $start := ($pg - 1) * $ps + 1
  return
    search:search($query, $c:SEARCH-OPTIONS, $start, $ps)
};

