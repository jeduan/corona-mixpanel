
API for sending events to Mixpanel on Corona SDK
------

Usage:

```lua
local mixpanel = require 'mixpanel'
mixpanel.initMixpanel(MIXPANEL_API)
mixpanel.track( 'clickedAd', {
  ['Banner Color'] = 'Blue'
})
```

You need to ensure these properties exist in `build.settings`

```lua
  android = {
    usesPermissions = {
      "android.permission.INTERNET",
      "android.permission.READ_PHONE_STATE",
      "android.permission.ACCESS_NETWORK_STATE",
    },
  }
```


 TODO:
 - Queue events in JSON
 - People API
