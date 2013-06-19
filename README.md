
-- API for using Mixpanel on Corona

Usage:

```lua
local mixpanel = require 'mixpanel'
mixpanel.initMixpanel(MIXPANEL_API)
mixpanel.track('eventName', {as = many, properties=true})
```


 TODO:
 - Queue events in JSON
 - People tracking
