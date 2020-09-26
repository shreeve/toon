# toon

`toon` is a Ruby gem that makes it easy to cleanup and format data.

## Example

The following code:

```ruby
require 'toon'

rows = [
  %w[ Name DOB      ],
  %w[ tom  19710413 ],
  %w[ mIkE 19690918 ],
]

p toon! rows, <<~""
  Name  tune
  DOB   to_yyyymmdd_ymd
```

will produce:

```text
[["Name", "DOB"       ],
 ["Tom" , "04/13/1971"],
 ["Mike", "09/18/1969"]]
```
