xquery version "1.0-ml";

module namespace trans = "http://www.marklogic.com/roxy/snippet-lib";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace boing = "http://www.boing.com/feeds"; 
declare namespace xh    = "http://www.w3.org/1999/xhtml";

import module namespace snip = "http://marklogic.com/appservices/search-snippet" at "/MarkLogic/appservices/search/snippet.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $NS := "http://www.boing.com/feeds";

declare variable $TIDY-OPTIONS as element () := <options xmlns="xdmp:tidy">
                                                  <escape-cdata>true</escape-cdata>
                                                  <clean>true</clean>
                                                  <drop-proprietary-attributes>true</drop-proprietary-attributes>
                                                </options>;

declare function trans:boing-snippet(
   $result as node(),
   $ctsquery as schema-element(cts:query),
   $options as element(search:transform-results)?
)
{
  element {fn:QName($NS,"permalink")}     {$result//boing:permalink/text()},
  element {fn:QName($NS,"created_on")}    {$result//boing:created_on/text()},
  element {fn:QName($NS,"basename")}      {$result//boing:basename/text()},
  element {fn:QName($NS,"author")}        {$result//boing:author/text()},
  element {fn:QName($NS,"title")}         {$result//boing:title/text()},
  element {fn:QName($NS,"body")}          {fn:normalize-space(fn:data(xdmp:tidy($result//boing:body/text(),$TIDY-OPTIONS)[2]/xh:html/xh:body))},
  element {fn:QName($NS,"body_more")}     {$result//boing:body_more/text()},
  element {fn:QName($NS,"comment_count")} {$result//boing:comment_count/text()},
  element {fn:QName($NS,"categories")}    {$result//boing:categories/text()},
  snip:do-snippet($result, $ctsquery, $options)
};

