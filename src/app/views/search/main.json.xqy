xquery version "1.0-ml";

import module namespace vh = "http://marklogic.com/roxy/view-helper" at "/roxy/lib/view-helper.xqy";

import module namespace json = "http://marklogic.com/json" at "/roxy/lib/json.xqy";
import module namespace c    = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace boing  = "http://www.boing.com/feeds"; 
declare namespace xh     = "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare variable $q  := vh:get("q");

declare variable $pg := vh:get("pg");
declare variable $ps := vh:get("ps");

declare variable $response := vh:get("response");

declare variable $TIDY-OPTIONS as element () := <options xmlns="xdmp:tidy">
                                                  <clean>true</clean>
                                                </options>;

declare function local:transform-snippet($nodes as node()*)
{
  for $n in $nodes
  return
    typeswitch($n)
      case element(search:highlight) return
        <span xmlns="http://www.w3.org/1999/xhtml" class="highlight">{fn:data($n)}</span>
      case element() return
        element div
        {
          attribute class { fn:local-name($n) },
          local:transform-snippet(($n/@*, $n/node()))
        }
      default return $n
};

declare function local:convert-to-json($doc, $page, $end, $total-pages, $count, $total)
{
  let $facetInfo :=
          json:o(("facetInfo",
            json:a((
              for $facet in $doc/search:facet
                return
                  json:o((
                    "categoryName", fn:string($facet/@name),
                    "facets",
                      json:a((
                        for $facet-value in $facet/search:facet-value
                          return
                            json:o((
                              "code", fn:string($facet-value/@name),
                              "count", xs:int($facet-value/@count),
                              "name", fn:string($facet-value/text())
                            ))
                          ))
                        ))
                      ))
                    ))

  let $resultsJson :=
          json:o(("results",
            json:a((
            for $result in $doc/search:result
              return
              (
                json:o((
                  "index",             xs:int($result/@index),
                  "relevance",         fn:string($result/@confidence * 100),
                  "permalink",         $result/boing:permalink/text(),
                  "author",            $result/boing:author/text(),
                  "created_on",        $result/boing:created_on/text(),
                  "title",             $result/boing:title/text(),
                  "comment_count",     $result/boing:comment_count/text(),
                  "body",              fn:normalize-space(fn:data(xdmp:tidy($result//boing:body/text(),$TIDY-OPTIONS)[2]/xh:html/xh:body)),
                  "snippet",
                  for $match in $result/search:snippet/search:match
                    return
                      json:o((
                        "highLights",
                        json:a((
                          for $highlight in $match/search:highlight
                            return
                              $highlight/text()
                          )),
                        "snippetText", fn:string(fn:normalize-space(fn:data($match)))
                      ))
                ))
              )
            ))
          ))

  let $paginationInfo :=
          json:o(("paginationInfo",
            json:o((
              "start", xs:int($doc/@start),
              "end", xs:int($end),
              "page", xs:int($page),
              "pageLength", xs:int($doc/@page-length),
              "totalPages", xs:int($total-pages),
              "total", xs:int($doc/@total),
              "qtext", fn:string($doc/search:qtext)
            ))
          ))

  let $pagination1 := json:serialize($paginationInfo)
  let $pagination2 := fn:substring($pagination1, 1, fn:string-length($pagination1)-1)
  
  let $facets1 := json:serialize($facetInfo)
  let $facets2 := fn:concat(fn:substring($facets1, 2, fn:string-length($facets1)-2))

  let $results1 := json:serialize($resultsJson)
  let $results2 := fn:concat(fn:substring($results1, 2, fn:string-length($results1)-2))

  let $avdoc := fn:concat($pagination2, ",", $facets2, ",", $results2, "}")

  let $jdoc :=
    fn:concat("srCallback(", $avdoc, ")")

  return $jdoc
};

declare function local:get-search-results()
{
  let $count := fn:count($response/search:result)
  let $total := fn:string($response/@total)
  
  let $pagesize    := if ($ps eq 0) then $c:DEFAULT-PAGE-LENGTH else $ps
  let $page        := (($response/@start - 1) div ($pagesize) + 1)
  let $end         := fn:string(fn:min(($response/@start + $response/@page-length - 1, $response/@total)))
  let $total-pages := fn:ceiling($response/@total div ($pagesize))

  let $jdoc := local:convert-to-json($response, $page, $end, $total-pages, $count, $total)

  return $jdoc
};

let $doc :=
  if ($q eq "") then
    "Search string is missing." 
  else
    local:get-search-results()

return $doc
