corona-mixpanel
========

API for sending events to Mixpanel on Corona SDK

Installation
------

### Bower

This package and its dependencies can be used as bower modules.

To do that, just follow the instructions on [this gist](https://gist.github.com/jeduan/6163713)

### Manual

Copy to your game folder the following files

  - [mixpanel.lua](https://raw.github.com/jeduan/corona-mixpanel/master/mixpanel.lua)
  - [offlinequeue.lua](https://raw.github.com/jeduan/corona-offlinequeue/master/offlinequeue.lua)
  - [log.lua](https://raw.github.com/jeduan/lua-log-tools/master/log.lua)
  - [fiber.lua](https://raw.github.com/jeduan/lua-fiber/master/fiber.lua)
  - [httptools.lua](https://github.com/jeduan/http-tools/blob/master/httptools.lua)

And change accordingly `require` paths

To have a drop-in replacement for Corona's analytics module, check out [corona-analytics-mixpanel](https://github.com/jeduan/corona-analytics-mixpanel)

Usage
-------

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


### Super properties

It's very common to have certain properties that you want to include with each event you send. Generally, these are things you know about the user rather than about a specific event—for example, the user's age, gender, or source.

To make things easier, you can register these properties as super properties. If you do, we will automatically include them with all tracked events. Super properties are saved to device storage, and will persist across invocations of your app.

```lua
local mixpanel = require 'mixpanel'
mixpanel.registerSuperProperties({
  ['User Type'] = 'Paid'
})
```

Going forward, whenever you track an event, super properties will be included as properties. For instance, if you call

```lua
local mixpanel = require 'mixpanel'

mixpanel.track('signup', {
  'signup_button' = 'test12'
})
```

after making the above call to registerSuperProperties:, it is just like adding the properties directly:

```lua
local mixpanel = require 'mixpanel'

mixpanel.track('signup', {
  'signup_button' = 'test12',
  ['User Type'] = 'Paid',
})
```

### Advanced configuration

You can use an existent offlinequeue instance when initing this module.

To do that just pass a second params argument to `initMixpanel`

```lua
local mixpanel = require 'mixpanel'
local offlinequeue = require 'offlinequeue'

local queue = offlinequeue.newQueue(...)
mixpanel.initMixpanel(MIXPANEL_TOKEN, {queue = queue})
```

 TODO:
 - ~~Queue events in JSON~~
 - People API
