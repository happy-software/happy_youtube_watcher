import "controllers"

import "trix"
import "@rails/actiontext"
import "ahoy"
import "@andypf/json-viewer"

ahoy.configure({
  useBeacon: false,
  visitsUrl: "/t/visits",
  eventsUrl: "/t/events",
});
