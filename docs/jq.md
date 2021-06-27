# jq

## Default value

    % echo '{"name": "Tom"}' | jq -r '.name // "World"'
    Tom

    % echo '{}' | jq -r '.name // "World"'
    World

## Attach new value

    % echo '{}' | jq '. += { "new_key": 0 }'
    {
      "new_key": 0
    }

## JQ arguments _(base on above)_

    % echo '{}' | jq --arg avar 42 '. += {"a": $avar}'                                                                                                                 !3359
    {
      "a": "42"
    }


## conversion to number _(base on above)_

    % echo '{}' | jq --arg avar 42 '. += {"a": $avar | tonumber}'                                                                                                                 !3359
    {
      "a": 42
    }
