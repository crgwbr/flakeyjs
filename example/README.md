# Flakey.js Example App

This is a example of an app made with Flakey.js. It's a simple note taking app that stores notes in localStorage. With the addition of a simple server application (perhaps a bottle.py app), it could be modified to also save notes to a server-side database.

Flakey.js is designed to work well with multiple storage backends, to provide redundancy incase one fails. For example, if an this app was being used over a 3G connection, it would save all model changes in both the localStorage and server backend. Then, if the server connection becomes "flakey," models continue to be saved in localStorage, while server actions are simply appended to a log. Then, when the server connection comes back online, it's data will be rebuilt by performing each action in the log in order.

What is the user then clears localStorage and reloads the page? On page load, `Flakey.models.backend_controller.sync(model_name)` is called. This function looks at every storage backend and compares their record set. It would then notice that records are missing from localStorage, and replace each of them so that normal use may continue.

### What Flakey.js isn't
This simple note taking app is an ideal use case for Flakey.js: it processes relatively small amounts of data and values reliability over raw performance. Because of the inherent complexness of sync between multiple storage backends and datamodel versioning, Flakey.js is *not* fast. However, for most applications (that don't deal with huge datasets), it's performance should seem very fast to the end user.