# Flakey.js

### Whats Flakey.js
**Goal:** A Javascript MVC framework with an emphasis on Model reliability. Flakey.js is targeted towards mobile platforms where solid server connections are not often possible.

**Details:**
Models exist as heuristic, versioned instructions rather than complete "records."  Therefore instead of a model instance being essentially a JS object with data parameters, data is be stored as a series of transactional modifications, dating back to the models creation. This has several benefits: all data is intrinsically versioned and backed up. Any transaction can be rolled back, and history can easily be viewed.

### Building an app based on Flakey.js
Using browserify to add requirement support to client side code (like the included example app) is strongly recommended. However it is possible to use Flakey.js as a vanilla JS file.

### Requirements
To compile flakey.js from source:
- nodejs
- npm (normally installed with nodejs)
- cake (normally installed with nodejs)
- coffeescript
- jqueryify
- jsonify

To compile the sample note taking app (example/*), all listed above plus:
- browserify
- eco